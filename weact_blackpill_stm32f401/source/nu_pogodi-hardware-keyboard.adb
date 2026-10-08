--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Nu_Pogodi.Hardware.Pin_Control;

package body Nu_Pogodi.Hardware.Keyboard is

   ---------
   -- Get --
   ---------

   function Get return Keyboard_State is
   begin
      return
        (Left_Top     => not Nu_Pogodi.Hardware.Pin_Control.Get_KEY_UP,
         Right_Top    => not Nu_Pogodi.Hardware.Pin_Control.Get_KEY_RIGHT,
         Left_Bottom  => not Nu_Pogodi.Hardware.Pin_Control.Get_KEY_LEFT,
         Right_Bottom => not Nu_Pogodi.Hardware.Pin_Control.Get_KEY_DOWN);
   end Get;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Nu_Pogodi.Hardware.Pin_Control.Configure_Keyboard_Pins;
   end Initialize;

end Nu_Pogodi.Hardware.Keyboard;
