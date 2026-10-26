--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Types;

with Nu_Pogodi.Keyboard;

generic
   with function Timer return A0B.Types.Unsigned_4;

   type Time is private;

   with function Clock return Time;

   with function Seconds_Ones (Item : Time) return A0B.Types.Unsigned_4;

   with function Seconds_Tens (Item : Time) return A0B.Types.Unsigned_4;

   with function Minutes_Ones (Item : Time) return A0B.Types.Unsigned_4;

   with function Minutes_Tens (Item : Time) return A0B.Types.Unsigned_4;

   with function Hours_Ones (Item : Time) return A0B.Types.Unsigned_4;

   with function Hours_Tens (Item : Time) return A0B.Types.Unsigned_4;

package Nu_Pogodi.Generic_Scene is

   type Sound_Kind is
     (None,
      Move_Left_Top,
      Move_Left_Bottom,
      Move_Right_Top,
      Move_Right_Bottom);

   type Game_Mode is (None, Mode_A, Mode_B);

   type Lane_Side is (Left, Right);
   type Lane_Height is (Top, Bottom);

   type Wolf_Position is record
      Side   : Lane_Side;
      Height : Lane_Height;
   end record;

   type Egg_Step is range 1 .. 5;

   type Egg_Array is array (Egg_Step) of Boolean;

   type Game_Lanes is array (Lane_Side, Lane_Height) of Egg_Array;

   type Optional_Lane is
     (None, Left_Top, Right_Top, Left_Bottom, Right_Bottom);

   subtype Lane is Optional_Lane range Left_Top .. Right_Bottom;

   procedure Initialize (Mode : Game_Mode)
     with Pre => Mode /= None;

   procedure Update_Physics_Tick
     (Refresh : in out Boolean;
      Sound   : out Sound_Kind);
   --  Sound is None unless this tick requests a display refresh.

   procedure Update_Keyboad_State (State : Nu_Pogodi.Keyboard.Keyboard_State);

   function Is_Game_Over return Boolean;

private

   type Score is mod 1_000;

   subtype Score_Digit is Score range 0 .. 9;

   type Game_State is record
      Mode                 : Game_Mode             := None;

      Current_Tick         : A0B.Types.Unsigned_32 := 0;
      Current_Cycle        : A0B.Types.Unsigned_32 := 0;
      Cycle_Ticks          : A0B.Types.Unsigned_32 := 31;
      --  Original amount of ticks in game cycle
      Remain_Ticks         : A0B.Types.Unsigned_32 := 32;
      --  Actual amount of ticks to wait, it is original amout plus one.

      Miss_Animation_Side  : Lane_Side             := Left;
      Miss_Animation_Cycle : A0B.Types.Unsigned_32 := 0;
      --  Miss animation when not equal to zero.

      Rabbit_Visible       : Boolean               := False;
      Rabbit_Remain_Cycles : A0B.Types.Unsigned_32 := 15;

      Current_Lane         : Lane                  := Left_Top;
      Current_Score        : Score                 := 0;
      Miss_Count           : Natural               := 0;
      Miss_Half            : Boolean               := False;
      Random_Seed          : A0B.Types.Unsigned_32 := 0;
      Idle_Lane_Count      : A0B.Types.Unsigned_32 := 0;
      Eggs_Count_Limit     : A0B.Types.Unsigned_32 := 1;
      Active_Eggs_Count    : A0B.Types.Unsigned_32 := 0;
      Dangerous_Lane       : Optional_Lane         := None;
   end record;

   type Game_Records is record
      A : Score := 0;
      B : Score := 0;
   end record;

   State   : Game_State;
   Records : Game_Records;

   Wolf              : Wolf_Position := (Side => Left, Height => Top);
   Lanes             : Game_Lanes    :=
     [others => [others => [others => False]]];

   function Ones (Value : Score) return Score_Digit is (Value mod 10);

   function Tens (Value : Score) return Score_Digit is ((Value / 10) mod 10);

   function Hundreds (Value : Score) return Score_Digit is
     ((Value / 100) mod 10);

end Nu_Pogodi.Generic_Scene;
