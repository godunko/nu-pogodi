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

   type Internal_Egg_Step is range 0 .. 5;
   subtype Egg_Step is Internal_Egg_Step range 1 .. 5;

   type Egg_Array is array (Internal_Egg_Step) of Boolean;

   type Game_Lanes is array (Lane_Side, Lane_Height) of Egg_Array;

   --  type Miss_Score is delta 0.5 range 0.0 .. 3.0;
   --  --  Miss score: `0.5` delta allow to represent Rabbit reduction rule

   procedure Initialize (Mode : Game_Mode);

   procedure Update_Physics_Tick (Refresh : out Boolean);

   procedure Spawn_Egg (Side : Lane_Side; Height : Lane_Height);

private

   type Game_State is record
      Current_Tick : A0B.Types.Unsigned_32 := 0;
      Remain_Ticks : A0B.Types.Unsigned_32 := 31;
   end record;

   State : Game_State;

   Mode              : Game_Mode     := Mode_A;
   Score             : Natural       := 0;
   Wolf              : Wolf_Position := (Side => Left, Height => Top);
   Lanes             : Game_Lanes    :=
     [others => [others => [others => False]]];
   Active_Eggs_Count : Natural := 0;

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
