--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

private with A0B.Types;

package Nu_Pogodi.Hardware is

private

   function Reverse_Bits
     (Value : A0B.Types.Unsigned_8) return A0B.Types.Unsigned_8;
   --  Reverse the order of the eight bits in Value.

end Nu_Pogodi.Hardware;
