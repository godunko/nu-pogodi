--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

package body Nu_Pogodi.Hardware is

   ------------------
   -- Reverse_Bits --
   ------------------

   function Reverse_Bits
     (Value : A0B.Types.Unsigned_8) return A0B.Types.Unsigned_8
   is
      use type A0B.Types.Unsigned_8;

      Result : A0B.Types.Unsigned_8 := Value;

   begin
      Result := A0B.Types.Shift_Left (Result and 16#55#, 1)
        or A0B.Types.Shift_Right (Result and 16#AA#, 1);
      Result := A0B.Types.Shift_Left (Result and 16#33#, 2)
        or A0B.Types.Shift_Right (Result and 16#CC#, 2);

      return A0B.Types.Shift_Left (Result, 4)
        or A0B.Types.Shift_Right (Result, 4);
   end Reverse_Bits;

end Nu_Pogodi.Hardware;
