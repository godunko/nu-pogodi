--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

package Nu_Pogodi.Hardware.Keyboard is

   type Keyboard_State is record
      Left_Top     : Boolean;
      Right_Top    : Boolean;
      Left_Bottom  : Boolean;
      Right_Bottom : Boolean;
   end record;

   procedure Initialize;

   function Get return Keyboard_State;

end Nu_Pogodi.Hardware.Keyboard;
