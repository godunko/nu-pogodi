--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.ARMv7M.NVIC_Utilities;
with A0B.STM32F401.SVD.EXTI;
with A0B.STM32F401.SVD.PWR;
with A0B.STM32F401.SVD.RCC;
with A0B.STM32F401.SVD.RTC;

package body Nu_Pogodi.Hardware.RTC is

   procedure EXTI17_RTC_Alarm_Handler
     with Export, Convention => C, External_Name => "EXTI17_RTC_Alarm_Handler";

   Wakeup_Callback : A0B.Callbacks.Callback;

   procedure Configure_Alarm;

   -----------
   -- Clock --
   -----------

   function Clock return Date_Time is
   begin
      return Result : Date_Time do
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

         declare
            DR : constant A0B.STM32F401.SVD.RTC.DR_Register :=
              A0B.STM32F401.SVD.RTC.RTC_Periph.DR;

         begin
            Result.Dates_Ones  := Dates_Ones_Type (DR.DT);
            Result.Dates_Tens  := Dates_Tens_Type (DR.DU);
            Result.Months_Ones := (if DR.MT then 1 else 0);
            Result.Months_Tens := Months_Tens_Type (DR.MU);
            Result.Years_Ones  := Years_Ones_Type (DR.YT);
            Result.Years_Tens  := Years_Tens_Type (DR.YU);
         end;
      end return;
   end Clock;

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

   ---------------------
   -- Configure_Alarm --
   ---------------------

   procedure Configure_Alarm is
   begin
      A0B.STM32F401.SVD.RTC.RTC_Periph.CR :=
        (@ with delta
           ALRAE  => False,   --  0: Alarm A disabled
           ALRAIE => False);  --  0: Alarm A interrupt disabled
      --  Disable both alarm and interrupt while configuring them.

      while not A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.ALRAWF loop
         --  1: Alarm A update allowed

         null;
      end loop;

      --  Clear pending alarm flag

      A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.ALRAF := False;

      --  Configure EXTI to process alarm interrupt

      A0B.STM32F401.SVD.EXTI.EXTI_Periph.RTSR.TR.Arr (17) := True;
      A0B.STM32F401.SVD.EXTI.EXTI_Periph.FTSR.TR.Arr (17) := False;
      A0B.STM32F401.SVD.EXTI.EXTI_Periph.PR :=
        (PR             =>
           (As_Array => True, Arr => [17 => True, others => False]),
         Reserved_23_31 => 0);
      A0B.STM32F401.SVD.EXTI.EXTI_Periph.IMR.MR.Arr (17) := True;

      --  Configure NVIC

      A0B.ARMv7M.NVIC_Utilities.Clear_Pending (A0B.STM32F401.EXTI17_RTC_Alarm);
      A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt
        (A0B.STM32F401.EXTI17_RTC_Alarm);

      --  Configure alarm

      A0B.STM32F401.SVD.RTC.RTC_Periph.ALRMAR :=
        (SU    => 0,
         ST    => 0,
         MSK1  => False,  --  0: Alarm A set if the seconds match
         MNU   => 0,
         MNT   => 0,
         MSK2  => True,   --  1: Minutes don’t care in Alarm A comparison
         HU    => 0,
         HT    => 0,
         PM    => False,  --  0: AM or 24-hour format
         MSK3  => True,   --  1: Hours don’t care in Alarm A comparison
         DU    => 0,
         DT    => 0,
         WDSEL => False,  --  0: DU[3:0] represents the date units
         MSK4  => True);  --  1: Date/day don’t care in Alarm A comparison

      A0B.STM32F401.SVD.RTC.RTC_Periph.ALRMASSR :=
        (SS             => 0,
         Reserved_15_23 => 0,
         MASKSS         => 2#0000#,
         --  0: No comparison on sub seconds for Alarm A. The alarm is set when
         --  the seconds unit is incremented (assuming that the rest of the
         --  fields match).
         Reserved_28_31 => 0);

      --  Enable alarm A and interrupt
      A0B.STM32F401.SVD.RTC.RTC_Periph.CR :=
        (@ with delta
           ALRAE  => True,   --  1: Alarm A enabled
           ALRAIE => True);  --  1: Alarm A interrupt enabled
   end Configure_Alarm;

   ------------------------------
   -- EXTI17_RTC_Alarm_Handler --
   ------------------------------

   procedure EXTI17_RTC_Alarm_Handler is
   begin
      A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.ALRAF := False;
      --  ALRAF is cleared by writing zero. Write ones to the other rc_w0
      --  flags to preserve them, including flags set during this write.
      --  Clearing ALRAF does not require unlocking RTC write protection.

      A0B.STM32F401.SVD.EXTI.EXTI_Periph.PR :=
        (PR             =>
           (As_Array => True, Arr => [17 => True, others => False]),
         Reserved_23_31 => 0);
      --  Clear the source before acknowledging EXTI17. PR is write-one-
      --  to-clear, so do not use a read-modify-write of this register.

      A0B.Callbacks.Emit (Wakeup_Callback);
   end EXTI17_RTC_Alarm_Handler;

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

      --  Unlock RTC write protection

      A0B.STM32F401.SVD.RTC.RTC_Periph.WPR := (16#CA#, others => <>);
      A0B.STM32F401.SVD.RTC.RTC_Periph.WPR := (16#53#, others => <>);

      --  Enter initialization mode

      A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.INIT := True;

      while not A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.INITF loop
         null;
      end loop;

      --  Program prescalers. Two write operations must be done, first for
      --  synchronous prescaler, and second for asynchronous.

      A0B.STM32F401.SVD.RTC.RTC_Periph.PRER.PREDIV_S := 16#FF#;
      A0B.STM32F401.SVD.RTC.RTC_Periph.PRER.PREDIV_A := 16#7F#;

      --  Configure 24-hours format.

      A0B.STM32F401.SVD.RTC.RTC_Periph.CR.FMT := False;
      --  0: 24 hour/day format

      --  Leave calendar initialization mode

      A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.INIT := False;

      Configure_Alarm;

      --  Re-lock write protection

      A0B.STM32F401.SVD.RTC.RTC_Periph.WPR := (16#FF#, others => <>);

      --  Reinitiate load of values into shadow regiters, and wait till values
      --  are loaded.

      A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.RSF := False;

      while not A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.RSF loop
         null;
      end loop;
   end Initialize;

   ----------------
   -- Set_Wakeup --
   ----------------

   procedure Set_Wakeup (Callback : A0B.Callbacks.Callback) is
   begin
      Wakeup_Callback := Callback;
   end Set_Wakeup;

end Nu_Pogodi.Hardware.RTC;
