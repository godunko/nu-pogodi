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

   procedure EXTI22_RTC_WKUP_Handler
     with Export, Convention => C, External_Name => "EXTI22_RTC_WKUP_Handler";

   Clock_Wakeup_Callback : aliased A0B.Callbacks.Callback;
   Timer_Wakeup_Callback : aliased A0B.Callbacks.Callback;

   procedure Clear_Interrupt_Flags
     (Alarm : Boolean := False;
      Timer : Boolean := False);
   --  Clear given flags in status register.

   procedure Clear_Pending_WKUP_Interrupt;
   --  Clear pending state of of EXTI22_RTC_WKUP interrupt at all levels:
   --    * RTC
   --    * EXTI
   --    * NVIC
   --
   --  RTC write-protection doesn't prevent clear of pending state of
   --  interrupt.

   procedure Configure_Alarm;

   procedure Configure_Timer;

   ---------------------------
   -- Clear_Interrupt_Flags --
   ---------------------------

   procedure Clear_Interrupt_Flags
     (Alarm : Boolean := False;
      Timer : Boolean := False) is
   begin
      A0B.STM32F401.SVD.RTC.RTC_Periph.ISR :=
        (@ with delta
           ALRAF  => not Alarm,
           ALRBF  => True,
           WUTF   => not Timer,
           TSF    => True,
           TSOVF  => True,
           TAMP1F => True,
           TAMP2F => True,
           RSF    => True,
           SHPF   => True);
      --  Write ones to unrelated rc_w0 flags, including flags asserted
      --  between the read and write; preserve the current INIT bit.
      --  These flags [13:8] are not write protected.
   end Clear_Interrupt_Flags;

   ----------------------------------
   -- Clear_Pending_WKUP_Interrupt --
   ----------------------------------

   procedure Clear_Pending_WKUP_Interrupt is
   begin
      A0B.STM32F401.SVD.RTC.RTC_Periph.ISR :=
        (@ with delta
           ALRAF  => True,
           ALRBF  => True,
           WUTF   => False,
           TSF    => True,
           TSOVF  => True,
           TAMP1F => True,
           TAMP2F => True,
           RSF    => True,
           SHPF   => True);
      --  Write ones to unrelated rc_w0 flags, including flags asserted
      --  between the read and write; preserve the current INIT bit.
      --  These flags [13:8] are not write protected.

      A0B.STM32F401.SVD.EXTI.EXTI_Periph.PR :=
        (PR => (As_Array => True, Arr => [22 => True, others => False]),
         others => <>);
      A0B.ARMv7M.NVIC_Utilities.Clear_Pending (A0B.STM32F401.EXTI22_RTC_WKUP);
   end Clear_Pending_WKUP_Interrupt;

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
            Result.Dates_Ones  := Dates_Ones_Type (DR.DU);
            Result.Dates_Tens  := Dates_Tens_Type (DR.DT);
            Result.Months_Ones := Months_Ones_Type (DR.MU);
            Result.Months_Tens := (if DR.MT then 1 else 0);
            Result.Years_Ones  := Years_Ones_Type (DR.YU);
            Result.Years_Tens  := Years_Tens_Type (DR.YT);
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

      Clear_Interrupt_Flags (Alarm => True);

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

   ---------------------
   -- Configure_Timer --
   ---------------------

   procedure Configure_Timer is
   begin
      A0B.STM32F401.SVD.RTC.RTC_Periph.CR :=
        (@ with delta
           WUTE  => False,   --  0: Wakeup timer disabled
           WUTIE => False);  --  0: Wakeup timer interrupt disabled

      while not A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.WUTWF loop
         null;
      end loop;

      --  Clear pending wakeup timer flag

      Clear_Interrupt_Flags (Timer => True);

      --  Configure EXTI to process wakeup timer events

      A0B.STM32F401.SVD.EXTI.EXTI_Periph.RTSR.TR.Arr (22) := True;
      A0B.STM32F401.SVD.EXTI.EXTI_Periph.FTSR.TR.Arr (22) := False;
      A0B.STM32F401.SVD.EXTI.EXTI_Periph.PR :=
        (PR => (As_Array => True, Arr => [22 => True, others => False]),
         others => <>);
      A0B.STM32F401.SVD.EXTI.EXTI_Periph.IMR.MR.Arr (22) := True;

      --  Configure NVIC

      A0B.ARMv7M.NVIC_Utilities.Clear_Pending
        (A0B.STM32F401.EXTI22_RTC_WKUP);
      A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt
        (A0B.STM32F401.EXTI22_RTC_WKUP);

      --  Configure wakeup timer

      A0B.STM32F401.SVD.RTC.RTC_Periph.CR.WCKSEL := 2#000#;
      --  000: RTC/16 clock is selected
      A0B.STM32F401.SVD.RTC.RTC_Periph.WUTR := (WUT => 5, others => <>);
      --  (5 + 1) * 16 / 32_768 = 2.9296875 ms, approximately 3 ms.
   end Configure_Timer;

   ------------------------------
   -- EXTI17_RTC_Alarm_Handler --
   ------------------------------

   procedure EXTI17_RTC_Alarm_Handler is
   begin
      Clear_Interrupt_Flags (Alarm => True);

      A0B.STM32F401.SVD.EXTI.EXTI_Periph.PR :=
        (PR             =>
           (As_Array => True, Arr => [17 => True, others => False]),
         Reserved_23_31 => 0);
      --  Clear the source before acknowledging EXTI17. PR is write-one-
      --  to-clear, so do not use a read-modify-write of this register.

      A0B.Callbacks.Emit (Clock_Wakeup_Callback);
   end EXTI17_RTC_Alarm_Handler;

   -----------------------------
   -- EXTI22_RTC_WKUP_Handler --
   -----------------------------

   procedure EXTI22_RTC_WKUP_Handler is
   begin
      --  Disable wakeup timer interrupt, keep timer running.

      A0B.STM32F401.SVD.RTC.RTC_Periph.WPR := (16#CA#, others => <>);
      A0B.STM32F401.SVD.RTC.RTC_Periph.WPR := (16#53#, others => <>);
      A0B.STM32F401.SVD.RTC.RTC_Periph.CR.WUTIE := False;
      A0B.STM32F401.SVD.RTC.RTC_Periph.WPR := (16#FF#, others => <>);

      Clear_Pending_WKUP_Interrupt;

      --  Emit callback

      A0B.Callbacks.Emit_Once (Timer_Wakeup_Callback);

      --  If callback doesn't request interrupt after next interval, disable
      --  wakeup timer.

      if not A0B.STM32F401.SVD.RTC.RTC_Periph.CR.WUTIE then
         A0B.STM32F401.SVD.RTC.RTC_Periph.WPR := (16#CA#, others => <>);
         A0B.STM32F401.SVD.RTC.RTC_Periph.WPR := (16#53#, others => <>);
         A0B.STM32F401.SVD.RTC.RTC_Periph.CR :=
           (@ with delta
              WUTE  => False,   --  0: Wakeup timer disabled
              WUTIE => False);  --  0: Wakeup timer interrupt disabled
         A0B.STM32F401.SVD.RTC.RTC_Periph.WPR := (16#FF#, others => <>);

         Clear_Pending_WKUP_Interrupt;
      end if;
   end EXTI22_RTC_WKUP_Handler;

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
      Configure_Timer;

      --  Re-lock write protection

      A0B.STM32F401.SVD.RTC.RTC_Periph.WPR := (16#FF#, others => <>);

      --  Reinitiate load of values into shadow regiters, and wait till values
      --  are loaded.

      A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.RSF := False;

      while not A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.RSF loop
         null;
      end loop;
   end Initialize;

   ---------------------------
   -- Schedule_Timer_Wakeup --
   ---------------------------

   procedure Schedule_Timer_Wakeup (Callback : A0B.Callbacks.Callback) is
   begin
      if not A0B.STM32F401.SVD.RTC.RTC_Periph.CR.WUTE then
         --  A stopped counter may still be synchronizing its previous stop.

         while not A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.WUTWF loop
            null;
         end loop;
      end if;

      Timer_Wakeup_Callback := Callback;

      --  Clear pending interrupt state at all levels

      Clear_Pending_WKUP_Interrupt;

      --  Enable timer interrupt, and timer itself, if it was disabled.

      A0B.STM32F401.SVD.RTC.RTC_Periph.WPR := (16#CA#, others => <>);
      A0B.STM32F401.SVD.RTC.RTC_Periph.WPR := (16#53#, others => <>);
      A0B.STM32F401.SVD.RTC.RTC_Periph.CR :=
        (@ with delta
           WUTE  => True,   --  1: Wakeup timer enabled
           WUTIE => True);  --  1: Wakeup timer interrupt enabled
      A0B.STM32F401.SVD.RTC.RTC_Periph.WPR := (16#FF#, others => <>);
   end Schedule_Timer_Wakeup;

   ----------------------
   -- Set_Clock_Wakeup --
   ----------------------

   procedure Set_Clock_Wakeup (Callback : A0B.Callbacks.Callback) is
   begin
      Clock_Wakeup_Callback := Callback;
   end Set_Clock_Wakeup;

end Nu_Pogodi.Hardware.RTC;
