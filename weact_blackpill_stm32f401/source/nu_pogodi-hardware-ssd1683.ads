--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Callbacks;

package Nu_Pogodi.Hardware.SSD1683 is

   procedure Initialize;

   procedure Reset (Callback : A0B.Callbacks.Callback);
   --  Do hardware reset and software reset of the panel.

end Nu_Pogodi.Hardware.SSD1683;
