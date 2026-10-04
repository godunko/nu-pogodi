--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Nu_Pogodi.Hardware.Pin_Control;
with Nu_Pogodi.Hardware.SPI;

package body Nu_Pogodi.Hardware.MIPI is

   --  Aux : A0B.Types.Unsigned_8 with Export, Volatile;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Nu_Pogodi.Hardware.Pin_Control.Configure_MIPI_Pins;
      Nu_Pogodi.Hardware.SPI.Initialize;

      --  Nu_Pogodi.Hardware.SPI.Acquire_MIPI_Read;
      --  Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (False);  --  Command mode
      --  Nu_Pogodi.Hardware.SPI.Transmit (16#2F#);  --  Status Bit Read

      --  Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (True);  --  Data mode
      --  Nu_Pogodi.Hardware.SPI.Receive (Aux);
   end Initialize;

end Nu_Pogodi.Hardware.MIPI;
