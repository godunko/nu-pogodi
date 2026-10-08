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

   Keyboard_UP     : constant := 6;  --  PA6
   Keyboard_DOWN   : constant := 5;  --  PA5
   Keyboard_LEFT   : constant := 4;  --  PA4
   Keyboard_RIGHT  : constant := 3;  --  PA3
   Keyboard_MIDDLE : constant := 2;  --  PA2
   Keyboard_SET    : constant := 1;  --  PA1
   Keyboard_RESET  : constant := 0;  --  PA0

   SSD1683_BUSY_Callback : A0B.Callbacks.Callback;

   procedure EXTI9_5_Handler
     with Export, Convention => C, External_Name => "EXTI9_5_Handler";

   procedure SSD1683_BUSY_EXTI_Clear_Pending with Inline;
   --  Clear pending status of `SSD1683_BUSY`

   procedure SSD1683_BUSY_EXTI_Mask_Interrupt with Inline;
   --  Mask interrupt of `SSD1683_BUSY`

   procedure SSD1683_BUSY_EXTI_Unmask_Interrupt with Inline;
   --  Unmask interrupt of `SSD1683_BUSY`

   type Pull_Mode is (None, Pull_Up, Pull_Down);

   procedure Configure_Input
     (GPIO : in out A0B.STM32F401.SVD.GPIO.GPIO_Peripheral;
      Pin  : Natural;
      Pull : Pull_Mode);

   ---------------------
   -- Configure_Input --
   ---------------------

   procedure Configure_Input
     (GPIO : in out A0B.STM32F401.SVD.GPIO.GPIO_Peripheral;
      Pin  : Natural;
      Pull : Pull_Mode) is
   begin
      GPIO.MODER.Arr (Pin) := 2#00#;  --  00: Input
      GPIO.PUPDR.Arr (Pin) :=
         (case Pull is
            when None => 2#00#,        --  00: No pull-up, pull-down
            when Pull_Up   => 2#01#,   --  01: Pull-up
            when Pull_Down => 2#10#);  --  10: Pull-down
   end Configure_Input;

   -----------------------------
   -- Configure_Keyboard_Pins --
   -----------------------------

   procedure Configure_Keyboard_Pins is
   begin
      --  Implementation for configuring keyboard pins goes here

      Configure_Input
        (A0B.STM32F401.SVD.GPIO.GPIOA_Periph, Keyboard_UP, Pull_Up);
      Configure_Input
        (A0B.STM32F401.SVD.GPIO.GPIOA_Periph, Keyboard_DOWN, Pull_Up);
      Configure_Input
        (A0B.STM32F401.SVD.GPIO.GPIOA_Periph, Keyboard_LEFT, Pull_Up);
      Configure_Input
        (A0B.STM32F401.SVD.GPIO.GPIOA_Periph, Keyboard_RIGHT, Pull_Up);
      Configure_Input
        (A0B.STM32F401.SVD.GPIO.GPIOA_Periph, Keyboard_MIDDLE, Pull_Up);
      Configure_Input
        (A0B.STM32F401.SVD.GPIO.GPIOA_Periph, Keyboard_SET, Pull_Up);
      Configure_Input
        (A0B.STM32F401.SVD.GPIO.GPIOA_Periph, Keyboard_RESET, Pull_Up);
   end Configure_Keyboard_Pins;

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
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.BSRR.BR.Arr (SSD1683_RES) := True;
      --  MIPI DBI recommends to set `RESX` line to `low` during display
      --  power-on process. It should help to avoid BUSY signal toggle at
      --  application initialization time, and an issue described above for
      --  `BUSY` line.

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

   --------------------------
   -- Disable_SSD1683_BUSY --
   --------------------------

   procedure Disable_SSD1683_BUSY is
   begin
      --  * unset callback
      --  * mask interrupt in EXTI.IMR
      --  * clear pending request if any in ESTI.PR

      A0B.Callbacks.Unset (SSD1683_BUSY_Callback);
      SSD1683_BUSY_EXTI_Mask_Interrupt;
      SSD1683_BUSY_EXTI_Clear_Pending;
   end Disable_SSD1683_BUSY;

   -------------------------
   -- Enable_SSD1683_BUSY --
   -------------------------

   procedure Enable_SSD1683_BUSY (Callback : A0B.Callbacks.Callback) is
   begin
      SSD1683_BUSY_Callback := Callback;
      SSD1683_BUSY_EXTI_Clear_Pending;
      SSD1683_BUSY_EXTI_Unmask_Interrupt;
   end Enable_SSD1683_BUSY;

   ---------------------
   -- EXTI9_5_Handler --
   ---------------------

   EXT_TIME : A0B.Time.Monotonic_Time with Volatile;

   procedure EXTI9_5_Handler is
   begin
      EXT_TIME := A0B.Time.Clock;

      if A0B.STM32F401.SVD.EXTI.EXTI_Periph.PR.PR.Arr (SSD1683_BUSY) then
         SSD1683_BUSY_EXTI_Mask_Interrupt;
         SSD1683_BUSY_EXTI_Clear_Pending;
         A0B.Callbacks.Emit_Once (SSD1683_BUSY_Callback);
      end if;
   end EXTI9_5_Handler;

   ------------------
   -- Get_KEY_DOWN --
   ------------------

   function Get_KEY_DOWN return Boolean is
   begin
      return A0B.STM32F401.SVD.GPIO.GPIOA_Periph.IDR.IDR.Arr (Keyboard_DOWN);
   end Get_KEY_DOWN;

   ------------------
   -- Get_KEY_LEFT --
   ------------------

   function Get_KEY_LEFT return Boolean is
   begin
      return A0B.STM32F401.SVD.GPIO.GPIOA_Periph.IDR.IDR.Arr (Keyboard_LEFT);
   end Get_KEY_LEFT;

   --------------------
   -- Get_KEY_MIDDLE --
   --------------------

   function Get_KEY_MIDDLE return Boolean is
   begin
      return A0B.STM32F401.SVD.GPIO.GPIOA_Periph.IDR.IDR.Arr (Keyboard_MIDDLE);
   end Get_KEY_MIDDLE;

   -------------------
   -- Get_KEY_RESET --
   -------------------

   function Get_KEY_RESET return Boolean is
   begin
      return A0B.STM32F401.SVD.GPIO.GPIOA_Periph.IDR.IDR.Arr (Keyboard_RESET);
   end Get_KEY_RESET;

   -------------------
   -- Get_KEY_RIGHT --
   -------------------

   function Get_KEY_RIGHT return Boolean is
   begin
      return A0B.STM32F401.SVD.GPIO.GPIOA_Periph.IDR.IDR.Arr (Keyboard_RIGHT);
   end Get_KEY_RIGHT;

   -----------------
   -- Get_KEY_SET --
   -----------------

   function Get_KEY_SET return Boolean is
   begin
      return A0B.STM32F401.SVD.GPIO.GPIOA_Periph.IDR.IDR.Arr (Keyboard_SET);
   end Get_KEY_SET;

   ----------------
   -- Get_KEY_UP --
   ----------------

   function Get_KEY_UP return Boolean is
   begin
      return A0B.STM32F401.SVD.GPIO.GPIOA_Periph.IDR.IDR.Arr (Keyboard_UP);
   end Get_KEY_UP;

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

   -------------------------------------
   -- SSD1683_BUSY_EXTI_Clear_Pending --
   -------------------------------------

   procedure SSD1683_BUSY_EXTI_Clear_Pending is
   begin
      A0B.STM32F401.SVD.EXTI.EXTI_Periph.PR :=
        (PR             =>
           (As_Array => True, Arr => (SSD1683_BUSY => True, others => False)),
         Reserved_23_31 => 0);
      --  Clear pending request unconditionally
   end SSD1683_BUSY_EXTI_Clear_Pending;

   --------------------------------------
   -- SSD1683_BUSY_EXTI_Mask_Interrupt --
   --------------------------------------

   procedure SSD1683_BUSY_EXTI_Mask_Interrupt is
   begin
      A0B.STM32F401.SVD.EXTI.EXTI_Periph.IMR.MR.Arr (SSD1683_BUSY) := False;
      --  0: Interrupt request from line x is masked
   end SSD1683_BUSY_EXTI_Mask_Interrupt;

   ----------------------------------------
   -- SSD1683_BUSY_EXTI_Unmask_Interrupt --
   ----------------------------------------

   procedure SSD1683_BUSY_EXTI_Unmask_Interrupt is
   begin
      A0B.STM32F401.SVD.EXTI.EXTI_Periph.IMR.MR.Arr (SSD1683_BUSY) := True;
      --  1: Interrupt request from line x is not masked
   end SSD1683_BUSY_EXTI_Unmask_Interrupt;

end Nu_Pogodi.Hardware.Pin_Control;
