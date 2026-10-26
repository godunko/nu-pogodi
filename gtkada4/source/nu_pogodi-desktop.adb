--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Characters.Handling;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Real_Time;
with Ada.Text_IO;

with GNAT.OS_Lib;

with Cairo;
with Gdk.Enums;
with Gdk.Pixbuf;
with Glib.Application;
with Glib.Main;
with Gtk.Box;
with Gtk.Drawing_Area;
with Gtk.Label;
with Gtk.Window;
with Gtk.Application;
with Gtk.Application_Window;
with Gtk.Enums;
with Gtk.Event_Controller_Key;
with Gtk.Event_Controller_Focus;

with Nu_Pogodi.Images;
with Nu_Pogodi.Keyboard;
with Nu_Pogodi.Scene.Screen;
with Nu_Pogodi.Display_Segments;

package body Nu_Pogodi.Desktop is

   use Ada.Real_Time;
   use Glib;
   use Nu_Pogodi.Scene;
   use type Gdk.Pixbuf.Gdk_Pixbuf;
   use type GNAT.OS_Lib.String_Access;
   use type Glib.Main.G_Source_Id;
   use type Nu_Pogodi.Display_Segments.Display_Segment_Set;

   Window     : Gtk.Application_Window.Gtk_Application_Window;
   Field      : Gtk.Drawing_Area.Gtk_Drawing_Area;
   Status     : Gtk.Label.Gtk_Label;
   Keys       : Nu_Pogodi.Keyboard.Keyboard_State :=
     (others => [others => False]);
   Visible    : Nu_Pogodi.Display_Segments.Display_Segment_Set :=
     [others => False];
   Running    : Boolean := False;
   Failed     : Boolean := False;
   Next_Tick  : Time;
   Timer      : Glib.Main.G_Source_Id := Glib.Main.No_Source_Id;
   Tick_Step  : constant Time_Span := Milliseconds (25);

   type Image_Array is
     array (Nu_Pogodi.Display_Segments.Display_Segment_Identifier)
     of Gdk.Pixbuf.Gdk_Pixbuf;

   Images     : Image_Array := [others => null];
   Background : Gdk.Pixbuf.Gdk_Pixbuf := null;
   Cache_W    : Positive := 1;
   Cache_H    : Positive := 1;

   function Resource_Directory return String;

   procedure Activate
     (Application : access Glib.Application.Gapplication_Record'Class);

   procedure Draw
     (Self : not null access Gtk.Drawing_Area.Gtk_Drawing_Area_Record'Class;
      Cr   : Cairo.Cairo_Context;
      W    : Glib.Gint;
      H    : Glib.Gint);

   function Finish
     (Self : access Gtk.Window.Gtk_Window_Record'Class) return Boolean;

   procedure Free_Images;

   procedure Handle_Key (Key : Guint; Pressed : Boolean);

   function Key_Press
     (Self    : access
        Gtk.Event_Controller_Key.Gtk_Event_Controller_Key_Record'Class;
      Keyval  : Guint;
      Keycode : Guint;
      State   : Gdk.Enums.Gdk_Modifier_Type) return Boolean;

   procedure Key_Release
     (Self    : access
        Gtk.Event_Controller_Key.Gtk_Event_Controller_Key_Record'Class;
      Keyval  : Glib.Guint;
      Keycode : Glib.Guint;
      State   : Gdk.Enums.Gdk_Modifier_Type);

   procedure Focus_Out
     (Self : access
        Gtk.Event_Controller_Focus.Gtk_Event_Controller_Focus_Record'Class);

   function On_Timer return Boolean;

   procedure Report_Error (Error : Ada.Exceptions.Exception_Occurrence);

   procedure Clear_Keys;

   procedure Update_Input;

   --------------
   -- Activate --
   --------------

   procedure Activate
     (Application : access Glib.Application.Gapplication_Record'Class)
   is
      use type Gtk.Application_Window.Gtk_Application_Window;

      Box        : Gtk.Box.Gtk_Box;
      Help       : Gtk.Label.Gtk_Label;
      Controller : Gtk.Event_Controller_Key.Gtk_Event_Controller_Key;
      Focus      : Gtk.Event_Controller_Focus.Gtk_Event_Controller_Focus;

   begin
      if Window /= null then
         Window.Present;

         return;
      end if;

      Gtk.Application_Window.Gtk_New
        (Window, Gtk.Application.Gtk_Application (Application));
      Window.Set_Title ("Nu, pogodi! - GtkAda4 demo");
      Window.Set_Default_Size (900, 650);
      Gtk.Box.Gtk_New (Box, Gtk.Enums.Orientation_Vertical, 6);
      Gtk.Drawing_Area.Gtk_New (Field);
      Field.Set_Size_Request (400, 252);
      Field.Set_Hexpand (True);
      Field.Set_Vexpand (True);
      Field.Set_Draw_Func (Draw'Access);
      Gtk.Label.Gtk_New (Status, "Press 1 or 2 to start game");
      Gtk.Label.Gtk_New
        (Help, "Q / S - left top / bottom"
         & "    P / L - right top / bottom"
         & "    1 / 2 - new game");
      Box.Append (Field);
      Box.Append (Status);
      Box.Append (Help);
      Window.Set_Child (Box);
      Window.On_Close_Request (Finish'Access);
      Gtk.Event_Controller_Key.Gtk_New (Controller);
      Controller.On_Key_Pressed (Key_Press'Access);
      Controller.On_Key_Released (Key_Release'Access);
      Window.Add_Controller (Controller);
      Gtk.Event_Controller_Focus.Gtk_New (Focus);
      Focus.On_Leave (Focus_Out'Access);
      Window.Add_Controller (Focus);
      Update_Input;
      Nu_Pogodi.Scene.Screen.Get_Visibility (Visible);

      Next_Tick := Clock + Tick_Step;
      Timer := Glib.Main.Timeout_Add (25, On_Timer'Access);

      Window.Present;
   end Activate;

   ----------------
   -- Clear_Keys --
   ----------------

   procedure Clear_Keys is
   begin
      for Key in Nu_Pogodi.Keyboard.Key loop
         if Keys.State (Key) then
            Keys.Released (Key) := True;
         end if;
      end loop;

      Keys.State := [others => False];
      Update_Input;
   end Clear_Keys;

   ----------
   -- Draw --
   ----------

   procedure Draw
     (Self : not null access Gtk.Drawing_Area.Gtk_Drawing_Area_Record'Class
        with Unreferenced;
      Cr   : Cairo.Cairo_Context;
      W    : Glib.Gint;
      H    : Glib.Gint)
   is
      Ratio  : constant Long_Float := 1570.2845 / 989.1816;
      Width  : constant Positive :=
        Positive'Max
          (1, Integer'Min (Integer (W), Integer (Long_Float (H) * Ratio)));
      Height : constant Positive :=
        Positive'Max
          (1, Integer'Min (Integer (H), Integer (Long_Float (Width) / Ratio)));

      procedure Paint (Image : Gdk.Pixbuf.Gdk_Pixbuf);

      -----------
      -- Paint --
      -----------

      procedure Paint (Image : Gdk.Pixbuf.Gdk_Pixbuf) is
      begin
         Nu_Pogodi.Images.Set_Source_Pixbuf
           (Cr,
            Image,
            Gdouble (Integer (W) - Width) / 2.0,
            Gdouble (Integer (H) - Height) / 2.0);
         Cairo.Paint (Cr);
      end Paint;

   begin
      Cairo.Set_Source_Rgb (Cr, 1.0, 1.0, 1.0);
      Cairo.Paint (Cr);

      if Failed then
         return;
      end if;

      if Background = null or Width /= Cache_W or Height /= Cache_H then
         Free_Images;

         declare
            Directory : constant String := Resource_Directory;

         begin
            Background :=
              Nu_Pogodi.Images.Load
                (Directory & "/background.svg", Width, Height);

            for Id in Images'Range loop
               Images (Id) :=
                 Nu_Pogodi.Images.Load
                   (Directory & "/" & Ada.Characters.Handling.To_Lower
                      (Nu_Pogodi.Display_Segments.Display_Segment_Identifier
                         'Image (Id)) & ".svg",
                    Width,
                    Height);
            end loop;
         end;

         Cache_W := Width;
         Cache_H := Height;
      end if;

      Paint (Background);

      for Id in Visible'Range loop
         if Visible (Id) then
            Paint (Images (Id));
         end if;
      end loop;

   exception
      when Error : others =>
         Report_Error (Error);
   end Draw;

   ------------
   -- Finish --
   ------------

   function Finish
     (Self : access Gtk.Window.Gtk_Window_Record'Class with Unreferenced)
      return Boolean is

   begin
      if Timer /= Glib.Main.No_Source_Id then
         Glib.Main.Remove (Timer);
         Timer := Glib.Main.No_Source_Id;
      end if;

      Running := False;
      Free_Images;
      Window := null;

      return False;
   end Finish;

   ---------------
   -- Focus_Out --
   ---------------

   procedure Focus_Out
     (Self : access
        Gtk.Event_Controller_Focus.Gtk_Event_Controller_Focus_Record'Class
          with Unreferenced) is
   begin
      Clear_Keys;
   end Focus_Out;

   -----------------
   -- Free_Images --
   -----------------

   procedure Free_Images is
   begin
      for Image of Images loop
         if Image /= null then
            Image.Unref;
            Image := null;
         end if;
      end loop;

      if Background /= null then
         Background.Unref;
         Background := null;
      end if;
   end Free_Images;

   ----------------
   -- Handle_Key --
   ----------------

   procedure Handle_Key (Key : Glib.Guint; Pressed : Boolean) is
      use Nu_Pogodi.Keyboard;

      Item : Nu_Pogodi.Keyboard.Key;
      Mode : Game_Mode;

   begin
      case Key is
         when 113 | 81 => Item := Left_Top;
         when 115 | 83 => Item := Left_Bottom;
         when 112 | 80 => Item := Right_Top;
         when 108 | 76 => Item := Right_Bottom;
         when 49       => Item := Game_A;
         when 50       => Item := Game_B;
         when others   => return;
      end case;

      if Keys.State (Item) = Pressed then
         return;
      end if;

      Keys.State (Item)    := Pressed;
      Keys.Pressed (Item)  := Pressed;
      Keys.Released (Item) := not Pressed;

      if Item in Game_A | Game_B and Pressed and not Failed then
         Mode := (if Item = Game_A then Mode_A else Mode_B);
         Initialize (Mode);
         Running := True;
         Next_Tick := Clock + Tick_Step;
         Status.Set_Text ((if Mode = Mode_A then "Game A" else "Game B"));
      end if;

      Update_Input;
   end Handle_Key;

   ---------------
   -- Key_Press --
   ---------------

   function Key_Press
     (Self    : access
        Gtk.Event_Controller_Key.Gtk_Event_Controller_Key_Record'Class
          with Unreferenced;
      Keyval  : Glib.Guint;
      Keycode : Glib.Guint with Unreferenced;
      State   : Gdk.Enums.Gdk_Modifier_Type with Unreferenced)
      return Boolean is
   begin
      Handle_Key (Keyval, True);

      return Keyval in 49 | 50 | 76 | 80 | 81 | 83 | 108 | 112 | 113 | 115;
   end Key_Press;

   -----------------
   -- Key_Release --
   -----------------

   procedure Key_Release
     (Self    : access
        Gtk.Event_Controller_Key.Gtk_Event_Controller_Key_Record'Class
          with Unreferenced;
      Keyval  : Glib.Guint;
      Keycode : Glib.Guint with Unreferenced;
      State   : Gdk.Enums.Gdk_Modifier_Type with Unreferenced) is
   begin
      Handle_Key (Keyval, False);
   end Key_Release;

   --------------
   -- On_Timer --
   --------------

   function On_Timer return Boolean is
      Now         : constant Time := Clock;
      Refresh     : Boolean := False;
      Updated     : Boolean := False;
      New_Visible : Nu_Pogodi.Display_Segments.Display_Segment_Set;

   begin
      if not Window.Is_Active then
         Clear_Keys;
      end if;

      if Running then
         Update_Input;

         while Next_Tick <= Now and then Running loop
            Update_Physics_Tick (Refresh);
            Updated := True;
            Next_Tick := Next_Tick + Tick_Step;

            if Is_Game_Over then
               Running := False;
               Status.Set_Text ("Game over. Select new game mode 1 or 2");
            end if;
         end loop;

         if Updated then
            Nu_Pogodi.Scene.Screen.Get_Visibility (New_Visible);

            if New_Visible /= Visible then
               Visible := New_Visible;
               Field.Queue_Draw;
            end if;
         end if;
      end if;

      return True;

   exception
      when Error : others =>
         Report_Error (Error);

         return True;
   end On_Timer;

   ------------------
   -- Report_Error --
   ------------------

   procedure Report_Error (Error : Ada.Exceptions.Exception_Occurrence) is
   begin
      Failed := True;
      Running := False;
      Free_Images;
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         Ada.Exceptions.Exception_Information (Error));
      Status.Set_Text ("Error: " & Ada.Exceptions.Exception_Message (Error));
   end Report_Error;

   ------------------------
   -- Resource_Directory --
   ------------------------

   function Resource_Directory return String is
      Executable : GNAT.OS_Lib.String_Access :=
        GNAT.OS_Lib.Locate_Exec_On_Path (Ada.Command_Line.Command_Name);

   begin
      if Executable = null then
         raise Program_Error with "Cannot locate executable";
      end if;

      declare
         Directory : constant String :=
           Ada.Directories.Containing_Directory
             (Ada.Directories.Full_Name (Executable.all)) & "/../gtkada4/svg";

      begin
         GNAT.OS_Lib.Free (Executable);

         return Directory;
      end;
   end Resource_Directory;

   ---------
   -- Run --
   ---------

   procedure Run is
      Application : Gtk.Application.Gtk_Application;
      Exit_Code   : Gint;

   begin
      Gtk.Application.Gtk_New
        (Application, "org.nu_pogodi.gtkada4",
         Glib.Application.G_Application_Flags_None);
      Application.On_Activate (Activate'Access);

      Exit_Code := Application.Run;
      Application.Unref;
      Ada.Command_Line.Set_Exit_Status
        (if Failed then Ada.Command_Line.Failure
         else Ada.Command_Line.Exit_Status (Exit_Code));
   end Run;

   ------------------
   -- Update_Input --
   ------------------

   procedure Update_Input is
   begin
      if Running and then not Failed then
         Update_Keyboad_State (Keys);
      end if;

      Keys.Pressed  := [others => False];
      Keys.Released := [others => False];
   end Update_Input;

end Nu_Pogodi.Desktop;
