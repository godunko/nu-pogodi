--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Ada.Calendar;

with A0B.Types;

package Nu_Pogodi.Desktop_Clock is

   function Timer return A0B.Types.Unsigned_4;

   function Seconds_Ones
     (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4;

   function Seconds_Tens
     (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4;

   function Minutes_Ones
     (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4;

   function Minutes_Tens
     (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4;

   function Hours_Ones
     (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4;

   function Hours_Tens
     (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4;

end Nu_Pogodi.Desktop_Clock;
