--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Nu_Pogodi.Scene;

package Nu_Pogodi.Application is

   procedure Run;

   procedure Request_Clock_State;

   procedure Request_Game_State (Mode : Nu_Pogodi.Scene.Game_Mode);

end Nu_Pogodi.Application;
