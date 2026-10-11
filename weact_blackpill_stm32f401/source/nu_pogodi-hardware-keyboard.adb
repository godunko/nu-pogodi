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
   begin
      return
         (State =>
            (Nu_Pogodi.Keyboard.Left_Top     =>
                not Nu_Pogodi.Hardware.Pin_Control.Get_KEY_UP,
             Nu_Pogodi.Keyboard.Right_Top    =>
                not Nu_Pogodi.Hardware.Pin_Control.Get_KEY_RIGHT,
             Nu_Pogodi.Keyboard.Left_Bottom  =>
                not Nu_Pogodi.Hardware.Pin_Control.Get_KEY_LEFT,
             Nu_Pogodi.Keyboard.Right_Bottom =>
                not Nu_Pogodi.Hardware.Pin_Control.Get_KEY_DOWN,
             Nu_Pogodi.Keyboard.Middle       =>
                not Nu_Pogodi.Hardware.Pin_Control.Get_KEY_MIDDLE,
             Nu_Pogodi.Keyboard.Game_A       =>
                not Nu_Pogodi.Hardware.Pin_Control.Get_KEY_SET,
             Nu_Pogodi.Keyboard.Game_B       =>
                not Nu_Pogodi.Hardware.Pin_Control.Get_KEY_RESET),
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
