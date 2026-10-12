--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Nu_Pogodi.Keyboard;

package Nu_Pogodi.Hardware.Keyboard is

   procedure Initialize;

   function Get return Nu_Pogodi.Keyboard.Keyboard_State;
   --  Return debounced levels and consume accumulated press/release events.

end Nu_Pogodi.Hardware.Keyboard;
