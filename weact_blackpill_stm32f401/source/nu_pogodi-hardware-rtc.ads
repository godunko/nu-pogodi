--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Callbacks;

package Nu_Pogodi.Hardware.RTC is

   type Seconds_Ones_Type is range 0 .. 9;

   type Seconds_Tens_Type is range 0 .. 5;

   type Minutes_Ones_Type is range 0 .. 9;

   type Minutes_Tens_Type is range 0 .. 5;

   type Hours_Ones_Type is range 0 .. 9;

   type Hours_Tens_Type is range 0 .. 2;

   type Dates_Ones_Type is range 0 .. 9;

   type Dates_Tens_Type is range 0 .. 3;

   type Months_Ones_Type is range 0 .. 9;

   type Months_Tens_Type is range 0 .. 1;

   type Years_Ones_Type is range 0 .. 9;

   type Years_Tens_Type is range 0 .. 9;

   type Time is record
      PM           : Boolean;
      Hours_Tens   : Hours_Tens_Type;
      Hours_Ones   : Hours_Ones_Type;
      Minutes_Tens : Minutes_Tens_Type;
      Minutes_Ones : Minutes_Ones_Type;
      Seconds_Tens : Seconds_Tens_Type;
      Seconds_Ones : Seconds_Ones_Type;
   end record;

   type Date_Time is record
      Years_Tens   : Years_Tens_Type;
      Years_Ones   : Years_Ones_Type;
      Months_Tens  : Months_Tens_Type;
      Months_Ones  : Months_Ones_Type;
      Dates_Tens   : Dates_Tens_Type;
      Dates_Ones   : Dates_Ones_Type;

      PM           : Boolean;
      Hours_Tens   : Hours_Tens_Type;
      Hours_Ones   : Hours_Ones_Type;
      Minutes_Tens : Minutes_Tens_Type;
      Minutes_Ones : Minutes_Ones_Type;
      Seconds_Tens : Seconds_Tens_Type;
      Seconds_Ones : Seconds_Ones_Type;
   end record;

   procedure Initialize;

   function Clock return Date_Time;

   function Clock return Time;

   procedure Set_Wakeup (Callback : A0B.Callbacks.Callback);

end Nu_Pogodi.Hardware.RTC;
