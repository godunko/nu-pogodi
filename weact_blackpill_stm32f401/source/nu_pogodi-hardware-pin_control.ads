--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Callbacks;

with Nu_Pogodi.Keyboard;

package Nu_Pogodi.Hardware.Pin_Control is

   procedure Initialize;

   procedure Configure_SPI1_Pins;

   procedure Configure_SPI1_MOSI_Input;
   --  Release shared SDA before the display starts sending data.

   procedure Configure_SPI1_MOSI_Output;
   --  Connect the push-pull MOSI output to SPI1 (AF5).

   procedure Configure_MIPI_Pins;

   procedure Configure_Keyboard_Pins (Callback : A0B.Callbacks.Callback);
   --  Configure keyboard pins and set callback to be emitted when change of
   --  key state is detected.

   procedure Set_MIPI_D_C (To : Boolean);

   procedure Set_SSD1683_RES (To : Boolean);

   function Get_SSD1683_BUSY return Boolean;

   procedure Enable_SSD1683_BUSY (Callback : A0B.Callbacks.Callback);
   --  Enable interrupt on falling edge of `BUSY` line. Emit given `Callback`
   --  on interrupt.
   --
   --  Callback is emitted once, interrupt is disabled automatically before
   --  callback execution.

   procedure Disable_SSD1683_BUSY;

   procedure Clear_Keyboard_Pending (Keys : Nu_Pogodi.Keyboard.Key_State);
   --  Clear interrupt pending state of given keys.

   function Get_Keyboard_Pending return Nu_Pogodi.Keyboard.Key_State;
   --  Pending edges are retained even while the interrupt is masked.

   procedure Enable_Keyboard_Interrupt;
   --  Enable key edge detection interrupt

   procedure Disable_Keyboard_Interrupt;
   --  Disable key edge detection interrupt

   function Get_Keyboard_State return Nu_Pogodi.Keyboard.Key_State;

end Nu_Pogodi.Hardware.Pin_Control;
