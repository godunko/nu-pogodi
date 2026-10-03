--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Types;

package Nu_Pogodi.Hardware.SPI is

   procedure Initialize;

   procedure Acquire_MIPI_Read;

   procedure Acquire_MIPI_Write;

   procedure Transmit (Command : A0B.Types.Unsigned_8);

   procedure Receive (Data : out A0B.Types.Unsigned_8);

end Nu_Pogodi.Hardware.SPI;
