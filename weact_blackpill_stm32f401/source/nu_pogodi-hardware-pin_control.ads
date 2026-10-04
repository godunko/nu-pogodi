--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Callbacks;

package Nu_Pogodi.Hardware.Pin_Control is

   procedure Initialize;

   procedure Configure_SPI1_Pins;

   procedure Configure_MIPI_Pins;

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

end Nu_Pogodi.Hardware.Pin_Control;
