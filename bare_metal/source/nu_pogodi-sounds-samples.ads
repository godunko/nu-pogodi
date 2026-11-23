--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

package Nu_Pogodi.Sounds.Samples is

   Samples_Per_Game_Over : constant :=
     4_000 * 350 / 1_000;

   type Builder_Subprogram is access procedure
     (Success : in out Boolean);

   procedure Generate_Catch_Sound
     (Success : in out Boolean);

   procedure Generate_Chick_Jump_Sound
     (Success : in out Boolean);

   procedure Generate_Fall_Sound
     (Success : in out Boolean);

   procedure Generate_Game_Over_Sound
     (Success : in out Boolean);

   procedure Generate_Left_Bottom_Sound
     (Success : in out Boolean);

   procedure Generate_Left_Top_Sound
     (Success : in out Boolean);

   procedure Generate_Right_Bottom_Sound
     (Success : in out Boolean);

   procedure Generate_Right_Top_Sound
     (Success : in out Boolean);

   Builders : constant
     array (Nu_Pogodi.Sounds.Sound_Identifier) of Builder_Subprogram :=
       [None              => null,
        Move_Left_Top     => Generate_Left_Top_Sound'Access,
        Move_Left_Bottom  => Generate_Left_Bottom_Sound'Access,
        Move_Right_Top    => Generate_Right_Top_Sound'Access,
        Move_Right_Bottom => Generate_Right_Bottom_Sound'Access,
        Egg_Caught        => Generate_Catch_Sound'Access,
        Egg_Broken        => Generate_Fall_Sound'Access,
        Chick_Jump        => Generate_Chick_Jump_Sound'Access,
        Game_Over         => Generate_Game_Over_Sound'Access];

end Nu_Pogodi.Sounds.Samples;
