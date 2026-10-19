--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.ARMv7M.SCS.SysTick;

function Nu_Pogodi.Hardware.Timer return A0B.Types.Unsigned_4 is
   use type A0B.Types.Unsigned_32;

begin
   return
     A0B.Types.Unsigned_4
       (A0B.ARMv7M.SCS.SysTick.SYST_CVR.CURRENT
          mod A0B.Types.Unsigned_4'Modulus);
end Nu_Pogodi.Hardware.Timer;
