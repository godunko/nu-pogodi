--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

private with A0B.Types;

package Nu_Pogodi.Scene is

   type Game_Mode is (Mode_A, Mode_B);

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

   procedure Initialize (Mode : Game_Mode);

   procedure Update_Physics_Tick (Refresh : out Boolean);

private

   type Score is mod 1_000;

   subtype Score_Digit is Score range 0 .. 9;

   type Game_State is record
      Mode                 : Game_Mode             := Mode_A;

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

   --  Algorithmic Entry Points
   --  procedure Move_Wolf (State : in out Game_State; Side : Lane_Side; Height : Lane_Height);

end Nu_Pogodi.Scene;
