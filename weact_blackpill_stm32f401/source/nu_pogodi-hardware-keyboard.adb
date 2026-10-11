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

   function Get return Nu_Pogodi.Keyboard.Keyboard_State is
      use type Nu_Pogodi.Keyboard.Key_State;

   begin
      return
        (State  => not Nu_Pogodi.Hardware.Pin_Control.Get_Keyboard_State,
         others => <>);
   end Get;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Nu_Pogodi.Hardware.Pin_Control.Configure_Keyboard_Pins;
   end Initialize;

end Nu_Pogodi.Hardware.Keyboard;
