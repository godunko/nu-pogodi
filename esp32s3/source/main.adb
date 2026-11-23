--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.ESPIDF_Timer_Clock_Timer;

with Nu_Pogodi.Hardware.Pin_Control;
with Nu_Pogodi.Hardware.Keyboard;
with Nu_Pogodi.Hardware.SSD1683;
with Nu_Pogodi.Application;
with Nu_Pogodi.Hardware.Sound;

procedure Main is
begin
   A0B.ESPIDF_Timer_Clock_Timer.Initialize;
   Nu_Pogodi.Hardware.Pin_Control.Initialize;
   Nu_Pogodi.Hardware.Keyboard.Initialize;
   Nu_Pogodi.Hardware.SSD1683.Initialize;
   Nu_Pogodi.Hardware.Sound.Initialize;

   Nu_Pogodi.Application.Run;
end Main;
