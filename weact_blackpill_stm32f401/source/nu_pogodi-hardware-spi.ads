--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

--  One operation may be active at a time. Descriptors and data must remain
--  available and unchanged by the caller until completion. For segmented
--  operations, only the first array element may use polling for 1-4 bytes;
--  subsequent nonempty segments use DMA, for both receive and transmit.

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

   procedure Receive
     (Descriptors : aliased in out
        A0B.Asynchronous_Operations.Transfer_Descriptor_Array;
      Callback    : A0B.Callbacks.Callback;
      Success     : in out Boolean);
   --  The array must remain available and unchanged until completion, and
   --  each descriptor must occur only once. Null entries and lengths above
   --  65_535 reject the whole operation without modifying any descriptor.
   --  Accepted descriptors start as Inactive with Transferred = 0, become
   --  Active when reached, then Success when completed (also for zero length).
   --  Callback is emitted once for the whole array, immediately if empty.

end Nu_Pogodi.Hardware.SPI;
