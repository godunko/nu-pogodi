--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

package Nu_Pogodi.Keyboard is

   type Key is
     (Left_Top,
      Right_Top,
      Left_Bottom,
      Right_Bottom,
      Middle,
      Game_A,
      Game_B);

   type Key_State is array (Key) of Boolean with Component_Size => 1;

   type Keyboard_State is record
      State    : Key_State;
      Pressed  : Key_State;
      Released : Key_State;
   end record with Object_Size => 32;

   for Keyboard_State use record
      State    at 0 range 0 .. 6;
      Pressed  at 1 range 0 .. 6;
      Released at 2 range 0 .. 6;
   end record;

end Nu_Pogodi.Keyboard;
