--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Nu_Pogodi.Hardware.RTC;

package body Nu_Pogodi.Scene is

   procedure Advance_Lane
     (Side   : Lane_Side;
      Height : Lane_Height);
   --  Internal Lane Physics Tracker and Scoring Logic

   procedure Next (Item : in out Lane);
   --  Select next lane circulary.

   procedure Update_Score;
   --  Increment score, update game speed.

   function Exclude_Current_Lane return Boolean;
   --  Returns `True` when current lane should be excluded from egg generation
   --  procedure.

   package Random_Generator is

      function Generate return Boolean;

      function Generate return A0B.Types.Unsigned_32;

      procedure Update;

   end Random_Generator;

   Miss_Animation_Ticks : constant := 15;

   To_Lane : constant array (Lane_Side, Lane_Height) of Lane :=
     [Left  =>
        [Top    => Left_Top,
         Bottom => Left_Bottom],
      Right =>
        [Top    => Right_Top,
         Bottom => Right_Bottom]];

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
      use type A0B.Types.Unsigned_32;

      Lane : Egg_Array renames Lanes (Side, Height);

   --     Penalty_Increment : Float := 1.0;
   begin
   --     if Lane (Lane'Last) then
   --  --        if State.Wolf.Side = Lane_S and State.Wolf.Height = Lane_H then
   --  --           -- Successful Capture
   --           --  Score := Score + 1;
   --  --           if State.Score > 999 then
   --  --              State.Score := 0;
   --  --           end if;
   --  --
   --  --           Recalculate_Game_Speed(State);
   --  --
   --  --           if State.Score = 200 or State.Score = 500 then
   --  --              State.Misses := 0.0;
   --  --           end if;
   --  --        else
   --  --           -- Drop Registered
   --  --           if State.Rabbit_Visible then
   --  --              Penalty_Increment := 0.5;
   --  --           end if;
   --  --
   --  --           State.Misses := State.Misses + Penalty_Increment;
   --  --           if State.Misses >= 3.0 then
   --  --              State.Game_Over := True;
   --  --           end if;
   --  --        end if;
   --  --
   --  --        Lane(Egg_Max_Step) := False;
   --        State.Active_Eggs_Count := @ - 1;
   --     end if;

      if Lane (Lane'Last) then
         State.Dangerous_Lane := To_Lane (Side, Height);
      end if;

      for Step in reverse Egg_Step'First + 1 .. Egg_Step'Last loop
         Lane (Step) := Lane (Step - 1);
      end loop;

      if not Exclude_Current_Lane
        and then not Lane (Lane'First)
        and then State.Active_Eggs_Count < State.Eggs_Count_Limit
        and then (Random_Generator.Generate or State.Active_Eggs_Count = 0)
      then
         Lane (Lane'First) := True;
         State.Active_Eggs_Count := @ + 1;

      else
         Lane (Lane'First) := False;
      end if;

      if (for some Step in Egg_Step => Lane (Step))
        or State.Dangerous_Lane /= None
      then
         State.Idle_Lane_Count := 0;

      else
         State.Idle_Lane_Count := @ + 1;
      end if;
   end Advance_Lane;

   --------------------------
   -- Exclude_Current_Lane --
   --------------------------

   function Exclude_Current_Lane return Boolean is
   begin
      case State.Mode is
         when Mode_A =>
            return
              (State.Current_Lane = Left_Top and State.Miss_Count = 2)
              or (State.Current_Lane = Right_Top and State.Miss_Count = 3)
              or (State.Current_Lane = Left_Bottom and State.Miss_Count = 0)
              or (State.Current_Lane = Right_Bottom and State.Miss_Count = 1);

         when Mode_B =>
            return False;
      end case;
   end Exclude_Current_Lane;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Mode : Game_Mode) is
      use type A0B.Types.Unsigned_32;

   begin
      State :=
        (Mode                 => Mode,
         Current_Tick         => 0,
         Cycle_Ticks          => <>,
         Remain_Ticks         => <>,
         Current_Score        => 0,
         Miss_Count           => 0,
         Miss_Animation_Side  => <>,
         Miss_Animation_Cycle => 0,
         Current_Lane         => <>,
         Random_Seed          => 0,
         Idle_Lane_Count      => 0,
         Eggs_Count_Limit     => 1,
         Active_Eggs_Count    => 0,
         Dangerous_Lane       => None);

      Wolf              := (Side => Right, Height => Bottom);
      Lanes             := [others => [others => [others => False]]];

      --  Some initial values requires calculations based on the game state

      declare
         Cycle_Ticks  : constant A0B.Types.Unsigned_32 :=
           (case Mode is when Mode_A => 31, when Mode_B => 25);
         Current_Lane : constant Lane :=
           (case Random_Generator.Generate mod 4 is
               when 0      => Left_Top,
               when 1      => Right_Top,
               when 2      => Left_Bottom,
               when 3      => Right_Bottom,
               when others => raise Program_Error);

      begin
         State.Cycle_Ticks := Cycle_Ticks;
         State.Current_Lane := Current_Lane;

         State.Remain_Ticks := State.Cycle_Ticks;
      end;
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

   ----------------------
   -- Random_Generator --
   ----------------------

   package body Random_Generator is

      Number_Value  : A0B.Types.Unsigned_32;
      Boolean_Value : Boolean;

      --------------
      -- Generate --
      --------------

      function Generate return Boolean is
      begin
         Update;

         return Boolean_Value;
      end Generate;

      --------------
      -- Generate --
      --------------

      function Generate return A0B.Types.Unsigned_32 is
      begin
         Update;

         return Number_Value;
      end Generate;

      ------------
      -- Update --
      ------------

      procedure Update is
         use type A0B.Types.Unsigned_32;

         Time : constant Nu_Pogodi.Hardware.RTC.Time :=
           Nu_Pogodi.Hardware.RTC.Clock;

      begin
         Number_Value :=
           (A0B.Types.Unsigned_32 (Time.Seconds_Ones)
            + A0B.Types.Unsigned_32 (Time.Seconds_Tens)
            + A0B.Types.Unsigned_32 (Time.Minutes_Ones)
            + A0B.Types.Unsigned_32 (Time.Minutes_Tens)
            + A0B.Types.Unsigned_32 (Time.Hours_Ones)
            + A0B.Types.Unsigned_32 (Time.Hours_Tens)
            + State.Idle_Lane_Count
            + A0B.Types.Unsigned_32 (Hundreds (Records.A))
            + A0B.Types.Unsigned_32 (Tens (Records.A))
            + A0B.Types.Unsigned_32 (Ones (Records.A))
            + State.Random_Seed) mod 16;

         --  Algorithm for generating a pseudo-random Boolean value generates
         --  at most two consecutive `False` values sequentially. This fact is
         --  used to limit number of iterations in the game loop.

         State.Random_Seed := @ + 6;

         if State.Random_Seed >= 16 then
            State.Random_Seed := @ mod 16;

            Boolean_Value := True;

         else
            Boolean_Value := False;
         end if;
      end Update;

   end Random_Generator;

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

      --  for Side in Lane_Side loop
      --     for Height in Lane_Height loop
      --        if Lanes (Side, Height) (Egg_Step'Last) then
      --           Wolf := (Side, Height);
      --           Random_Generator.Update;
      --        end if;
      --     end loop;
      --  end loop;

      --  case Wolf.Side is
      --     when Left =>
      --        case Wolf.Height is
      --           when Top =>
      --              Wolf := (Left, Bottom);
      --
      --           when Bottom =>
      --              Wolf := (Right, Top);
      --        end case;
      --
      --     when Right =>
      --        case Wolf.Height is
      --           when Top =>
      --              Wolf := (Right, Bottom);
      --
      --           when Bottom =>
      --              Wolf := (Left, Top);
      --        end case;
      --  end case;

   --     if State.Game_Over then
   --        return;
   --     end if;

      if State.Miss_Animation_Cycle = 0 then
         if State.Dangerous_Lane /= None then
            State.Miss_Animation_Side  :=
              (case State.Dangerous_Lane is
                  when None         => raise Program_Error,
                  when Left_Top     => Left,
                  when Right_Top    => Right,
                  when Left_Bottom  => Left,
                  when Right_Bottom => Right);
            State.Miss_Animation_Cycle := 4;

            Lanes := [others => [others => [others => False]]];
            State.Active_Eggs_Count := 0;

            State.Dangerous_Lane := None;
            State.Remain_Ticks := Miss_Animation_Ticks;

         else
            State.Idle_Lane_Count := 0;

            loop
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

               exit when
                 State.Idle_Lane_Count = 0 or State.Idle_Lane_Count >= 3;
            end loop;

            if State.Dangerous_Lane /= None
              and then State.Dangerous_Lane = To_Lane (Wolf.Side, Wolf.Height)
            then
               State.Dangerous_Lane := None;
               State.Active_Eggs_Count := @ - 1;

               Update_Score;
            end if;

            State.Remain_Ticks := State.Cycle_Ticks;
         end if;

      else
         State.Miss_Animation_Cycle := @ - 1;

         if State.Miss_Animation_Cycle = 0 then
            --  XXX Recompute miss count
            --  raise Program_Error;
            null;
         end if;

         State.Remain_Ticks := Miss_Animation_Ticks;
      end if;

      Refresh := True;
   end Update_Physics_Tick;

   ------------------
   -- Update_Score --
   ------------------

   procedure Update_Score is

      use type A0B.Types.Unsigned_32;

      Previous_Score : constant Score := State.Current_Score;

   begin
      State.Current_Score := @ + 1;

      if Hundreds (Previous_Score) /= Hundreds (State.Current_Score) then
         if Hundreds (State.Current_Score) /= 9 then
            State.Cycle_Ticks := @ + 7;
         end if;

      elsif Tens (Previous_Score) /= Tens (State.Current_Score) then
         State.Cycle_Ticks := @ - 1;

         if State.Cycle_Ticks < 9 then  --  7 in original code
            --  XXX Should be configurable !!!

            State.Cycle_Ticks := 9;
         end if;
      end if;

      --  Update eggs limit

      declare
         Assessment : constant Score :=
           Hundreds (State.Current_Score) + Tens (State.Current_Score);

      begin
         State.Eggs_Count_Limit :=
           (if Assessment > 16                  then 12
            elsif Assessment >= 14              then 9
            elsif Assessment >= 11              then 7
            elsif Assessment >= 9               then 5
            elsif Assessment >= 5               then 4
            elsif Assessment >= 1               then 3
            elsif State.Current_Score in 5 .. 9 then 2
            else                                     1);
      end;

      --  Update score records

      case State.Mode is
         when Mode_A =>
            if State.Current_Score > Records.A then
               Records.A := State.Current_Score;
            end if;

         when Mode_B =>
            if State.Current_Score > Records.B then
               Records.B := State.Current_Score;
            end if;
      end case;
   end Update_Score;

end Nu_Pogodi.Scene;
