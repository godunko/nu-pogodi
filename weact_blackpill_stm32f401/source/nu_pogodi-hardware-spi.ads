--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Asynchronous_Operations;
with A0B.Callbacks;

package Nu_Pogodi.Hardware.SPI is

   procedure Initialize;

   procedure Acquire_MIPI_Read;

   procedure Acquire_MIPI_Write;

   procedure Release;

   --  procedure Transmit
   --    (Descriptors : aliased in out
   --       A0B.Asynchronous_Operations.Transfer_Descriptor_Array;
   --     Finished    : A0B.Callbacks.Callback;
   --     Success     : in out Boolean);

   procedure Transmit
     (Descriptor : aliased in out
        A0B.Asynchronous_Operations.Transfer_Descriptor;
      Finished   : A0B.Callbacks.Callback;
      Success    : in out Boolean);

   procedure Receive
     (Descriptor : aliased in out
        A0B.Asynchronous_Operations.Transfer_Descriptor;
      Callback   : A0B.Callbacks.Callback;
      Success    : in out Boolean);

end Nu_Pogodi.Hardware.SPI;
