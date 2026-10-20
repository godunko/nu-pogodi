--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

--  Commands and buffer bytes are transmitted as-is without any bit order
--  conversion. It is the caller's responsibility to ensure that commands,
--  parameters and buffer bytes are encoded correctly for the intended bit
--  order. Likewise, it is the caller's responsibility to configure underlying
--  hardware and drivers for the intended bit order to be used on wire(s).

with A0B.Asynchronous_Operations;
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
     (Command    : Command_Code;
      Descriptor : aliased in out
        A0B.Asynchronous_Operations.Transfer_Descriptor;
      Finished   : A0B.Callbacks.Callback;
      Success    : in out Boolean);

   procedure Command_Read
     (Command           : Command_Code;
      Buffer            : aliased in out A0B.Buffers.Abstract_Buffer'Class;
      Finished          : A0B.Callbacks.Callback;
      Success           : in out Boolean;
      Ignore_First_Byte : Boolean := False);

end Nu_Pogodi.Hardware.MIPI;
