--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Nu_Pogodi.Application;
with Nu_Pogodi.Drawing;
with Nu_Pogodi.States.Splash.Frames;

package body Nu_Pogodi.States.Splash is

   Last_Frame_Tick : constant := Frames.Last_Frame * Ticks_Per_Frame;
   Hold_Ticks      : constant := Last_Frame_Tick + Physics_Ticks_Per_Second;

   --------------
   -- Keyboard --
   --------------

   overriding procedure Keyboard
     (Self  : in out Splash_State;
      State : Nu_Pogodi.Keyboard.Keyboard_State) is
   begin
      null;
   end Keyboard;

   ------------------
   -- Physics_Tick --
   ------------------

   overriding procedure Physics_Tick
     (Self    : in out Splash_State;
      Refresh : in out Boolean) is
   begin
      if not Self.Started or else Self.Tick >= Hold_Ticks then
         return;
      end if;

      Self.Tick := @ + 1;

      if Self.Tick <= Last_Frame_Tick then
         if Self.Tick mod Ticks_Per_Frame = 0 then
            Refresh := True;
         end if;

      elsif Self.Tick = Hold_Ticks then
         Nu_Pogodi.Application.Request_Clock_State;
      end if;
   end Physics_Tick;

   ------------
   -- Render --
   ------------

   overriding procedure Render
     (Self        : in out Splash_State;
      Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer)
   is
      Frame : constant Natural :=
        Natural'Min (Self.Tick / Ticks_Per_Frame, Frames.Last_Frame);

   begin
      Self.Started := True;

      if Frame /= 0 then
         Nu_Pogodi.Drawing.Draw (Framebuffer, Frames.Descriptors (Frame));
      end if;
   end Render;

end Nu_Pogodi.States.Splash;
