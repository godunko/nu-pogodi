--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Callbacks.Generic_Parameterless;

with Nu_Pogodi.Application;
with Nu_Pogodi.Bitmaps;
with Nu_Pogodi.Clock;
with Nu_Pogodi.Hardware.Sound;
with Nu_Pogodi.Scene.Screen;
with Nu_Pogodi.Display_Segments;
with Nu_Pogodi.Sounds.Buffers;
with Nu_Pogodi.Sounds.Samples;

package body Nu_Pogodi.States.Game is

   use type Nu_Pogodi.Sounds.Sound_Identifier;

   procedure On_Sound_Finished;

   package Sound_Finished_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Sound_Finished);

   procedure Play_Sound (Sound : Nu_Pogodi.Sounds.Sound_Identifier);

   procedure Start_Sound;

   Buffer : Nu_Pogodi.Hardware.Sound.Sample_Array
     renames Nu_Pogodi.Sounds.Buffers.Buffer_0;

   type Queue_Index is mod 4;
   --  One slot remains free, leaving room for three sounds.

   Queue : array (Queue_Index) of Nu_Pogodi.Sounds.Sound_Identifier :=
     [others => Nu_Pogodi.Sounds.None] with Volatile;
   Read_Index  : Queue_Index := 0 with Volatile;
   Write_Index : Queue_Index := 0 with Volatile;

   --------------
   -- Keyboard --
   --------------

   overriding procedure Keyboard
     (Self  : in out Game_State;
      State : Nu_Pogodi.Keyboard.Keyboard_State)
   is
      Sound : Nu_Pogodi.Sounds.Sound_Identifier;

   begin
      Nu_Pogodi.Scene.Update_Keyboad_State (State, Sound);
      Play_Sound (Sound);
   end Keyboard;

   -----------------------
   -- On_Sound_Finished --
   -----------------------

   procedure On_Sound_Finished is
   begin
      Read_Index := @ + 1;
      Start_Sound;
   end On_Sound_Finished;

   ------------------
   -- Physics_Tick --
   ------------------

   overriding procedure Physics_Tick
     (Self    : in out Game_State;
      Refresh : in out Boolean)
   is
      Sound : Nu_Pogodi.Sounds.Sound_Identifier;

   begin
      Nu_Pogodi.Scene.Update_Physics_Tick (Refresh, Sound);
      Play_Sound (Sound);
   end Physics_Tick;

   ----------------
   -- Play_Sound --
   ----------------

   procedure Play_Sound (Sound : Nu_Pogodi.Sounds.Sound_Identifier) is
   begin
      if Sound = Nu_Pogodi.Sounds.None then
         return;
      end if;

      if Write_Index + 1 = Read_Index then
         raise Program_Error;
      end if;

      Queue (Write_Index) := Sound;
      Write_Index := @ + 1;

      Start_Sound;
   end Play_Sound;

   ------------
   -- Render --
   ------------

   overriding procedure Render
     (Self        : in out Game_State;
      Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer)
   is
      Set : Nu_Pogodi.Display_Segments.Display_Segment_Set;

   begin
      Nu_Pogodi.Scene.Screen.Get_Visibility (Set);
      Nu_Pogodi.Bitmaps.Draw (Framebuffer, Set);
      Nu_Pogodi.Clock.Draw (Framebuffer);

      if Nu_Pogodi.Scene.Is_Game_Over then
         Nu_Pogodi.Application.Request_Clock_State;
      end if;
   end Render;

   -----------------
   -- Start_Sound --
   -----------------

   procedure Start_Sound is
      Sound   : Nu_Pogodi.Sounds.Sound_Identifier;
      Last    : Natural;
      Success : Boolean;

   begin
      if Read_Index = Write_Index then
         return;
      end if;

      Sound := Queue (Read_Index);

      if Sound = Nu_Pogodi.Sounds.None then
         return;
      end if;

      --  None marks a sound being generated or played. The slot stays
      --  occupied until the completion callback advances Read_Index.

      Queue (Read_Index) := Nu_Pogodi.Sounds.None;
      Nu_Pogodi.Sounds.Samples.Builders (Sound) (Buffer, Last);

      declare
         Data : constant access Nu_Pogodi.Hardware.Sound.Sample_Array :=
           Buffer (Buffer'First .. Last)'Unrestricted_Access;

      begin
         Nu_Pogodi.Hardware.Sound.Start
           (Data     => Data.all,
            Finished => Sound_Finished_Callbacks.Create_Callback,
            Success  => Success);
      end;

      if not Success then
         Queue (Read_Index) := Sound;
         raise Program_Error;
      end if;
   end Start_Sound;

end Nu_Pogodi.States.Game;
