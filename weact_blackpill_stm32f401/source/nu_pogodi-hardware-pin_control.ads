--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

package Nu_Pogodi.Hardware.Pin_Control is

   procedure Initialize;

   procedure Configure_SPI1_Pins;

   procedure Configure_MIPI_Pins;

   procedure Set_MIPI_D_C (To : Boolean);

end Nu_Pogodi.Hardware.Pin_Control;
