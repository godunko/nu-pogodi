--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.STM32F401.SVD.PWR;
with A0B.STM32F401.SVD.RCC;
with A0B.STM32F401.SVD.RTC;

package body Nu_Pogodi.Hardware.RTC is

   -----------
   -- Clock --
   -----------

   function Clock return Time is
   begin
      return Result : Time do
         declare
            TR : constant A0B.STM32F401.SVD.RTC.TR_Register :=
              A0B.STM32F401.SVD.RTC.RTC_Periph.TR;

         begin
            Result.Seconds_Ones := Seconds_Ones_Type (TR.SU);
            Result.Seconds_Tens := Seconds_Tens_Type (TR.ST);
            Result.Minutes_Ones := Minutes_Ones_Type (TR.MNU);
            Result.Minutes_Tens := Minutes_Tens_Type (TR.MNT);
            Result.Hours_Ones   := Hours_Ones_Type (TR.HU);
            Result.Hours_Tens   := Hours_Tens_Type (TR.HT);
            Result.PM           := TR.PM;
         end;

         --  Read DR is necessary to "unlock" update of values in shadow
         --  registers.

         declare
            DR : constant A0B.STM32F401.SVD.RTC.DR_Register :=
              A0B.STM32F401.SVD.RTC.RTC_Periph.DR
                with Unreferenced;

         begin
            null;
         end;
      end return;
   end Clock;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      --  Enable clock of PWR peripheral: not needed, clock is enabled by
      --  startup code.

      A0B.STM32F401.SVD.PWR.PWR_Periph.CR.DBP := True;
      --  1: Access to RTC and RTC Backup registers enabled.

      --  Enable LSE and wait till it ready

      A0B.STM32F401.SVD.RCC.RCC_Periph.BDCR :=
        (@ with delta
           LSEON  => True,    --  1: LSE clock ON
           LSEBYP => False);  --  0: LSE oscillator not bypassed

      while not A0B.STM32F401.SVD.RCC.RCC_Periph.BDCR.LSERDY loop
         null;
      end loop;

      --  Select clock source for RTC and enable RTC

      A0B.STM32F401.SVD.RCC.RCC_Periph.BDCR.RTCSEL :=
        (As_Array => False, Val => 2#01#);
      --  01: LSE oscillator clock used as the RTC clock

      A0B.STM32F401.SVD.RCC.RCC_Periph.BDCR.RTCEN := True;
      --  1: RTC clock enabled

      --  XXX Initial initialization is not implemented !!!

      --  Reinitiate load of values into shadow regiters, and wait till values
      --  are loaded.

      A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.RSF := False;

      while not A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.RSF loop
         null;
      end loop;
   end Initialize;

end Nu_Pogodi.Hardware.RTC;
