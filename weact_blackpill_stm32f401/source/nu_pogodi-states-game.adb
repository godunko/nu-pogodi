--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Callbacks.Unset_Callback;
with A0B.Types;

with Nu_Pogodi.Application;
with Nu_Pogodi.Bitmaps;
with Nu_Pogodi.Clock;
with Nu_Pogodi.Hardware.Sound;
with Nu_Pogodi.Scene.Screen;
with Nu_Pogodi.Display_Segments;

package body Nu_Pogodi.States.Game is

   subtype Movement_Sound_Kind is Nu_Pogodi.Scene.Sound_Kind
     range Nu_Pogodi.Scene.Move_Left_Top .. Nu_Pogodi.Scene.Move_Right_Bottom;

   Samples_Per_Movement : constant :=
     Nu_Pogodi.Hardware.Sound.Sample_Rate / 40;
   --  Each movement sound lasts 25 ms.

   subtype Movement_Samples is Nu_Pogodi.Hardware.Sound.Sample_Array
     (0 .. Samples_Per_Movement - 1);

   --------------------
   -- Generate_Sound --
   --------------------

   function Generate_Sound
     (First_Frequency  : Positive;
      Second_Frequency : Positive) return Movement_Samples
   is
      Half_Samples : constant := Samples_Per_Movement / 2;

      First_Period  : constant Positive := 1_000_000 / First_Frequency;
      Second_Period : constant Positive := 1_000_000 / Second_Frequency;

      First_Sample  : constant Nu_Pogodi.Hardware.Sound.Sample :=
        (ARR    => A0B.Types.Unsigned_16 (First_Period - 1),
         CCR1   => A0B.Types.Unsigned_16 (First_Period / 2),
         others => <>);
      Second_Sample : constant Nu_Pogodi.Hardware.Sound.Sample :=
        (ARR    => A0B.Types.Unsigned_16 (Second_Period - 1),
         CCR1   => A0B.Types.Unsigned_16 (Second_Period / 2),
         others => <>);

   begin
      return
        [0 .. Half_Samples - 1                    => First_Sample,
         Half_Samples .. Samples_Per_Movement - 1 => Second_Sample];
   end Generate_Sound;

   Left_Top_Sound     : aliased constant
     Nu_Pogodi.Hardware.Sound.Sample_Array :=
       Generate_Sound (2_400, 1_600) with Alignment => 4;
   Left_Bottom_Sound  : aliased constant
     Nu_Pogodi.Hardware.Sound.Sample_Array :=
       Generate_Sound (1_800, 1_200) with Alignment => 4;
   Right_Top_Sound    : aliased constant
     Nu_Pogodi.Hardware.Sound.Sample_Array :=
       Generate_Sound (1_500, 2_200) with Alignment => 4;
   Right_Bottom_Sound : aliased constant
     Nu_Pogodi.Hardware.Sound.Sample_Array :=
       Generate_Sound (1_100, 1_700) with Alignment => 4;

   type Movement_Samples_Access is
     access constant Nu_Pogodi.Hardware.Sound.Sample_Array;

   Sounds : constant array (Movement_Sound_Kind)
     of Movement_Samples_Access :=
       [Nu_Pogodi.Scene.Move_Left_Top     => Left_Top_Sound'Access,
        Nu_Pogodi.Scene.Move_Left_Bottom  => Left_Bottom_Sound'Access,
        Nu_Pogodi.Scene.Move_Right_Top    => Right_Top_Sound'Access,
        Nu_Pogodi.Scene.Move_Right_Bottom => Right_Bottom_Sound'Access];

   --------------
   -- Keyboard --
   --------------

   overriding procedure Keyboard
     (Self  : in out Game_State;
      State : Nu_Pogodi.Keyboard.Keyboard_State) is
   begin
      Nu_Pogodi.Scene.Update_Keyboad_State (State);
   end Keyboard;

   ------------------
   -- Physics_Tick --
   ------------------

   overriding procedure Physics_Tick
     (Self    : in out Game_State;
      Refresh : in out Boolean)
   is
      Sound   : Nu_Pogodi.Scene.Sound_Kind;
      Success : Boolean;

   begin
      Nu_Pogodi.Scene.Update_Physics_Tick (Refresh, Sound);

      if Sound in Movement_Sound_Kind then
         Nu_Pogodi.Hardware.Sound.Start
           (Data     => Sounds (Sound).all,
            Finished => A0B.Callbacks.Unset_Callback.Create_Callback,
            Success  => Success);

         if not Success then
            raise Program_Error;
         end if;
      end if;
   end Physics_Tick;

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

end Nu_Pogodi.States.Game;
