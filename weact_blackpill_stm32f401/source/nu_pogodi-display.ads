--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

--  Manages update of display RAM and and refresh panel.
--
--  It is expected that implementation is asynchronous as much as possible.
--  Right now only upload of data to RAM is done synchronously, due to
--  limitation of SPI implementation.

with A0B.Buffers;
with A0B.Callbacks;

package Nu_Pogodi.Display is

   procedure Update
     (New_Buffer : A0B.Buffers.Abstract_Buffer'Class;
      Old_Buffer : A0B.Buffers.Abstract_Buffer'Class;
      Callback   : A0B.Callbacks.Callback;
      Success    : in out Boolean);
   --  Initiate panel refresh procedure. `Callback` is emitted when update
   --  sequence is completed, and next update can be requested immediately.

end Nu_Pogodi.Display;
