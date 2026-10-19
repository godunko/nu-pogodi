--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Ada.Calendar.Formatting;
with Ada.Calendar.Time_Zones;
with Ada.Real_Time;

package body Nu_Pogodi.Desktop_Clock is

   Epoch : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;

   ----------------
   -- Hours_Ones --
   ----------------

   function Hours_Ones
     (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4 is
     (A0B.Types.Unsigned_4 (Ada.Calendar.Formatting.Hour
        (Item, Ada.Calendar.Time_Zones.UTC_Time_Offset (Item)) mod 10));

   ----------------
   -- Hours_Tens --
   ----------------

   function Hours_Tens
     (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4 is
     (A0B.Types.Unsigned_4 (Ada.Calendar.Formatting.Hour
        (Item, Ada.Calendar.Time_Zones.UTC_Time_Offset (Item)) / 10));

   ------------------
   -- Minutes_Ones --
   ------------------

   function Minutes_Ones
     (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4 is
     (A0B.Types.Unsigned_4 (Ada.Calendar.Formatting.Minute
        (Item, Ada.Calendar.Time_Zones.UTC_Time_Offset (Item)) mod 10));

   ------------------
   -- Minutes_Tens --
   ------------------

   function Minutes_Tens
     (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4 is
     (A0B.Types.Unsigned_4 (Ada.Calendar.Formatting.Minute
        (Item, Ada.Calendar.Time_Zones.UTC_Time_Offset (Item)) / 10));

   ------------------
   -- Seconds_Ones --
   ------------------

   function Seconds_Ones
     (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4 is
     (A0B.Types.Unsigned_4 (Ada.Calendar.Formatting.Second (Item) mod 10));

   ------------------
   -- Seconds_Tens --
   ------------------

   function Seconds_Tens
     (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4 is
     (A0B.Types.Unsigned_4 (Ada.Calendar.Formatting.Second (Item) / 10));

   -----------
   -- Timer --
   -----------

   function Timer return A0B.Types.Unsigned_4 is
      use Ada.Real_Time;

   begin
      return
        A0B.Types.Unsigned_4
          (((Ada.Real_Time.Clock - Epoch) / Microseconds (1)) mod 16);
   end Timer;

end Nu_Pogodi.Desktop_Clock;
