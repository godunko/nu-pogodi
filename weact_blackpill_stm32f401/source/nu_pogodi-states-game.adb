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

package body Nu_Pogodi.States.Game is

   --------------
   -- Keyboard --
   --------------

   overriding procedure Keyboard
     (Self  : in out Game_State;
      State : Nu_Pogodi.Keyboard.Keyboard_State) is
   begin
      Nu_Pogodi.Scene.Update_Keyboad_State (State);
   end Keyboard;

   ------------------
   -- Physics_Tick --
   ------------------

   overriding procedure Physics_Tick
     (Self    : in out Game_State;
      Refresh : in out Boolean) is
   begin
      Nu_Pogodi.Scene.Update_Physics_Tick (Refresh);
   end Physics_Tick;

   ------------
   -- Render --
   ------------

   overriding procedure Render
     (Self        : in out Game_State;
      Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer)
   is
      Set : Nu_Pogodi.Display_Segments.Display_Segment_Set;

   begin
      Nu_Pogodi.Scene.Screen.Get_Visibility (Set);
      Nu_Pogodi.Bitmaps.Draw (Framebuffer, Set);
      Nu_Pogodi.Clock.Draw (Framebuffer);

      if Nu_Pogodi.Scene.Is_Game_Over then
         Nu_Pogodi.Application.Request_Clock_State;
      end if;
   end Render;

end Nu_Pogodi.States.Game;
