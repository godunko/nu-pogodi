--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Callbacks;
with A0B.Buffers;
with A0B.Types.Arrays;

package Nu_Pogodi.Hardware.SPI is

   procedure Initialize;

   procedure Acquire_MIPI_Read;

   procedure Acquire_MIPI_Write;

   procedure Release;

   procedure Transmit (Command : A0B.Types.Unsigned_8);

   procedure Transmit
     (Buffer   : A0B.Buffers.Abstract_Buffer'Class;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);

   procedure Receive (Data : out A0B.Types.Unsigned_8);

   procedure Receive
     (Data              : out A0B.Types.Arrays.Unsigned_8_Array;
      Ignore_First_Byte : Boolean := False);
   --  Read consecutive bytes, keeping CS asserted until the last byte.

   procedure Receive
     (Buffer            : in out A0B.Buffers.Abstract_Buffer'Class;
      Ignore_First_Byte : Boolean := False);
   --  Read Expected_Length bytes and update the buffer's actual length.
   --  When requested, discard one leading byte without storing it.

end Nu_Pogodi.Hardware.SPI;
