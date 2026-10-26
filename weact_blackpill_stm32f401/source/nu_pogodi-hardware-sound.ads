--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Callbacks;
with A0B.Types;

package Nu_Pogodi.Hardware.Sound is

   Sample_Rate       : constant := 4_000;
   Samples_Per_Frame : constant := Sample_Rate / 8;

   type Sample is record
      ARR  : A0B.Types.Unsigned_16;
      RCR  : A0B.Types.Unsigned_16 := 0;
      CCR1 : A0B.Types.Unsigned_16;
      CCR2 : A0B.Types.Unsigned_16 := 0;
   end record with Object_Size => 64;
   --  Raw PWM register values for a 1 MHz TIM1 counter.

   for Sample use record
      ARR  at 0 range 0 .. 15;
      RCR  at 2 range 0 .. 15;
      CCR1 at 4 range 0 .. 15;
      CCR2 at 6 range 0 .. 15;
   end record;

   type Sample_Array is array (Natural range <>) of Sample;

   procedure Initialize;

   procedure Start
     (Data     : aliased Sample_Array;
      Finished : A0B.Callbacks.Callback;
      Success  : out Boolean);

end Nu_Pogodi.Hardware.Sound;
