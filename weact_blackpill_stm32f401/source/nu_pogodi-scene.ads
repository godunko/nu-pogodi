--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Nu_Pogodi.Generic_Scene;
with Nu_Pogodi.Hardware.RTC;
with Nu_Pogodi.Hardware.Timer;

package Nu_Pogodi.Scene is
  new Nu_Pogodi.Generic_Scene
    (Timer        => Nu_Pogodi.Hardware.Timer,
     Time         => Nu_Pogodi.Hardware.RTC.Time,
     Clock        => Nu_Pogodi.Hardware.RTC.Clock,
     Seconds_Ones => Nu_Pogodi.Hardware.RTC.Seconds_Ones,
     Seconds_Tens => Nu_Pogodi.Hardware.RTC.Seconds_Tens,
     Minutes_Ones => Nu_Pogodi.Hardware.RTC.Minutes_Ones,
     Minutes_Tens => Nu_Pogodi.Hardware.RTC.Minutes_Tens,
     Hours_Ones   => Nu_Pogodi.Hardware.RTC.Hours_Ones,
     Hours_Tens   => Nu_Pogodi.Hardware.RTC.Hours_Tens);
