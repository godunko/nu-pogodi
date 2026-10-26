--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Nu_Pogodi.Hardware.Sound;

package Nu_Pogodi.Sounds.Samples is

   type Builder_Subprogram is access procedure
     (Buffer : out Nu_Pogodi.Hardware.Sound.Sample_Array;
      Last   : out Natural);
   --  Last is the index of the last sample written to Buffer.

   procedure Generate_Catch_Sound
     (Buffer : out Nu_Pogodi.Hardware.Sound.Sample_Array;
      Last   : out Natural);

   procedure Generate_Left_Bottom_Sound
     (Buffer : out Nu_Pogodi.Hardware.Sound.Sample_Array;
      Last   : out Natural);

   procedure Generate_Left_Top_Sound
     (Buffer : out Nu_Pogodi.Hardware.Sound.Sample_Array;
      Last   : out Natural);

   procedure Generate_Right_Bottom_Sound
     (Buffer : out Nu_Pogodi.Hardware.Sound.Sample_Array;
      Last   : out Natural);

   procedure Generate_Right_Top_Sound
     (Buffer : out Nu_Pogodi.Hardware.Sound.Sample_Array;
      Last   : out Natural);

   Builders : constant
     array (Nu_Pogodi.Sounds.Sound_Identifier) of Builder_Subprogram :=
       [None              => null,
        Move_Left_Top     => Generate_Left_Top_Sound'Access,
        Move_Left_Bottom  => Generate_Left_Bottom_Sound'Access,
        Move_Right_Top    => Generate_Right_Top_Sound'Access,
        Move_Right_Bottom => Generate_Right_Bottom_Sound'Access,
        Egg_Caught        => Generate_Catch_Sound'Access];

end Nu_Pogodi.Sounds.Samples;
