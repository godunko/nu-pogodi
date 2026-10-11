--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.ARMv7M.NVIC_Utilities;
with A0B.STM32F401.SVD.GPIO;
with A0B.STM32F401.SVD.EXTI;
with A0B.STM32F401.SVD.RCC;
with A0B.STM32F401.SVD.SYSCFG;

package body Nu_Pogodi.Hardware.Pin_Control is

   MIPI_SPI_MOSI : constant := 7;   --  PA7
   MIPI_SPI_MISO : constant := 6;   --  PA6
   MIPI_SPI_SCK  : constant := 5;   --  PA5
   MIPI_SPI_NSS  : constant := 4;   --  PA4
   MIPI_D_C      : constant := 3;   --  PA3
   SSD1683_RES   : constant := 2;   --  PA2
   SSD1683_BUSY  : constant := 1;   --  PA1

   Keyboard_UP     : constant := 12;  --  PB12
   Keyboard_DOWN   : constant := 13;  --  PB13
   Keyboard_LEFT   : constant := 14;  --  PB14
   Keyboard_RIGHT  : constant := 15;  --  PB15
   Keyboard_MIDDLE : constant := 10;  --  PB10
   Keyboard_SET    : constant := 8;   --  PB8
   Keyboard_RESET  : constant := 9;   --  PB9

   SSD1683_BUSY_Callback : A0B.Callbacks.Callback;

   procedure EXTI1_Handler
     with Export, Convention => C, External_Name => "EXTI1_Handler";

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

   procedure Configure_Analog_All;
   --  Switch all GPIO pins into "analog" mode to minimize power consumption,
   --  with exception of SWDIO/SWCLK tp allow debugging.

   --------------------------
   -- Configure_Analog_All --
   --------------------------

   procedure Configure_Analog_All is
      Dummy : A0B.STM32F401.SVD.RCC.AHB1ENR_Register;

   begin
      A0B.STM32F401.SVD.RCC.RCC_Periph.AHB1ENR :=
        (@ with delta
           GPIOAEN => True,
           GPIOBEN => True,
           GPIOCEN => True,
           GPIODEN => True,
           GPIOEEN => True,
           GPIOHEN => True);
      Dummy := A0B.STM32F401.SVD.RCC.RCC_Periph.AHB1ENR;
      --  Enable clock of all GPIO peripheral

      --  A0B.STM32F401.SVD.GPIO.GPIOA_Periph.MODER.Arr := [others => 2#11#];
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.MODER.Arr :=
        [13 | 14 => 2#10#,  --  SWDIO, SWCLK: debugger interface
         others  => 2#11#];
      A0B.STM32F401.SVD.GPIO.GPIOB_Periph.MODER.Arr := [others => 2#11#];
      A0B.STM32F401.SVD.GPIO.GPIOC_Periph.MODER.Arr := [others => 2#11#];
      A0B.STM32F401.SVD.GPIO.GPIOD_Periph.MODER.Arr := [others => 2#11#];
      A0B.STM32F401.SVD.GPIO.GPIOE_Periph.MODER.Arr := [others => 2#11#];
      A0B.STM32F401.SVD.GPIO.GPIOH_Periph.MODER.Arr := [others => 2#11#];
      --  11: Analog mode

      A0B.STM32F401.SVD.RCC.RCC_Periph.AHB1ENR :=
        (@ with delta
           GPIOAEN => False,
           GPIOBEN => False,
           GPIOCEN => False,
           GPIODEN => False,
           GPIOEEN => False,
           GPIOHEN => False);
         --  Dummy := A0B.STM32F401.SVD.RCC.RCC_Periph.AHB1ENR;
      --  Disable clock of all GPIO peripheral
   end Configure_Analog_All;

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
        (A0B.STM32F401.SVD.GPIO.GPIOB_Periph, Keyboard_UP, Pull_Up);
      Configure_Input
        (A0B.STM32F401.SVD.GPIO.GPIOB_Periph, Keyboard_DOWN, Pull_Up);
      Configure_Input
        (A0B.STM32F401.SVD.GPIO.GPIOB_Periph, Keyboard_LEFT, Pull_Up);
      Configure_Input
        (A0B.STM32F401.SVD.GPIO.GPIOB_Periph, Keyboard_RIGHT, Pull_Up);
      Configure_Input
        (A0B.STM32F401.SVD.GPIO.GPIOB_Periph, Keyboard_MIDDLE, Pull_Up);
      Configure_Input
        (A0B.STM32F401.SVD.GPIO.GPIOB_Periph, Keyboard_SET, Pull_Up);
      Configure_Input
        (A0B.STM32F401.SVD.GPIO.GPIOB_Periph, Keyboard_RESET, Pull_Up);
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
      A0B.STM32F401.SVD.SYSCFG.SYSCFG_Periph.EXTICR1.EXTI.Arr (SSD1683_BUSY) :=
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

   --------------------------------
   -- Configure_SPI1_MOSI_Input --
   --------------------------------

   procedure Configure_SPI1_MOSI_Input is
   begin
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.MODER.Arr (MIPI_SPI_MOSI) := 2#00#;
   end Configure_SPI1_MOSI_Input;

   ---------------------------------
   -- Configure_SPI1_MOSI_Output --
   ---------------------------------

   procedure Configure_SPI1_MOSI_Output is
   begin
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.MODER.Arr (MIPI_SPI_MOSI) := 2#10#;
   end Configure_SPI1_MOSI_Output;

   -------------------------
   -- Configure_SPI1_Pins --
   -------------------------

   procedure Configure_SPI1_Pins is
   begin
      --  PA15: SPI1_NSS/CS
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.MODER.Arr (MIPI_SPI_NSS) := 2#10#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.AFRL.Arr (MIPI_SPI_NSS) := 2#0101#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.OSPEEDR.Arr (MIPI_SPI_NSS) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.OTYPER.OT.Arr (MIPI_SPI_NSS) :=
        False;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.PUPDR.Arr (MIPI_SPI_NSS) := 2#01#;

      --  PB3: SPI1_SCK/SCL
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.MODER.Arr (MIPI_SPI_SCK) := 2#10#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.AFRL.Arr (MIPI_SPI_SCK) := 2#0101#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.OSPEEDR.Arr (MIPI_SPI_SCK) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.OTYPER.OT.Arr (MIPI_SPI_SCK) :=
        False;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.PUPDR.Arr (MIPI_SPI_SCK) := 2#01#;

      --  PA7: SPI1_MOSI/SDA, input by default on the shared SDA line.
      --  Use AF5 with push-pull output only while transmitting.
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.MODER.Arr (MIPI_SPI_MOSI) := 2#00#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.AFRL.Arr (MIPI_SPI_MOSI) := 2#0101#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.OSPEEDR.Arr (MIPI_SPI_MOSI) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.OTYPER.OT.Arr (MIPI_SPI_MOSI) :=
        False;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.PUPDR.Arr (MIPI_SPI_MOSI) := 2#00#;

      --  PA6: SPI1_MISO/SDA
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.MODER.Arr (MIPI_SPI_MISO) := 2#10#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.AFRL.Arr (MIPI_SPI_MISO) := 2#0101#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.PUPDR.Arr (MIPI_SPI_MISO) := 2#01#;
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

   -------------------
   -- EXTI1_Handler --
   -------------------

   procedure EXTI1_Handler is
   begin
      if A0B.STM32F401.SVD.EXTI.EXTI_Periph.PR.PR.Arr (SSD1683_BUSY) then
         SSD1683_BUSY_EXTI_Mask_Interrupt;
         SSD1683_BUSY_EXTI_Clear_Pending;
         A0B.Callbacks.Emit_Once (SSD1683_BUSY_Callback);
      end if;
   end EXTI1_Handler;

   ------------------
   -- Get_KEY_DOWN --
   ------------------

   function Get_KEY_DOWN return Boolean is
   begin
      return A0B.STM32F401.SVD.GPIO.GPIOB_Periph.IDR.IDR.Arr (Keyboard_DOWN);
   end Get_KEY_DOWN;

   ------------------
   -- Get_KEY_LEFT --
   ------------------

   function Get_KEY_LEFT return Boolean is
   begin
      return A0B.STM32F401.SVD.GPIO.GPIOB_Periph.IDR.IDR.Arr (Keyboard_LEFT);
   end Get_KEY_LEFT;

   --------------------
   -- Get_KEY_MIDDLE --
   --------------------

   function Get_KEY_MIDDLE return Boolean is
   begin
      return A0B.STM32F401.SVD.GPIO.GPIOB_Periph.IDR.IDR.Arr (Keyboard_MIDDLE);
   end Get_KEY_MIDDLE;

   -------------------
   -- Get_KEY_RESET --
   -------------------

   function Get_KEY_RESET return Boolean is
   begin
      return A0B.STM32F401.SVD.GPIO.GPIOB_Periph.IDR.IDR.Arr (Keyboard_RESET);
   end Get_KEY_RESET;

   -------------------
   -- Get_KEY_RIGHT --
   -------------------

   function Get_KEY_RIGHT return Boolean is
   begin
      return A0B.STM32F401.SVD.GPIO.GPIOB_Periph.IDR.IDR.Arr (Keyboard_RIGHT);
   end Get_KEY_RIGHT;

   -----------------
   -- Get_KEY_SET --
   -----------------

   function Get_KEY_SET return Boolean is
   begin
      return A0B.STM32F401.SVD.GPIO.GPIOB_Periph.IDR.IDR.Arr (Keyboard_SET);
   end Get_KEY_SET;

   ----------------
   -- Get_KEY_UP --
   ----------------

   function Get_KEY_UP return Boolean is
   begin
      return A0B.STM32F401.SVD.GPIO.GPIOB_Periph.IDR.IDR.Arr (Keyboard_UP);
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
      Configure_Analog_All;

      A0B.STM32F401.SVD.RCC.RCC_Periph.APB2ENR.SYSCFGEN := True;

      A0B.STM32F401.SVD.RCC.RCC_Periph.AHB1ENR.GPIOAEN := True;
      A0B.STM32F401.SVD.RCC.RCC_Periph.AHB1ENR.GPIOBEN := True;

      A0B.ARMv7M.NVIC_Utilities.Clear_Pending (A0B.STM32F401.EXTI1);
      A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt (A0B.STM32F401.EXTI1);
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
              (As_Array => True, Arr => [MIPI_D_C => True, others => False]),
            BR => (As_Array => True, Arr => [others => False]))
         else
           (BS => (As_Array => True, Arr => [others => False]),
            BR =>
              (As_Array => True, Arr => [MIPI_D_C => True, others => False])));
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
               Arr      => [SSD1683_RES => True, others => False]),
            BR => (As_Array => True, Arr => [others => False]))
         else
           (BS => (As_Array => True, Arr => [others => False]),
            BR =>
              (As_Array => True,
               Arr      => [SSD1683_RES => True, others => False])));
   end Set_SSD1683_RES;

   -------------------------------------
   -- SSD1683_BUSY_EXTI_Clear_Pending --
   -------------------------------------

   procedure SSD1683_BUSY_EXTI_Clear_Pending is
   begin
      A0B.STM32F401.SVD.EXTI.EXTI_Periph.PR :=
        (PR             =>
           (As_Array => True, Arr => [SSD1683_BUSY => True, others => False]),
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
