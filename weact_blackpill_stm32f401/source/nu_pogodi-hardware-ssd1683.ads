--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Buffers;
with A0B.Callbacks;

package Nu_Pogodi.Hardware.SSD1683 is

   procedure Initialize;

   procedure Reset (Callback : A0B.Callbacks.Callback);
   --  Do hardware reset and software reset of the panel.

   procedure Write_RAM_Black_White
     (Data     : A0B.Buffers.Abstract_Buffer'Class;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Write given data to BW RAM

   procedure Write_RAM_Red
     (Data     : A0B.Buffers.Abstract_Buffer'Class;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Write given data to RED RAM

end Nu_Pogodi.Hardware.SSD1683;
