--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.ARMv7M.SysTick_Clock_Timer;

procedure Nu_Pogodi.Driver is
begin
   A0B.ARMv7M.SysTick_Clock_Timer.Initialize
     (Use_Processor_Clock => True,
      Clock_Frequency     => 80_000_000);
end Nu_Pogodi.Driver;
