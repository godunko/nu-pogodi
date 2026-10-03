--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.STM32F401.SVD.GPIO;
with A0B.STM32F401.SVD.RCC;

package body Nu_Pogodi.Hardware.Pin_Control is

   -------------------------
   -- Configure_MIPI_Pins --
   -------------------------

   procedure Configure_MIPI_Pins is
   begin
      --  PA8: EXTI8/BUSY
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.MODER.Arr (8) := 2#00#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.PUPDR.Arr (8) := 2#01#;

      --  PA9: OUT/RES, high
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.MODER.Arr (9) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.OSPEEDR.Arr (9) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.OTYPER.OT.Arr (9) := False;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.PUPDR.Arr (9) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.BSRR.BS.Arr (9) := True;

      --  PA10: OUT/D/C, high
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.MODER.Arr (10) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.OSPEEDR.Arr (10) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.OTYPER.OT.Arr (10) := False;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.PUPDR.Arr (10) := 2#01#;
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.BSRR.BS.Arr (10) := True;
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

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      A0B.STM32F401.SVD.RCC.RCC_Periph.AHB1ENR.GPIOAEN := True;
      A0B.STM32F401.SVD.RCC.RCC_Periph.AHB1ENR.GPIOBEN := True;
   end Initialize;

   ------------------
   -- Set_MIPI_D_C --
   ------------------

   procedure Set_MIPI_D_C (To : Boolean) is
   begin
      A0B.STM32F401.SVD.GPIO.GPIOA_Periph.BSRR :=
        (if To
         then
           (BS => (As_Array => True, Arr => (10 => True, others => False)),
            BR => (As_Array => True, Arr => (others => False)))
         else
           (BS => (As_Array => True, Arr => (others => False)),
            BR => (As_Array => True, Arr => (10 => True, others => False))));
   end Set_MIPI_D_C;

end Nu_Pogodi.Hardware.Pin_Control;
