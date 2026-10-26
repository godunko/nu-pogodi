--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Asynchronous_Transfers;
with A0B.Callbacks;

package Nu_Pogodi.Hardware.TIM is

   procedure Initialize;

   procedure Transmit
     (Descriptor : aliased in out
        A0B.Asynchronous_Transfers.Transfer_Descriptor;
      Finished   : A0B.Callbacks.Callback;
      Success    : in out Boolean);

end Nu_Pogodi.Hardware.TIM;
