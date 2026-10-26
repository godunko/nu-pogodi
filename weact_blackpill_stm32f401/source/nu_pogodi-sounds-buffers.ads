--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Nu_Pogodi.Hardware.Sound;
with Nu_Pogodi.Sounds.Samples;

package Nu_Pogodi.Sounds.Buffers is

   type Buffer_Index is range 0 .. 1;

   Buffer_0 : aliased Nu_Pogodi.Hardware.Sound.Sample_Array :=
     [0 .. Nu_Pogodi.Sounds.Samples.Samples_Per_Game_Over - 1 =>
        (ARR => 249, CCR1 => 0, others => <>)] with Alignment => 4;
   Buffer_1 : aliased Nu_Pogodi.Hardware.Sound.Sample_Array :=
     [0 .. Nu_Pogodi.Hardware.Sound.Samples_Per_Frame - 1 =>
        (ARR => 249, CCR1 => 0, others => <>)] with Alignment => 4;

   type Sound_Buffer_Access is
     access all Nu_Pogodi.Hardware.Sound.Sample_Array;

   Buffers : constant array (Buffer_Index) of Sound_Buffer_Access :=
     [Buffer_0 (0 .. Nu_Pogodi.Hardware.Sound.Samples_Per_Frame - 1)
        'Unrestricted_Access,
      Buffer_1'Access];
   --  Splash uses one 125 ms frame from each buffer.

end Nu_Pogodi.Sounds.Buffers;
