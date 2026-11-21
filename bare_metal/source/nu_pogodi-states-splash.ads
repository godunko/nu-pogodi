--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

package Nu_Pogodi.States.Splash is

   type Splash_State is new Abstract_State with private;

private

   Physics_Ticks_Per_Second : constant := 40;
   Ticks_Per_Frame          : constant := 5;
   --  8 FPS at 40 Hz.

   type Splash_State is new Abstract_State with record
      Tick    : Natural := 0;
      Started : Boolean := False;
   end record;

   overriding procedure Render
     (Self        : in out Splash_State;
      Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer);

   overriding procedure Physics_Tick
     (Self    : in out Splash_State;
      Refresh : in out Boolean);

   overriding procedure Keyboard
     (Self  : in out Splash_State;
      State : Nu_Pogodi.Keyboard.Keyboard_State);

end Nu_Pogodi.States.Splash;
