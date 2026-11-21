--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Nu_Pogodi.Application;
with Nu_Pogodi.Bitmaps;
with Nu_Pogodi.Clock;
with Nu_Pogodi.Scene.Screen;
with Nu_Pogodi.Display_Segments;

package body Nu_Pogodi.States.Clock is

   --------------
   -- Keyboard --
   --------------

   overriding procedure Keyboard
     (Self  : in out Clock_State;
      State : Nu_Pogodi.Keyboard.Keyboard_State) is
   begin
      if State.Released (Nu_Pogodi.Keyboard.Game_A) then
         Nu_Pogodi.Application.Request_Game_State (Nu_Pogodi.Scene.Mode_A);

      elsif State.Released (Nu_Pogodi.Keyboard.Game_B) then
         Nu_Pogodi.Application.Request_Game_State (Nu_Pogodi.Scene.Mode_B);
      end if;
   end Keyboard;

   ------------------
   -- Physics_Tick --
   ------------------

   overriding procedure Physics_Tick
     (Self    : in out Clock_State;
      Refresh : in out Boolean) is
   begin
      null;
   end Physics_Tick;

   ------------
   -- Render --
   ------------

   overriding procedure Render
     (Self        : in out Clock_State;
      Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer)
   is
      Set : Nu_Pogodi.Display_Segments.Display_Segment_Set;

   begin
      Nu_Pogodi.Scene.Screen.Get_Visibility (Set);
      Nu_Pogodi.Bitmaps.Draw (Framebuffer, Set);
      Nu_Pogodi.Clock.Draw (Framebuffer);
   end Render;

end Nu_Pogodi.States.Clock;
