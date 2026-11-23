--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Nu_Pogodi.Hardware.Sound;
with Nu_Pogodi.Sounds.Buffers;

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
     (Success          : in out Boolean;
      First_Frequency  : Positive;
      Second_Frequency : Positive);

   --------------------------
   -- Generate_Catch_Sound --
   --------------------------

   procedure Generate_Catch_Sound
     (Success : in out Boolean)
   is
      Frequencies : constant array (Natural range 0 .. 3) of Positive :=
        [1_760, 2_093, 2_637, 3_136];
      Samples_Per_Note : constant := Samples_Per_Catch / Frequencies'Length;

   begin
      for Part in Frequencies'Range loop
         declare
            Period : constant Positive := 1_000_000 / Frequencies (Part);

         begin
            Nu_Pogodi.Sounds.Buffers.Encode
              (Period, Period / 2, Samples_Per_Note, Success);
         end;
      end loop;
   end Generate_Catch_Sound;

   -------------------------------
   -- Generate_Chick_Jump_Sound --
   -------------------------------

   procedure Generate_Chick_Jump_Sound
     (Success : in out Boolean)
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
            Nu_Pogodi.Sounds.Buffers.Encode
              (Period, Period / 2, Samples_Per_Note, Success);
         end;
      end loop;
   end Generate_Chick_Jump_Sound;

   -------------------------
   -- Generate_Fall_Sound --
   -------------------------

   procedure Generate_Fall_Sound
     (Success : in out Boolean)
   is
      Period_Start : constant := 2_223;
      Period_End   : constant := 8_334;

   begin
      for J in 0 .. Samples_Per_Fall - 1 loop
         declare
            Period : constant Positive :=
              Period_Start
                + (Period_End - Period_Start) * J / Samples_Per_Fall;

         begin
            Nu_Pogodi.Sounds.Buffers.Encode
              (Period  => Period,
               High    =>
                 (if J > Samples_Per_Fall - 40 then 0 else (Period - 1) / 2),
               Success => Success);
         end;
      end loop;
   end Generate_Fall_Sound;

   ------------------------------
   -- Generate_Game_Over_Sound --
   ------------------------------

   procedure Generate_Game_Over_Sound
     (Success : in out Boolean)
   is
      Start_Frequency : constant := 700;
      End_Frequency   : constant := 180;
      Frequency_Scale : constant := Samples_Per_Game_Over ** 2;

   begin
      --  Keep the quadratic frequency curve without floating-point rounding.

      for J in 0 .. Samples_Per_Game_Over - 1 loop
         declare
            Scaled_Frequency : constant Positive :=
              Start_Frequency * Frequency_Scale
                - (Start_Frequency - End_Frequency) * J * J;
            Period           : constant Positive :=
              Positive
                (1_000_000 * Long_Long_Integer (Frequency_Scale)
                   / Long_Long_Integer (Scaled_Frequency));
            Pulse            : Natural := Period / 2;

         begin
            if Scaled_Frequency < 300 * Frequency_Scale then
               if J mod 12 > 6 then
                  Pulse := @ + Period / 4;

               else
                  Pulse := @ - Period / 4;
               end if;
            end if;

            if J > Samples_Per_Game_Over - 200 then
               Pulse := 0;
            end if;

            Nu_Pogodi.Sounds.Buffers.Encode
              (Period => Period, High => Pulse, Success => Success);
         end;
      end loop;
   end Generate_Game_Over_Sound;

   --------------------------------
   -- Generate_Left_Bottom_Sound --
   --------------------------------

   procedure Generate_Left_Bottom_Sound
     (Success : in out Boolean) is
   begin
      Generate_Sound (Success, 1_800, 1_200);
   end Generate_Left_Bottom_Sound;

   -----------------------------
   -- Generate_Left_Top_Sound --
   -----------------------------

   procedure Generate_Left_Top_Sound
     (Success : in out Boolean) is
   begin
      Generate_Sound (Success, 2_400, 1_600);
   end Generate_Left_Top_Sound;

   ---------------------------------
   -- Generate_Right_Bottom_Sound --
   ---------------------------------

   procedure Generate_Right_Bottom_Sound
     (Success : in out Boolean) is
   begin
      Generate_Sound (Success, 1_100, 1_700);
   end Generate_Right_Bottom_Sound;

   ------------------------------
   -- Generate_Right_Top_Sound --
   ------------------------------

   procedure Generate_Right_Top_Sound
     (Success : in out Boolean) is
   begin
      Generate_Sound (Success, 1_500, 2_200);
   end Generate_Right_Top_Sound;

   --------------------
   -- Generate_Sound --
   --------------------

   procedure Generate_Sound
     (Success          : in out Boolean;
      First_Frequency  : Positive;
      Second_Frequency : Positive)
   is
      Half_Samples : constant := Samples_Per_Movement / 2;

      First_Period  : constant Positive := 1_000_000 / First_Frequency;
      Second_Period : constant Positive := 1_000_000 / Second_Frequency;

   begin
      Nu_Pogodi.Sounds.Buffers.Encode
        (First_Period, First_Period / 2, Half_Samples, Success);
      Nu_Pogodi.Sounds.Buffers.Encode
        (Second_Period, Second_Period / 2,
         Samples_Per_Movement - Half_Samples, Success);
   end Generate_Sound;

end Nu_Pogodi.Sounds.Samples;
