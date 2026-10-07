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

   procedure EXTI22_RTC_WKUP_Handler
     with Export, Convention => C, External_Name => "EXTI22_RTC_WKUP_Handler";

   Wakeup_Callback : A0B.Callbacks.Callback;

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

   -----------------------------
   -- EXTI22_RTC_WKUP_Handler --
   -----------------------------

   procedure EXTI22_RTC_WKUP_Handler is
   begin
      A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.WUTF := False;
      --  WUTF is cleared by writing zero. Write ones to the other rc_w0
      --  flags to preserve them, including flags set during this write.
      --  Clearing WUTF does not require unlocking RTC write protection.

      --  Clear the source before acknowledging EXTI22. PR is write-one-
      --  to-clear, so do not use a read-modify-write of this register.

      A0B.STM32F401.SVD.EXTI.EXTI_Periph.PR :=
        (PR             =>
           (As_Array => True, Arr => [22 => True, others => False]),
         Reserved_23_31 => 0);

      A0B.Callbacks.Emit (Wakeup_Callback);
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

      --  Configure wakeup timer:
      --    * disable wakeup timer
      --    * wait when it will be ready for configuration
      --    * select clock source
      --    * set auto-reload value
      --    * enable wakeup timer

      A0B.STM32F401.SVD.RTC.RTC_Periph.CR :=
        (@ with delta WUTE => False, WUTIE => False);
      --  Disable both timer and interrupt while configuring them.

      while not A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.WUTWF loop
         null;
      end loop;

      A0B.STM32F401.SVD.RTC.RTC_Periph.CR.WCKSEL := 2#000#;
      --  000: RTC/16 clock is selected

      A0B.STM32F401.SVD.RTC.RTC_Periph.WUTR := (WUT => 2_047, others => <>);
      --  (2_047 + 1) * 16 / 32_768 = 1 second

      A0B.STM32F401.SVD.RTC.RTC_Periph.ISR.WUTF := False;
      --  RTC state survives a system reset. Clear a previous wakeup flag
      --  so that the next expiry generates a new rising edge on EXTI22.

      --  Clear_Wakeup_Flag;

      --  Configure EXTI to process wakeup interrupts

      A0B.STM32F401.SVD.EXTI.EXTI_Periph.RTSR.TR.Arr (22) := True;
      A0B.STM32F401.SVD.EXTI.EXTI_Periph.FTSR.TR.Arr (22) := False;
      A0B.STM32F401.SVD.EXTI.EXTI_Periph.PR :=
        (PR             =>
           (As_Array => True, Arr => [22 => True, others => False]),
         Reserved_23_31 => 0);
      A0B.STM32F401.SVD.EXTI.EXTI_Periph.IMR.MR.Arr (22) := True;

      --  Configure NVIC

      A0B.ARMv7M.NVIC_Utilities.Clear_Pending (A0B.STM32F401.EXTI22_RTC_WKUP);
      A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt
        (A0B.STM32F401.EXTI22_RTC_WKUP);

      --  Start the timer only after EXTI and NVIC are ready.

      A0B.STM32F401.SVD.RTC.RTC_Periph.CR :=
        (@ with delta
           WUTE  => True,   --  1: Wakeup timer enabled
           WUTIE => True);  --  1: Wakeup timer interrupt enabled

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
