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

   type Lane is (Left_Top, Right_Top, Left_Bottom, Right_Bottom);

   --  type Miss_Score is delta 0.5 range 0.0 .. 3.0;
   --  --  Miss score: `0.5` delta allow to represent Rabbit reduction rule

   procedure Initialize (Mode : Game_Mode);

   procedure Update_Physics_Tick (Refresh : out Boolean);

private

   type Score is mod 1_000;

   subtype Score_Digit is Score range 0 .. 9;

   type Game_State is record
      Current_Tick  : A0B.Types.Unsigned_32 := 0;
      Cycle_Ticks   : A0B.Types.Unsigned_32 := 31;
      Remain_Ticks  : A0B.Types.Unsigned_32 := 31;
      Current_Lane  : Lane                  := Left_Top;
      Current_Score : Score                 := 0;
      Random_Seed   : A0B.Types.Unsigned_32 := 0;
   end record;

   State : Game_State;

   Mode              : Game_Mode     := Mode_A;
   Wolf              : Wolf_Position := (Side => Left, Height => Top);
   Lanes             : Game_Lanes    :=
     [others => [others => [others => False]]];
   Active_Eggs_Count : Natural := 0;

   function Ones (Value : Score) return Score_Digit is (Value mod 10);

   function Tens (Value : Score) return Score_Digit is ((Value / 10) mod 10);

   function Hundreds (Value : Score) return Score_Digit is
     ((Value / 100) mod 10);

   --  Misses                : Miss_Score    := 0.0;
   --  Game_Over             : Boolean       := False;
   --
   --  Rabbit_Visible        : Boolean       := False;
   --  Base_Speed_Ms         : Positive      := 1000;
   --  --  Baseline tick speed in milliseconds
   --  Current_Tick_Interval : Positive      := 1000;
   --  --  Dynamically adjusted delay threshold
   --  Total_Ticks           : Natural       := 0;

   --  Algorithmic Entry Points
   --  procedure Move_Wolf (State : in out Game_State; Side : Lane_Side; Height : Lane_Height);
   --  procedure Spawn_Egg (State : in out Game_State; Side : Lane_Side; Height : Lane_Height);
   --  procedure Set_Rabbit_State (State : in out Game_State; Visible : Boolean);

end Nu_Pogodi.Scene;
