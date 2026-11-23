--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Storage;
with A0B.Types;

with ESPIDF.Driver.RMT;

package body Nu_Pogodi.Sounds.Buffers is

   type Buffer_Index is mod 2;

   type Encoder_State is record
      Count     : Natural := 0;
      Phase     : Natural := 0;
      Pending   : Boolean := False;
      Ticks     : A0B.Types.Unsigned_15 := 0;
      Level     : A0B.Types.Unsigned_1 := 0;
      Finalized : Boolean := False;
      Failed    : Boolean := False;
   end record;

   function Capacity return Natural;
   --  Returns current capacity of the buffer: full length in `Single` mode
   --  and half of the length in `Double` mode.

   function Offset return A0B.Types.Unsigned_32;
   --  Offset of the current mode in data buffer.

   Symbols : aliased ESPIDF.Driver.RMT.rmt_symbol_word_t_Array (0 .. 1_024)
     with Alignment => 4;
   State   : Encoder_State;
   Current : Buffer_Index := 0;
   Mode    : Buffer_Mode := Single;

   --------------
   -- Capacity --
   --------------

   function Capacity return Natural
   is (if Mode = Single then Symbols'Length else Symbols'Length / 2);

   -----------
   -- Clear --
   -----------

   procedure Clear is
   begin
      State := (others => <>);
   end Clear;

   ------------
   -- Encode --
   ------------

   procedure Encode
     (Period    : Positive;
      High      : Natural;
      Intervals : Positive := 1;
      Success   : in out Boolean)
   is
      procedure Append (Duration : Positive; Level : A0B.Types.Unsigned_1);

      Remaining : Natural;
      Run       : Positive;
      Is_High   : Boolean;

      ------------
      -- Append --
      ------------

      procedure Append (Duration : Positive; Level : A0B.Types.Unsigned_1) is
         use type A0B.Types.Unsigned_32;

      begin
         if not State.Pending then
            State.Ticks := A0B.Types.Unsigned_15 (Duration * 2);
            State.Level := Level;
            State.Pending := True;

         elsif State.Count = Capacity then
            State.Failed := True;
            Success := False;

         else
            Symbols (Offset + A0B.Types.Unsigned_32 (State.Count)) :=
              (duration0 => State.Ticks,
               level0    => State.Level,
               duration1 => A0B.Types.Unsigned_15 (Duration * 2),
               level1    => Level);
            State.Count := @ + 1;
            State.Pending := False;
         end if;
      end Append;

   begin
      if not Success then
         return;
      end if;

      if State.Finalized or State.Failed or High > Period then
         State.Failed := True;
         Success := False;

         return;
      end if;

      for Interval in 1 .. Intervals loop
         Remaining := 250;
         State.Phase := State.Phase mod Period;

         while Remaining /= 0 loop
            Is_High := State.Phase < High;

            if High = 0 or High = Period then
               Run := Remaining;

            elsif Is_High then
               Run := Natural'Min (Remaining, High - State.Phase);

            else
               Run := Natural'Min (Remaining, Period - State.Phase);
            end if;

            Append (Run, (if Is_High then 1 else 0));

            if not Success then
               return;
            end if;

            --  Avoid overflow even for periods near Positive'Last.

            if Run >= Period - State.Phase then
               State.Phase := (Run - (Period - State.Phase)) mod Period;

            else
               State.Phase := @ + Run;
            end if;

            Remaining := @ - Run;
         end loop;
      end loop;
   end Encode;

   ------------
   -- Finish --
   ------------

   procedure Finish (Success : in out Boolean) is
      use type A0B.Types.Unsigned_15;
      use type A0B.Types.Unsigned_32;

   begin
      if not Success then
         return;
      end if;

      if State.Failed or (State.Count = 0 and not State.Pending) then
         Success := False;

         return;
      end if;

      if State.Finalized then
         return;
      end if;

      if State.Pending then
         if State.Count = Capacity then
            State.Failed := True;
            Success := False;

            return;
         end if;

         --  Durations are even at 2 MHz; both halves remain nonzero.

         Symbols (Offset + A0B.Types.Unsigned_32 (State.Count)) :=
           (duration0 => State.Ticks / 2,
            level0    => State.Level,
            duration1 => State.Ticks / 2,
            level1    => State.Level);
         State.Count := @ + 1;
         State.Pending := False;
      end if;

      State.Finalized := True;
   end Finish;

   ---------
   -- Get --
   ---------

   procedure Get
     (Descriptor : out A0B.Asynchronous_Transfers.Transfer_Descriptor;
      Success    : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      if not State.Finalized or State.Failed then
         Success := False;

         return;
      end if;

      A0B.Asynchronous_Transfers.Initialize
        (Descriptor,
         Symbols (Offset)'Address,
         A0B.Storage.Storage_Count (State.Count * 4));
   end Get;

   ------------
   -- Offset --
   ------------

   function Offset return A0B.Types.Unsigned_32
   is (A0B.Types.Unsigned_32 (Natural (Current) * Capacity));

   --------------
   -- Set_Mode --
   --------------

   procedure Set_Mode (To : Buffer_Mode) is
   begin
      Mode    := To;
      Current := 0;
      State   := (others => <>);
   end Set_Mode;

   ------------
   -- Switch --
   ------------

   procedure Switch is
   begin
      if Mode = Double then
         Current := @ - 1;
      end if;
   end Switch;

end Nu_Pogodi.Sounds.Buffers;
