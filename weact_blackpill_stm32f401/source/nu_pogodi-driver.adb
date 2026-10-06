--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.ARMv7M.SysTick_Clock_Timer;

with Nu_Pogodi.Application;
with Nu_Pogodi.Hardware.Pin_Control;
with Nu_Pogodi.Hardware.RTC;
with Nu_Pogodi.Hardware.SSD1683;

procedure Nu_Pogodi.Driver is
begin
   A0B.ARMv7M.SysTick_Clock_Timer.Initialize
     (Use_Processor_Clock => True,
      Clock_Frequency     => 80_000_000);

   Nu_Pogodi.Hardware.RTC.Initialize;
   Nu_Pogodi.Hardware.Pin_Control.Initialize;
   Nu_Pogodi.Hardware.SSD1683.Initialize;

   Nu_Pogodi.Application.Run;
end Nu_Pogodi.Driver;
