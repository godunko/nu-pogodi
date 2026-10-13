--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

package body Nu_Pogodi.Hardware.SSD1683.Utilities is

   --------------------
   -- Select_Partial --
   --------------------

   procedure Select_Partial
     (Ranges      : Waveform_Temperature_Range_Array;
      Modes       : A0B.Types.Unsigned_24;
      Temperature : A0B.Types.Integer_8;
      Index       : out Waveform_Setting_Index;
      Success     : out Boolean)
   is
      use type A0B.Types.Integer_8;
      use type A0B.Types.Unsigned_24;

   begin
      Index   := Waveform_Setting_Index'First;
      Success := False;

      for Slot in Ranges'Range loop
         if (Modes and 2 ** Natural (Slot)) /= 0
           and then Ranges (Slot).Temp_Low < Temperature
           and then Temperature <= Ranges (Slot).Temp_High
         then
            Index   := Slot;
            Success := True;

            exit;
         end if;
      end loop;
   end Select_Partial;

end Nu_Pogodi.Hardware.SSD1683.Utilities;
