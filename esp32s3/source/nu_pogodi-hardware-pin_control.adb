--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with System;

with A0B.Time;
with A0B.Time.Clock;
with A0B.Types;

with ESPIDF.Driver.GPIO;

package body Nu_Pogodi.Hardware.Pin_Control is

   MIPI_D_C     : constant := 14;
   SSD1686_BUSY : constant := 9;
   SSD1686_RES  : constant := 13;

   --  --  procedure Configure_SPI1_Pins;

   --  --  procedure Configure_SPI1_MOSI_Input;
   --  --  --  Release shared SDA before the display starts sending data.

   --  --  procedure Configure_SPI1_MOSI_Output;
   --  --  --  Connect the push-pull MOSI output to SPI1 (AF5).

   --  --  procedure Configure_Keyboard_Pins (Callback : A0B.Callbacks.Callback);
   --  --  --  Configure keyboard pins and set callback to be emitted when change of
   --  --  --  key state is detected.

   --  --  procedure Configure_Buzzer_Pin;
   --  --  --  Configure TIM1 CH1 output pin, used to control buzzer

   --  --  function Get_SSD1683_BUSY return Boolean;

   --  --  procedure Clear_Keyboard_Pending (Keys : Nu_Pogodi.Keyboard.Key_State);
   --  --  --  Clear interrupt pending state of given keys.

   --  --  function Get_Keyboard_Pending return Nu_Pogodi.Keyboard.Key_State;
   --  --  --  Pending edges are retained even while the interrupt is masked.

   --  --  procedure Enable_Keyboard_Interrupt;
   --  --  --  Enable key edge detection interrupt

   --  --  procedure Disable_Keyboard_Interrupt;
   --  --  --  Disable key edge detection interrupt

   --  --  function Get_Keyboard_State return Nu_Pogodi.Keyboard.Key_State;

   SSD1683_BUSY_Callback : aliased A0B.Callbacks.Callback;

   procedure BUSY_Handler (Arg : System.Address) with Convention => C;

   ------------------
   -- BUSY_Handler --
   ------------------

   procedure BUSY_Handler (Arg : System.Address) is
   begin
      ESPIDF.Driver.GPIO.gpio_intr_disable (SSD1686_BUSY);
      A0B.Callbacks.Emit_Once (SSD1683_BUSY_Callback);
   end BUSY_Handler;

   -------------------------
   -- Configure_MIPI_Pins --
   -------------------------

   procedure Configure_MIPI_Pins is
      use type ESPIDF.uint64_t;

      OUT_GPIO_Config  : ESPIDF.Driver.GPIO.gpio_config_t;
      EXTI_GPIO_Config : ESPIDF.Driver.GPIO.gpio_config_t;

   begin
      ESPIDF.Driver.GPIO.Set_pin_bit_mask
        (OUT_GPIO_Config,
         A0B.Types.Shift_Left (1, MIPI_D_C)
         or A0B.Types.Shift_Left (1, SSD1686_RES));
      ESPIDF.Driver.GPIO.Set_mode
        (OUT_GPIO_Config, ESPIDF.Driver.GPIO.GPIO_MODE_OUTPUT);
      ESPIDF.Driver.GPIO.gpio_config (OUT_GPIO_Config);
      ESPIDF.Driver.GPIO.gpio_set_level (MIPI_D_C, 1);
      ESPIDF.Driver.GPIO.gpio_set_level (SSD1686_RES, 1);

      ESPIDF.Driver.GPIO.Set_pin_bit_mask
        (EXTI_GPIO_Config, A0B.Types.Shift_Left (1, SSD1686_BUSY));
      ESPIDF.Driver.GPIO.Set_mode
        (EXTI_GPIO_Config, ESPIDF.Driver.GPIO.GPIO_MODE_INPUT);
      ESPIDF.Driver.GPIO.Set_pull_up_en
        (EXTI_GPIO_Config, ESPIDF.Driver.GPIO.GPIO_PULLUP_ENABLE);
      ESPIDF.Driver.GPIO.Set_intr_type
        (EXTI_GPIO_Config, ESPIDF.Driver.GPIO.GPIO_INTR_NEGEDGE);
      ESPIDF.Driver.GPIO.gpio_config (EXTI_GPIO_Config);
      ESPIDF.Driver.GPIO.gpio_isr_handler_add
        (SSD1686_BUSY, BUSY_Handler'Access, System.Null_Address);
      ESPIDF.Driver.GPIO.gpio_intr_disable (SSD1686_BUSY);
   end Configure_MIPI_Pins;

   ----------------------------
   -- Disable_SSD1683_BUSY --
   ----------------------------

   procedure Disable_SSD1683_BUSY is
   begin
      ESPIDF.Driver.GPIO.gpio_intr_disable (SSD1686_BUSY);
   end Disable_SSD1683_BUSY;

   -------------------------
   -- Enable_SSD1683_BUSY --
   -------------------------

   procedure Enable_SSD1683_BUSY (Callback : A0B.Callbacks.Callback) is
   begin
      SSD1683_BUSY_Callback := Callback;
      ESPIDF.Driver.GPIO.gpio_intr_enable (SSD1686_BUSY);
   end Enable_SSD1683_BUSY;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      ESPIDF.Driver.GPIO.gpio_install_isr_service (0);
   end Initialize;

   ------------------
   -- Set_MIPI_D_C --
   ------------------

   procedure Set_MIPI_D_C (To : Boolean) is
   begin
      ESPIDF.Driver.GPIO.gpio_set_level (MIPI_D_C, (if To then 1 else 0));
   end Set_MIPI_D_C;

   ---------------------
   -- Set_SSD1683_RES --
   ---------------------

   procedure Set_SSD1683_RES (To : Boolean) is
   begin
      ESPIDF.Driver.GPIO.gpio_set_level (SSD1686_RES, (if To then 1 else 0));
   end Set_SSD1683_RES;

end Nu_Pogodi.Hardware.Pin_Control;
