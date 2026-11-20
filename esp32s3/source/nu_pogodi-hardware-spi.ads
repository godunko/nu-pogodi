--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

--  One operation may be active at a time. Descriptors and data must remain
--  available and unchanged by the caller until completion. Each descriptor
--  may transfer at most 32_768 bytes on this platform. Nonempty descriptors
--  use queued DMA transactions. Completion callbacks execute asynchronously
--  on the callback dispatcher task after the results and received data have
--  been recorded. The caller must acquire the bus before starting transfers
--  and release it after completion.

with A0B.Asynchronous_Transfers;
with A0B.Callbacks;

package Nu_Pogodi.Hardware.SPI is

   procedure Initialize;

   procedure Acquire_MIPI_Read;

   procedure Acquire_MIPI_Write;

   procedure Release;

   --  procedure Transmit
   --    (Descriptors : aliased in out
   --       A0B.Asynchronous_Transfers.Transfer_Descriptor_Array;
   --     Finished    : A0B.Callbacks.Callback;
   --     Success     : in out Boolean);
   --  --  The array contract is the same as for Receive below.

   procedure Transmit
     (Descriptor : aliased in out
        A0B.Asynchronous_Transfers.Transfer_Descriptor;
      Finished   : A0B.Callbacks.Callback;
      Success    : in out Boolean);

   procedure Receive
     (Descriptor : aliased in out
        A0B.Asynchronous_Transfers.Transfer_Descriptor;
      Callback   : A0B.Callbacks.Callback;
      Success    : in out Boolean);

   procedure Receive
     (Descriptors : aliased in out
        A0B.Asynchronous_Transfers.Transfer_Descriptor_Array;
      Callback    : A0B.Callbacks.Callback;
      Success     : in out Boolean);
   --  The array must remain available and unchanged until completion, and
   --  each descriptor must occur only once. Null entries and lengths above
   --  32_768 reject the whole operation without modifying any descriptor.
   --  Accepted descriptors start as Inactive with Transferred = 0, become
   --  Active when reached, then Success when completed (also for zero length).
   --  On failure, subsequent descriptors remain Inactive. Callback is queued
   --  once for the whole array, also if empty. If Success is False on entry,
   --  nothing is done. Validation or initial queueing failure sets Success to
   --  False and does not emit Callback; later failures are reported in the
   --  descriptors and emit Callback.

end Nu_Pogodi.Hardware.SPI;
