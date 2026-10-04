--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.ARMv7M.NVIC_Utilities;
with A0B.STM32F401.SVD.GPIO;
with A0B.STM32F401.SVD.EXTI;
with A0B.STM32F401.SVD.RCC;
with A0B.STM32F401.SVD.SYSCFG;
with A0B.Time;
with A0B.Time.Clock;

package body Nu_Pogodi.Hardware.Pin_Control is

   MIPI_D_C     : constant := 10;  --  PA10
   SSD1683_RES  : constant := 9;   --  PA9
   SSD1683_BUSY : constant := 8;   --  PA8

   SSD1683_BUSY_Callback : A0B.Callbacks.Callback;

   procedure EXTI9_5_Handler
     with Export, Convention => C, External_Name => "EXTI9_5_Handler";

   -------------------------
   -- Configure_MIPI_Pins --
   -------------------------

   procedure Configure_MIPI_Pins is
   begin
      --  PA8: EXTI8/BUSY
      --
      --  Note: display controller starts own initialization sequence on power
      --  up, and toggle BUSY line. It can be or cannot be caught during
      --  application initialization. Thus, interrupt is not enabled at this
      --  point. During initialization, display driver let display controller
      --  complete its initialization sequence, do hardware reset and enable
      --  interrupt after that.
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.MODER.Arr (SSD1683_BUSY) := 2#00#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.PUPDR.Arr (SSD1683_BUSY) := 2#01#;
      A0B.STM32F401.SVD.SYSCFG.SYSCFG_Periph.EXTICR3.EXTI.Arr (SSD1683_BUSY) :=
        2#0000#;  --  0000: PA[x] pin
      A0B.STM32F401.SVD.EXTI.EXTI_Periph.RTSR.TR.Arr (SSD1683_BUSY) := False;
      --  0: Rising trigger disabled (for Event and Interrupt) for input line
      A0B.STM32F401.SVD.EXTI.EXTI_Periph.FTSR.TR.Arr (SSD1683_BUSY) := True;
      --  1: Falling trigger enabled (for Event and Interrupt) for input line.

      --  PA9: OUT/RES, high
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.MODER.Arr (SSD1683_RES) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.OSPEEDR.Arr (SSD1683_RES) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.OTYPER.OT.Arr (SSD1683_RES) := False;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.PUPDR.Arr (SSD1683_RES) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.BSRR.BS.Arr (SSD1683_RES) := True;

      --  PA10: OUT/D/C, high
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.MODER.Arr (MIPI_D_C) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.OSPEEDR.Arr (MIPI_D_C) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.OTYPER.OT.Arr (MIPI_D_C) := False;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.PUPDR.Arr (MIPI_D_C) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.BSRR.BS.Arr (MIPI_D_C) := True;
   end Configure_MIPI_Pins;

   -------------------------
   -- Configure_SPI1_Pins --
   -------------------------

   procedure Configure_SPI1_Pins is
   begin
      --  PA15: SPI1_NSS/CS
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.MODER.Arr (15) := 2#10#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.AFRH.Arr (15) := 2#0101#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.OSPEEDR.Arr (15) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.OTYPER.OT.Arr (15) := False;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.PUPDR.Arr (15) := 2#01#;

      --  PB3: SPI1_SCK/SCL
      A0B.STM32F401.SVD.GPIO.GPIOB_Periph.MODER.Arr (3) := 2#10#;
      A0B.STM32F401.SVD.GPIO.GPIOB_Periph.AFRL.Arr (3) := 2#0101#;
      A0B.STM32F401.SVD.GPIO.GPIOB_Periph.OSPEEDR.Arr (3) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOB_Periph.OTYPER.OT.Arr (3) := False;
      A0B.STM32F401.SVD.GPIO.GPIOB_Periph.PUPDR.Arr (3) := 2#01#;

      --  PB5: SPI1_MOSI/SDA
      A0B.STM32F401.SVD.GPIO.GPIOB_Periph.MODER.Arr (5) := 2#10#;
      A0B.STM32F401.SVD.GPIO.GPIOB_Periph.AFRL.Arr (5) := 2#0101#;
      A0B.STM32F401.SVD.GPIO.GPIOB_Periph.OSPEEDR.Arr (5) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOB_Periph.OTYPER.OT.Arr (5) := False;
      A0B.STM32F401.SVD.GPIO.GPIOB_Periph.PUPDR.Arr (5) := 2#01#;
   end Configure_SPI1_Pins;

   -------------------------
   -- Enable_SSD1683_BUSY --
   -------------------------

   procedure Enable_SSD1683_BUSY (Callback : A0B.Callbacks.Callback) is
   begin
      SSD1683_BUSY_Callback := Callback;

      A0B.STM32F401.SVD.EXTI.EXTI_Periph.PR :=
        (PR             =>
           (As_Array => True, Arr => (SSD1683_BUSY => True, others => False)),
         Reserved_23_31 => 0);
      --  Clear pending status if any
      A0B.STM32F401.SVD.EXTI.EXTI_Periph.IMR.MR.Arr (SSD1683_BUSY) := True;
      --  1: Interrupt request from line x is not masked
   end Enable_SSD1683_BUSY;

   ---------------------
   -- EXTI9_5_Handler --
   ---------------------

   EXT_TIME : A0B.Time.Monotonic_Time with Volatile;

   procedure EXTI9_5_Handler is
   begin
      EXT_TIME := A0B.Time.Clock;

      if A0B.STM32F401.SVD.EXTI.EXTI_Periph.PR.PR.Arr (SSD1683_BUSY) then
         A0B.Callbacks.Emit_Once (SSD1683_BUSY_Callback);
      end if;

      raise Program_Error;
   end EXTI9_5_Handler;

   ----------------------
   -- Get_SSD1683_BUSY --
   ----------------------

   function Get_SSD1683_BUSY return Boolean is
   begin
      return A0B.STM32F401.SVD.GPIO.GPIOA_Periph.IDR.IDR.Arr (SSD1683_BUSY);
   end Get_SSD1683_BUSY;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      A0B.STM32F401.SVD.RCC.RCC_Periph.APB2ENR.SYSCFGEN := True;

      A0B.STM32F401.SVD.RCC.RCC_Periph.AHB1ENR.GPIOAEN := True;
      A0B.STM32F401.SVD.RCC.RCC_Periph.AHB1ENR.GPIOBEN := True;

      A0B.ARMv7M.NVIC_Utilities.Clear_Pending (A0B.STM32F401.EXTI9_5);
      A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt (A0B.STM32F401.EXTI9_5);
   end Initialize;

   ------------------
   -- Set_MIPI_D_C --
   ------------------

   procedure Set_MIPI_D_C (To : Boolean) is
   begin
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.BSRR :=
        (if To
         then
           (BS =>
              (As_Array => True, Arr => (MIPI_D_C => True, others => False)),
            BR => (As_Array => True, Arr => (others => False)))
         else
           (BS => (As_Array => True, Arr => (others => False)),
            BR =>
              (As_Array => True, Arr => (MIPI_D_C => True, others => False))));
   end Set_MIPI_D_C;

   ---------------------
   -- Set_SSD1683_RES --
   ---------------------

   procedure Set_SSD1683_RES (To : Boolean) is
   begin
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.BSRR :=
        (if To
         then
           (BS =>
              (As_Array => True,
               Arr      => (SSD1683_RES => True, others => False)),
            BR => (As_Array => True, Arr => (others => False)))
         else
           (BS => (As_Array => True, Arr => (others => False)),
            BR =>
              (As_Array => True,
               Arr      => (SSD1683_RES => True, others => False))));
   end Set_SSD1683_RES;

end Nu_Pogodi.Hardware.Pin_Control;
