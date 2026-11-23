--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Asynchronous_Transfers;
with A0B.Callbacks;

package Nu_Pogodi.Hardware.Sound is

   Sample_Rate       : constant := 4_000;
   Samples_Per_Frame : constant := Sample_Rate / 8;

   procedure Initialize;

   procedure Start
     (Descriptor :
        aliased in out A0B.Asynchronous_Transfers.Transfer_Descriptor;
      Finished   : A0B.Callbacks.Callback;
      Success    : in out Boolean);

end Nu_Pogodi.Hardware.Sound;
