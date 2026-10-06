--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Time.Clock;

package body Nu_Pogodi.Scene is

   procedure Advance_Lane
     (Side   : Lane_Side;
      Height : Lane_Height);
   --  Internal Lane Physics Tracker and Scoring Logic

   procedure Next (Item : in out Lane);

   function Generate return Natural;

   --  --------------------------------------------------------------------------
   --  -- Private Helper: Pure, deterministic LCG for embedded random logic
   --  --------------------------------------------------------------------------
   --  function Pseudo_Random (Seed : Natural) return Natural is
   --  begin
   --     -- Standard numeric constants for linear congruential generation
   --     return (Seed * 1103515245 + 12345) mod 2147483648;
   --  end Pseudo_Random;
   --
   --  --------------------------------------------------------------------------
   --  -- Sets initial state defaults per game mode
   --  --------------------------------------------------------------------------
   --  procedure Initialize_Game (State : out Game_State; Mode : Game_Mode_Type) is
   --  begin
   --     State := (
   --        Mode                  => Mode,
   --        Score                 => 0,
   --        Misses                => 0.0,
   --        Wolf                  => (Side => Left, Height => Top),
   --        Lanes                 => (others => (others => False)),
   --        Game_Over             => False,
   --        Rabbit_Visible        => False,
   --        Base_Speed_Ms         => (if Mode = Mode_A then 1000 else 800), -- Mode B starts faster
   --        Current_Tick_Interval => (if Mode = Mode_A then 1000 else 800),
   --        Total_Ticks           => 0,
   --        Active_Eggs_Count     => 0
   --     );
   --  end Initialize_Game;
   --
   --  --------------------------------------------------------------------------
   --  -- Private Helper: Recomputes systemic tick speeds based on score scaling
   --  --------------------------------------------------------------------------
   --  procedure Recalculate_Game_Speed (State : in out Game_State) is
   --     Speed_Reduction : Natural := 0;
   --  begin
   --     -- Drop 100ms every 100 points
   --     Speed_Reduction := (State.Score / 100) * 100;
   --
   --     if State.Base_Speed_Ms > Speed_Reduction + 150 then
   --        State.Current_Tick_Interval := State.Base_Speed_Ms - Speed_Reduction;
   --     else
   --        State.Current_Tick_Interval := 150; -- absolute hardware cap speed
   --     end if;
   --  end Recalculate_Game_Speed;
   --
   --  --------------------------------------------------------------------------
   --  -- Private Helper: Injects an egg into a target lane safely
   --  --------------------------------------------------------------------------
   --  procedure Spawn_Egg_In_Lane (State : in out Game_State; Lane_Idx : Natural) is
   --  begin
   --     case Lane_Idx mod 4 is
   --        when 0 =>
   --           if not State.Lanes.Top_Left(0) then
   --              State.Lanes.Top_Left(0) := True; State.Active_Eggs_Count := State.Active_Eggs_Count + 1;
   --           end if;
   --        when 1 =>
   --           if not State.Lanes.Top_Right(0) then
   --              State.Lanes.Top_Right(0) := True; State.Active_Eggs_Count := State.Active_Eggs_Count + 1;
   --           end if;
   --        when 2 =>
   --           if not State.Lanes.Bottom_Left(0) then
   --              State.Lanes.Bottom_Left(0) := True; State.Active_Eggs_Count := State.Active_Eggs_Count + 1;
   --           end if;
   --        when others =>
   --           if not State.Lanes.Bottom_Right(0) then
   --              State.Lanes.Bottom_Right(0) := True; State.Active_Eggs_Count := State.Active_Eggs_Count + 1;
   --           end if;
   --     end case;
   --  end Spawn_Egg_In_Lane;

   --------------
   -- Generate --
   --------------

   function Generate return Natural is
      use type A0B.Types.Unsigned_64;

      Seed : constant A0B.Types.Unsigned_64 :=
        A0B.Time.To_Nanoseconds (A0B.Time.Clock) / 3_000;

   begin
      --  Standard numeric constants for linear congruential generation

      return Natural ((Seed * 1103515245 + 12345) mod 2147483648);
   end Generate;

   --  --------------------------------------------------------------------------
   --  -- Private Helper: Evaluates autonomic egg spawning thresholds
   --  --------------------------------------------------------------------------
   procedure Handle_Autonomic_Generation is
      Random_Value      : Natural;
      Max_Eggs          : Natural;
      Spawn_Probability : Natural; -- Out of 100

   begin
      --  Establish operational constraints based on game rulesets

      if Mode = Mode_A then
         Max_Eggs          :=
           (if Score < 100
            then 2
            else (if Score < 500 then 3 else 4));
         Spawn_Probability := (if Score < 200 then 30 else 45);

      else
         --  Mode B enforces heavier pressure immediately

         Max_Eggs          := (if Score < 200 then 3 else 4);
         Spawn_Probability := (if Score < 200 then 50 else 65);
      end if;

      if Active_Eggs_Count < Max_Eggs then
         Random_Value := Generate;
         --  Random_Value := Pseudo_Random (Total_Ticks + Score);

         if (Random_Value mod 100) < Spawn_Probability then
            --  Choose lane based on next random iteration

            declare
               Lane_Choice : constant Natural := Generate;
   --              Lane_Choice : Natural := Pseudo_Random(Rand_Val);
             --  Simpson : Integer;
            begin
               case Lane_Choice mod 4 is
                  when 0      => Spawn_Egg (Left, Top);
                  when 1      => Spawn_Egg (Right, Top);
                  when 2      => Spawn_Egg (Left, Bottom);
                  when 3      => Spawn_Egg (Right, Bottom);
                  when others => raise Program_Error;
               end case;

   --              Spawn_Egg_In_Lane(State, Lane_Choice);
   --
   --              -- Mode B rules: Chance to immediately trigger a concurrent double spawn
   --              if State.Mode = Mode_B and then State.Active_Eggs_Count < Max_Eggs then
   --                 if (Pseudo_Random(Lane_Choice) mod 100) < 30 then
   --                    Spawn_Egg_In_Lane(State, Lane_Choice + 1);
   --                 end if;
   --              end if;
            end;
         end if;
      end if;
   end Handle_Autonomic_Generation;

   --  --------------------------------------------------------------------------
   --  -- Updates Wolf Placement
   --  --------------------------------------------------------------------------
   --  procedure Move_Wolf (State : in out Game_State; Side : Lane_Side; Height : Lane_Height) is
   --  begin
   --     if not State.Game_Over then
   --        State.Wolf := (Side => Side, Height => Height);
   --     end if;
   --  end Move_Wolf;
   --
   --  --------------------------------------------------------------------------
   --  -- Toggles Rabbit Windows
   --  --------------------------------------------------------------------------
   --  procedure Set_Rabbit_State (State : in out Game_State; Visible : Boolean) is
   --  begin
   --     if not State.Game_Over then
   --        State.Rabbit_Visible := Visible;
   --     end if;
   --  end Set_Rabbit_State;

   ------------------
   -- Advance_Lane --
   ------------------

   procedure Advance_Lane
     (Side   : Lane_Side;
      Height : Lane_Height)
   --     State        : in out Game_State;
   --     Lane         : in out Egg_Array;
   --     Lane_S       : Lane_Side;
   --     Lane_H       : Lane_Height
     --  ) is
   is
      Lane : Egg_Array renames Lanes (Side, Height);

   --     Penalty_Increment : Float := 1.0;
   begin
      if Lane (Lane'Last) then
   --        if State.Wolf.Side = Lane_S and State.Wolf.Height = Lane_H then
   --           -- Successful Capture
            Score := Score + 1;
   --           if State.Score > 999 then
   --              State.Score := 0;
   --           end if;
   --
   --           Recalculate_Game_Speed(State);
   --
   --           if State.Score = 200 or State.Score = 500 then
   --              State.Misses := 0.0;
   --           end if;
   --        else
   --           -- Drop Registered
   --           if State.Rabbit_Visible then
   --              Penalty_Increment := 0.5;
   --           end if;
   --
   --           State.Misses := State.Misses + Penalty_Increment;
   --           if State.Misses >= 3.0 then
   --              State.Game_Over := True;
   --           end if;
   --        end if;
   --
   --        Lane(Egg_Max_Step) := False;
         Active_Eggs_Count := @ - 1;
      end if;

      --  Move eggs down in lane

      for Step in reverse Egg_Step loop
         Lane (Step) := Lane (Step - 1);
      end loop;

      Lane (Lane'First) := False;
   end Advance_Lane;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Mode : Game_Mode) is
   begin
      State :=
        (Current_Tick => 0,
         Remain_Ticks => 31,
         Current_Lane => Left_Top);

      Scene.Mode        := Mode;
      Score             := 0;
      Wolf              := (Side => Left, Height => Top);
      Lanes             := [others => [others => [others => False]]];
      Active_Eggs_Count := 0;

      Spawn_Egg (Left, Top);
      Spawn_Egg (Right, Top);
      Spawn_Egg (Left, Bottom);
      Spawn_Egg (Right, Bottom);
   end Initialize;

   ----------
   -- Next --
   ----------

   procedure Next (Item : in out Lane) is
   begin
      Item :=
        (case Item is
            when Left_Top     => Right_Top,
            when Right_Top    => Left_Bottom,
            when Left_Bottom  => Right_Bottom,
            when Right_Bottom => Left_Top);
   end Next;

   ---------------
   -- Spawn_Egg --
   ---------------

   procedure Spawn_Egg (Side : Lane_Side; Height : Lane_Height) is
   begin
      Lanes (Side, Height) (Egg_Array'First) := True;
      Active_Eggs_Count                      := @ + 1;
   end Spawn_Egg;

   -------------------------
   -- Update_Physics_Tick --
   -------------------------

   procedure Update_Physics_Tick (Refresh : out Boolean) is
      use type A0B.Types.Unsigned_32;

   begin
      State.Current_Tick := @ + 1;
      State.Remain_Ticks := @ - 1;

      if State.Remain_Ticks /= 0 then
         Refresh := False;

         return;
      end if;

      case Wolf.Side is
         when Left =>
            case Wolf.Height is
               when Top =>
                  Wolf := (Left, Bottom);

               when Bottom =>
                  Wolf := (Right, Top);
            end case;

         when Right =>
            case Wolf.Height is
               when Top =>
                  Wolf := (Right, Bottom);

               when Bottom =>
                  Wolf := (Left, Top);
            end case;
      end case;

   --     if State.Game_Over then
   --        return;
   --     end if;

      --  Advance active items down their tracks

      case State.Current_Lane is
         when Left_Top =>
            Advance_Lane (Left, Top);

         when Right_Top =>
            Advance_Lane (Right, Top);

         when Left_Bottom =>
            Advance_Lane (Left, Bottom);

         when Right_Bottom =>
            Advance_Lane (Right, Bottom);
      end case;

      Next (State.Current_Lane);

   --     -- 2. Increment global cycle timeline
   --     State.Total_Ticks := State.Total_Ticks + 1;

      --  Run embedded autonomic generations

      --  Handle_Autonomic_Generation;

      State.Remain_Ticks := 31;
      Refresh := True;
   end Update_Physics_Tick;

end Nu_Pogodi.Scene;
