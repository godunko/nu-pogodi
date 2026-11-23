--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Asynchronous_Transfers;

package Nu_Pogodi.Sounds.Buffers is

   type Buffer_Mode is (Single, Double);

   procedure Set_Mode (To : Buffer_Mode);

   procedure Switch;
   --  Switch to the next buffer in `Double` mode, do nothing in `Single` mode.

   procedure Clear;
   --  Reset state of the encoder, including PWM phase, clear the current
   --  buffer. Set_Mode selects the first buffer and clears encoder state.
   --  Switch selects the other buffer without clearing it.

   procedure Encode
     (Period    : Positive;
      High      : Natural;
      Intervals : Positive := 1;
      Success   : in out Boolean);
   --  Encodes a waveform with the given period, high time, and number of
   --  intervals. Period and high time are specified in microseconds, one
   --  interval corresponds to 250 microseconds.

   procedure Finish (Success : in out Boolean);
   --  Finish encoding the waveform.

   procedure Get
     (Descriptor : out A0B.Asynchronous_Transfers.Transfer_Descriptor;
      Success    : in out Boolean);
   --  Setup the transfer descriptor for the encoded waveform.

end Nu_Pogodi.Sounds.Buffers;
