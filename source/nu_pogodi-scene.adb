--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

package body Nu_Pogodi.Scene is

   ------------------
   -- Is_Game_Over --
   ------------------

   function Is_Game_Over return Boolean is
   begin
      return State.Miss_Count > 3;
   end Is_Game_Over;

end Nu_Pogodi.Scene;
