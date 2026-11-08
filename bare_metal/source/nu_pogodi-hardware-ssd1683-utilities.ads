--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

package Nu_Pogodi.Hardware.SSD1683.Utilities is

   procedure Select_Partial
     (Ranges      : Waveform_Temperature_Range_Array;
      Modes       : A0B.Types.Unsigned_24;
      Temperature : A0B.Types.Integer_8;
      Index       : out Waveform_Setting_Index;
      Success     : out Boolean);
   --  Select the first matching partial-refresh/temperature slot for the
   --  monochrome panel.

end Nu_Pogodi.Hardware.SSD1683.Utilities;
