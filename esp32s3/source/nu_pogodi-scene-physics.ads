--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Ada.Calendar;

with Nu_Pogodi.Scene.Generic_Physics;
with Nu_Pogodi.ESP_Clock;

package Nu_Pogodi.Scene.Physics is
  new Nu_Pogodi.Scene.Generic_Physics
    (Timer        => Nu_Pogodi.ESP_Clock.Timer,
     Time         => Ada.Calendar.Time,
     Clock        => Ada.Calendar.Clock,
     Seconds_Ones => Nu_Pogodi.ESP_Clock.Seconds_Ones,
     Seconds_Tens => Nu_Pogodi.ESP_Clock.Seconds_Tens,
     Minutes_Ones => Nu_Pogodi.ESP_Clock.Minutes_Ones,
     Minutes_Tens => Nu_Pogodi.ESP_Clock.Minutes_Tens,
     Hours_Ones   => Nu_Pogodi.ESP_Clock.Hours_Ones,
     Hours_Tens   => Nu_Pogodi.ESP_Clock.Hours_Tens);
