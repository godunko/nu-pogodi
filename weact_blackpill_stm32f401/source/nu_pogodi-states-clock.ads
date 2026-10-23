--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

package Nu_Pogodi.States.Clock is

   type Clock_State is new Abstract_State with private;

private

   type Clock_State is new Abstract_State with null record;

   overriding procedure Render
     (Self        : in out Clock_State;
      Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer);

   overriding procedure Physics_Tick
     (Self    : in out Clock_State;
      Refresh : in out Boolean);

   overriding procedure Keyboard
     (Self  : in out Clock_State;
      State : Nu_Pogodi.Keyboard.Keyboard_State);

end Nu_Pogodi.States.Clock;
