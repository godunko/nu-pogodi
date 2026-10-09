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
     (Buffer   : aliased A0B.Buffers.Abstract_Buffer'Class;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Initiate partial panel refresh. Partial update mode and RAM ping-pong
   --  must be enabled, with RED RAM containing the current panel image.
   --  Only BW RAM is uploaded; the controller switches RAM banks after
   --  refresh. `Callback` is emitted when update sequence is completed,
   --  and next update can be requested immediately.

end Nu_Pogodi.Display;
