--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Types;

package body Nu_Pogodi.Sounds.Samples is

   Samples_Per_Movement : constant :=
     Nu_Pogodi.Hardware.Sound.Sample_Rate / 40;
   --  Each movement sound lasts 25 ms.

   Samples_Per_Catch : constant :=
     Nu_Pogodi.Hardware.Sound.Sample_Rate * 75 / 1_000;

   Samples_Per_Fall : constant :=
     Nu_Pogodi.Hardware.Sound.Sample_Rate / 20;

   Samples_Per_Chick_Jump : constant :=
     Nu_Pogodi.Hardware.Sound.Sample_Rate * 30 / 1_000;

   procedure Generate_Sound
     (Buffer           : out Nu_Pogodi.Hardware.Sound.Sample_Array;
      Last             : out Natural;
      First_Frequency  : Positive;
      Second_Frequency : Positive);

   --------------------------
   -- Generate_Catch_Sound --
   --------------------------

   procedure Generate_Catch_Sound
     (Buffer : out Nu_Pogodi.Hardware.Sound.Sample_Array;
      Last   : out Natural)
   is
      Frequencies : constant array (Natural range 0 .. 3) of Positive :=
        [1_760, 2_093, 2_637, 3_136];
      Samples_Per_Note : constant := Samples_Per_Catch / Frequencies'Length;

   begin
      for Part in Frequencies'Range loop
         declare
            Period : constant Positive := 1_000_000 / Frequencies (Part);

         begin
            Buffer
              (Buffer'First + Part * Samples_Per_Note ..
                 Buffer'First + (Part + 1) * Samples_Per_Note - 1) :=
                [others =>
                   (ARR    => A0B.Types.Unsigned_16 (Period - 1),
                    CCR1   => A0B.Types.Unsigned_16 (Period / 2),
                    others => <>)];
         end;
      end loop;

      Last := Buffer'First + Samples_Per_Catch - 1;
   end Generate_Catch_Sound;

   -------------------------------
   -- Generate_Chick_Jump_Sound --
   -------------------------------

   procedure Generate_Chick_Jump_Sound
     (Buffer : out Nu_Pogodi.Hardware.Sound.Sample_Array;
      Last   : out Natural)
   is
      Frequencies : constant array (Natural range 0 .. 3) of Positive :=
        [2_500, 3_200, 4_000, 5_000];
      Samples_Per_Note : constant :=
        Samples_Per_Chick_Jump / Frequencies'Length;

   begin
      for Part in Frequencies'Range loop
         declare
            Period : constant Positive := 1_000_000 / Frequencies (Part);

         begin
            Buffer
              (Buffer'First + Part * Samples_Per_Note ..
                 Buffer'First + (Part + 1) * Samples_Per_Note - 1) :=
                [others =>
                   (ARR    => A0B.Types.Unsigned_16 (Period - 1),
                    CCR1   => A0B.Types.Unsigned_16 (Period / 2),
                    others => <>)];
         end;
      end loop;

      Last := Buffer'First + Samples_Per_Chick_Jump - 1;
   end Generate_Chick_Jump_Sound;

   -------------------------
   -- Generate_Fall_Sound --
   -------------------------

   procedure Generate_Fall_Sound
     (Buffer : out Nu_Pogodi.Hardware.Sound.Sample_Array;
      Last   : out Natural)
   is
      ARR_Start : constant := 2_222;
      ARR_End   : constant := 8_333;

   begin
      for J in 0 .. Samples_Per_Fall - 1 loop
         declare
            ARR : constant Natural :=
              ARR_Start + (ARR_End - ARR_Start) * J / Samples_Per_Fall;

         begin
            Buffer (Buffer'First + J) :=
              (ARR    => A0B.Types.Unsigned_16 (ARR),
               CCR1   =>
                 (if J > Samples_Per_Fall - 40 then 0
                  else A0B.Types.Unsigned_16 (ARR / 2)),
               others => <>);
         end;
      end loop;

      Last := Buffer'First + Samples_Per_Fall - 1;
   end Generate_Fall_Sound;

   --------------------------------
   -- Generate_Left_Bottom_Sound --
   --------------------------------

   procedure Generate_Left_Bottom_Sound
     (Buffer : out Nu_Pogodi.Hardware.Sound.Sample_Array;
      Last   : out Natural) is
   begin
      Generate_Sound (Buffer, Last, 1_800, 1_200);
   end Generate_Left_Bottom_Sound;

   -----------------------------
   -- Generate_Left_Top_Sound --
   -----------------------------

   procedure Generate_Left_Top_Sound
     (Buffer : out Nu_Pogodi.Hardware.Sound.Sample_Array;
      Last   : out Natural) is
   begin
      Generate_Sound (Buffer, Last, 2_400, 1_600);
   end Generate_Left_Top_Sound;

   ---------------------------------
   -- Generate_Right_Bottom_Sound --
   ---------------------------------

   procedure Generate_Right_Bottom_Sound
     (Buffer : out Nu_Pogodi.Hardware.Sound.Sample_Array;
      Last   : out Natural) is
   begin
      Generate_Sound (Buffer, Last, 1_100, 1_700);
   end Generate_Right_Bottom_Sound;

   ------------------------------
   -- Generate_Right_Top_Sound --
   ------------------------------

   procedure Generate_Right_Top_Sound
     (Buffer : out Nu_Pogodi.Hardware.Sound.Sample_Array;
      Last   : out Natural) is
   begin
      Generate_Sound (Buffer, Last, 1_500, 2_200);
   end Generate_Right_Top_Sound;

   --------------------
   -- Generate_Sound --
   --------------------

   procedure Generate_Sound
     (Buffer           : out Nu_Pogodi.Hardware.Sound.Sample_Array;
      Last             : out Natural;
      First_Frequency  : Positive;
      Second_Frequency : Positive)
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
      Buffer (Buffer'First .. Buffer'First + Half_Samples - 1) :=
        [others => First_Sample];
      Buffer
        (Buffer'First + Half_Samples ..
           Buffer'First + Samples_Per_Movement - 1) :=
             [others => Second_Sample];

      Last := Buffer'First + Samples_Per_Movement - 1;
   end Generate_Sound;

end Nu_Pogodi.Sounds.Samples;
