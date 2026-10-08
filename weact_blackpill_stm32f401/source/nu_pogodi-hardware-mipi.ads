--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

--  Commands and buffer bytes are transmitted LSB first without conversion.
--  The caller supplies commands and parameters encoded for this bit order.

with A0B.Buffers;
with A0B.Callbacks;
with A0B.Types.Enumerable;

package Nu_Pogodi.Hardware.MIPI is

   type Command_Code is new A0B.Types.Enumerable.Enumerable_8;

   procedure Initialize;

   procedure Command
     (Command  : Command_Code;
      Finished : A0B.Callbacks.Callback;
      Success  : in out Boolean);

   procedure Command_Write
     (Command  : Command_Code;
      Buffer   : A0B.Buffers.Abstract_Buffer'Class;
      Finished : A0B.Callbacks.Callback;
      Success  : in out Boolean);

end Nu_Pogodi.Hardware.MIPI;
