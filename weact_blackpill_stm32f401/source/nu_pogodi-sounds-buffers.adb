--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Storage;
with A0B.Types;

package body Nu_Pogodi.Sounds.Buffers is

   type Sample is record
      ARR  : A0B.Types.Unsigned_16;
      RCR  : A0B.Types.Unsigned_16 := 0;
      CCR1 : A0B.Types.Unsigned_16;
      CCR2 : A0B.Types.Unsigned_16 := 0;
   end record with Size => 64, Alignment => 2;

   for Sample use record
      ARR  at 0 range 0 .. 15;
      RCR  at 2 range 0 .. 15;
      CCR1 at 4 range 0 .. 15;
      CCR2 at 6 range 0 .. 15;
   end record;

   type Sample_Array is array (Natural range <>) of Sample;

   Data : aliased Sample_Array (0 .. 1_399) with Alignment => 4;

   type Buffer_Index is mod 2;

   type Encoder_State is record
      Count     : Natural := 0;
      Finalized : Boolean := False;
      Failed    : Boolean := False;
   end record;

   function Capacity return Natural;
   --  Returns current capacity of the buffer: full length in `Single` mode
   --  and half of the length in `Double` mode.

   function Offset return Natural;
   --  Offset of the current mode in data buffer.

   State   : Encoder_State;
   Current : Buffer_Index := 0;
   Mode    : Buffer_Mode := Single;

   --------------
   -- Capacity --
   --------------

   function Capacity return Natural is
     (if Mode = Single then Data'Length else Data'Length / 2);

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
      Success   : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      if State.Finalized or else State.Failed
        or else Period > 65_536 or else High > Period or else High > 65_535
        or else Intervals > Capacity - State.Count
      then
         State.Failed := True;
         Success      := False;

         return;
      end if;

      Data (Offset + State.Count .. Offset + State.Count + Intervals - 1) :=
        [others => (ARR => A0B.Types.Unsigned_16 (Period - 1),
                    CCR1 => A0B.Types.Unsigned_16 (High), others => <>)];
      State.Count := @ + Intervals;
   end Encode;

   ------------
   -- Finish --
   ------------

   procedure Finish (Success : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      if State.Failed or State.Count = 0 then
         Success := False;

         return;
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
         Data (Offset)'Address,
         A0B.Storage.Storage_Count (State.Count * 8));
   end Get;

   ------------
   -- Offset --
   ------------

   function Offset return Natural is (Natural (Current) * Capacity);

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
         Current := @ + 1;
      end if;
   end Switch;

end Nu_Pogodi.Sounds.Buffers;
