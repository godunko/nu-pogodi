--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

package Nu_Pogodi.States.Game is

   type Game_State is new Abstract_State with private;

private

   type Game_State is new Abstract_State with null record;

   overriding procedure Render
     (Self        : in out Game_State;
      Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer);

   overriding procedure Physics_Tick
     (Self    : in out Game_State;
      Refresh : in out Boolean);

   overriding procedure Keyboard
     (Self  : in out Game_State;
      State : Nu_Pogodi.Keyboard.Keyboard_State);

end Nu_Pogodi.States.Game;
