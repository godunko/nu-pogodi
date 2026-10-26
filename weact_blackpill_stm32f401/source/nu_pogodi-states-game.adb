--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Callbacks.Generic_Parameterless;
with A0B.Types;

with Nu_Pogodi.Application;
with Nu_Pogodi.Bitmaps;
with Nu_Pogodi.Clock;
with Nu_Pogodi.Hardware.Sound;
with Nu_Pogodi.Scene.Screen;
with Nu_Pogodi.Display_Segments;

package body Nu_Pogodi.States.Game is

   use type Nu_Pogodi.Scene.Sound_Kind;

   subtype Game_Sound_Kind is Nu_Pogodi.Scene.Sound_Kind
     range Nu_Pogodi.Scene.Move_Left_Top .. Nu_Pogodi.Scene.Egg_Caught;

   Samples_Per_Movement : constant :=
     Nu_Pogodi.Hardware.Sound.Sample_Rate / 40;
   --  Each movement sound lasts 25 ms.

   Samples_Per_Catch : constant :=
     Nu_Pogodi.Hardware.Sound.Sample_Rate * 75 / 1_000;

   subtype Catch_Samples is Nu_Pogodi.Hardware.Sound.Sample_Array
     (0 .. Samples_Per_Catch - 1);

   subtype Movement_Samples is Nu_Pogodi.Hardware.Sound.Sample_Array
     (0 .. Samples_Per_Movement - 1);

   procedure On_Sound_Finished;

   package Sound_Finished_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Sound_Finished);

   procedure Play_Sound (Sound : Nu_Pogodi.Scene.Sound_Kind);

   procedure Start_Sound;

   --------------------------
   -- Generate_Catch_Sound --
   --------------------------

   function Generate_Catch_Sound return Catch_Samples is
      Frequencies : constant array (Natural range 0 .. 3) of Positive :=
        [1_760, 2_093, 2_637, 3_136];
      Samples_Per_Note : constant := Samples_Per_Catch / Frequencies'Length;

   begin
      return Result : Catch_Samples do
         for Part in Frequencies'Range loop
            declare
               Period : constant Positive := 1_000_000 / Frequencies (Part);

            begin
               Result
                 (Part * Samples_Per_Note ..
                    (Part + 1) * Samples_Per_Note - 1) :=
                   [others =>
                      (ARR    => A0B.Types.Unsigned_16 (Period - 1),
                       CCR1   => A0B.Types.Unsigned_16 (Period / 2),
                       others => <>)];
            end;
         end loop;
      end return;
   end Generate_Catch_Sound;

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
   Egg_Caught_Sound   : aliased constant
     Nu_Pogodi.Hardware.Sound.Sample_Array :=
       Generate_Catch_Sound with Alignment => 4;

   type Sound_Samples_Access is
     access constant Nu_Pogodi.Hardware.Sound.Sample_Array;

   Sounds : constant array (Game_Sound_Kind)
     of Sound_Samples_Access :=
       [Nu_Pogodi.Scene.Move_Left_Top     => Left_Top_Sound'Access,
        Nu_Pogodi.Scene.Move_Left_Bottom  => Left_Bottom_Sound'Access,
        Nu_Pogodi.Scene.Move_Right_Top    => Right_Top_Sound'Access,
        Nu_Pogodi.Scene.Move_Right_Bottom => Right_Bottom_Sound'Access,
        Nu_Pogodi.Scene.Egg_Caught        => Egg_Caught_Sound'Access];

   type Queue_Index is mod 4;
   --  One slot remains free, leaving room for three sounds.

   Queue : array (Queue_Index) of Nu_Pogodi.Scene.Sound_Kind :=
     [others => Nu_Pogodi.Scene.None] with Volatile;
   Read_Index  : Queue_Index := 0 with Volatile;
   Write_Index : Queue_Index := 0 with Volatile;

   --------------
   -- Keyboard --
   --------------

   overriding procedure Keyboard
     (Self  : in out Game_State;
      State : Nu_Pogodi.Keyboard.Keyboard_State)
   is
      Sound : Nu_Pogodi.Scene.Sound_Kind;

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
      Sound : Nu_Pogodi.Scene.Sound_Kind;

   begin
      Nu_Pogodi.Scene.Update_Physics_Tick (Refresh, Sound);
      Play_Sound (Sound);
   end Physics_Tick;

   ----------------
   -- Play_Sound --
   ----------------

   procedure Play_Sound (Sound : Nu_Pogodi.Scene.Sound_Kind) is
   begin
      if Sound = Nu_Pogodi.Scene.None then
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
      Sound   : Nu_Pogodi.Scene.Sound_Kind;
      Success : Boolean;

   begin
      if Read_Index = Write_Index then
         return;
      end if;

      Sound := Queue (Read_Index);

      if Sound = Nu_Pogodi.Scene.None then
         return;
      end if;

      --  None marks a sound already handed to the driver. The slot stays
      --  occupied until the completion callback advances Read_Index.

      Queue (Read_Index) := Nu_Pogodi.Scene.None;
      Nu_Pogodi.Hardware.Sound.Start
        (Data     => Sounds (Sound).all,
         Finished => Sound_Finished_Callbacks.Create_Callback,
         Success  => Success);

      if not Success then
         Queue (Read_Index) := Sound;
         raise Program_Error;
      end if;
   end Start_Sound;

end Nu_Pogodi.States.Game;
