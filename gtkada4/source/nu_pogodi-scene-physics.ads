--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Ada.Calendar;

with Nu_Pogodi.Desktop_Clock;
with Nu_Pogodi.Scene.Generic_Physics;

package Nu_Pogodi.Scene.Physics is new Nu_Pogodi.Scene.Generic_Physics
  (Timer        => Nu_Pogodi.Desktop_Clock.Timer,
   Time         => Ada.Calendar.Time,
   Clock        => Ada.Calendar.Clock,
   Seconds_Ones => Nu_Pogodi.Desktop_Clock.Seconds_Ones,
   Seconds_Tens => Nu_Pogodi.Desktop_Clock.Seconds_Tens,
   Minutes_Ones => Nu_Pogodi.Desktop_Clock.Minutes_Ones,
   Minutes_Tens => Nu_Pogodi.Desktop_Clock.Minutes_Tens,
   Hours_Ones   => Nu_Pogodi.Desktop_Clock.Hours_Ones,
   Hours_Tens   => Nu_Pogodi.Desktop_Clock.Hours_Tens);
