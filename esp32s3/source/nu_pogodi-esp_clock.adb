--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with ESPIDF.Timer;

package body Nu_Pogodi.ESP_Clock is

   function Whole_Seconds (Item : Ada.Calendar.Time) return Natural;
   --  Elapsed whole seconds since midnight in the supplied snapshot.

   -------------------
   -- Whole_Seconds --
   -------------------

   function Whole_Seconds (Item : Ada.Calendar.Time) return Natural is
      Seconds : constant Ada.Calendar.Day_Duration :=
        Ada.Calendar.Seconds (Item);
      Result  : Natural := Natural (Seconds);

   begin
      --  Fixed-point to integer conversion rounds; discard the fractional
      --  second so digits never advance before the next second begins.

      if Duration (Result) > Seconds then
         Result := Result - 1;
      end if;

      return Result;
   end Whole_Seconds;

   ----------------
   -- Hours_Ones --
   ----------------

   function Hours_Ones (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4 is
      Hours : constant Natural := Whole_Seconds (Item) / 3_600;

   begin
      return A0B.Types.Unsigned_4 (Hours mod 10);
   end Hours_Ones;

   ----------------
   -- Hours_Tens --
   ----------------

   function Hours_Tens (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4 is
      Hours : constant Natural := Whole_Seconds (Item) / 3_600;

   begin
      return A0B.Types.Unsigned_4 (Hours / 10);
   end Hours_Tens;

   ------------------
   -- Minutes_Ones --
   ------------------

   function Minutes_Ones (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4 is
      Minutes : constant Natural := (Whole_Seconds (Item) / 60) mod 60;

   begin
      return A0B.Types.Unsigned_4 (Minutes mod 10);
   end Minutes_Ones;

   ------------------
   -- Minutes_Tens --
   ------------------

   function Minutes_Tens (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4 is
      Minutes : constant Natural := (Whole_Seconds (Item) / 60) mod 60;

   begin
      return A0B.Types.Unsigned_4 (Minutes / 10);
   end Minutes_Tens;

   ------------------
   -- Seconds_Ones --
   ------------------

   function Seconds_Ones (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4 is
      Seconds : constant Natural := Whole_Seconds (Item) mod 60;

   begin
      return A0B.Types.Unsigned_4 (Seconds mod 10);
   end Seconds_Ones;

   ------------------
   -- Seconds_Tens --
   ------------------

   function Seconds_Tens (Item : Ada.Calendar.Time) return A0B.Types.Unsigned_4 is
      Seconds : constant Natural := Whole_Seconds (Item) mod 60;

   begin
      return A0B.Types.Unsigned_4 (Seconds / 10);
   end Seconds_Tens;

   -----------
   -- Timer --
   -----------

   function Timer return A0B.Types.Unsigned_4 is
      use type ESPIDF.int64_t;

   begin
      return
        A0B.Types.Unsigned_4
          (ESPIDF.Timer.esp_timer_get_time mod A0B.Types.Unsigned_4'Modulus);
   end Timer;

end Nu_Pogodi.ESP_Clock;
