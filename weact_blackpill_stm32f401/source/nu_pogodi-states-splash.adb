--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Callbacks.Generic_Discrete;

with Nu_Pogodi.Application;
with Nu_Pogodi.Hardware.Sound;
with Nu_Pogodi.Logo;
with Nu_Pogodi.Matrix_Printer;

package body Nu_Pogodi.States.Splash is

   Last_Frame : constant Natural :=
     Nu_Pogodi.Matrix_Printer.Frame_Count (Nu_Pogodi.Logo.Descriptor);
   Last_Frame_Tick : constant Natural := Last_Frame * Ticks_Per_Frame;
   Hold_Ticks      : constant Natural :=
     Last_Frame_Tick + Physics_Ticks_Per_Second;

   type Buffer_Index is range 0 .. 1;

   Buffer_0, Buffer_1 : aliased Nu_Pogodi.Hardware.Sound.Sample_Array :=
     [0 .. Nu_Pogodi.Hardware.Sound.Samples_Per_Frame - 1 =>
        (ARR => 249, CCR1 => 0, others => <>)] with Alignment => 4;

   type Sound_Buffer_Access is
     access all Nu_Pogodi.Hardware.Sound.Sample_Array;

   Buffers : constant array (Buffer_Index) of Sound_Buffer_Access :=
     [Buffer_0'Access, Buffer_1'Access];

   procedure On_Sound_Finished (Frame : Natural);

   package Sound_Finished_Callbacks is
     new A0B.Callbacks.Generic_Discrete (Natural, On_Sound_Finished);

   --------------
   -- Keyboard --
   --------------

   overriding procedure Keyboard
     (Self  : in out Splash_State;
      State : Nu_Pogodi.Keyboard.Keyboard_State) is
   begin
      null;
   end Keyboard;

   -----------------------
   -- On_Sound_Finished --
   -----------------------

   procedure On_Sound_Finished (Frame : Natural) is
      Buffer  : constant Buffer_Index := Buffer_Index (Frame mod 2);
      Success : Boolean;

   begin
      if Frame >= Last_Frame then
         return;
      end if;

      Nu_Pogodi.Hardware.Sound.Start
        (Buffers (Buffer).all,
         Sound_Finished_Callbacks.Create_Callback (Frame + 1),
         Success);

      if not Success then
         raise Program_Error;
      end if;
   end On_Sound_Finished;

   ------------------
   -- Physics_Tick --
   ------------------

   overriding procedure Physics_Tick
     (Self    : in out Splash_State;
      Refresh : in out Boolean) is
   begin
      if not Self.Started then
         Self.Started := True;

         if Last_Frame /= 0 then
            Nu_Pogodi.Matrix_Printer.Generate_Sound
              (Nu_Pogodi.Logo.Descriptor, 1, Buffers (0).all);
            On_Sound_Finished (0);

            if Last_Frame > 1 then
               Nu_Pogodi.Matrix_Printer.Generate_Sound
                 (Nu_Pogodi.Logo.Descriptor, 2, Buffers (1).all);
            end if;
         end if;

         return;
      end if;

      if Self.Tick >= Hold_Ticks then
         return;
      end if;

      Self.Tick := @ + 1;

      if Self.Tick <= Last_Frame_Tick then
         if Self.Tick mod Ticks_Per_Frame = 0 then
            Refresh := True;

            declare
               Sound_Frame : constant Positive :=
                 Self.Tick / Ticks_Per_Frame + 2;

            begin
               if Sound_Frame <= Last_Frame then
                  Nu_Pogodi.Matrix_Printer.Generate_Sound
                    (Nu_Pogodi.Logo.Descriptor,
                     Sound_Frame,
                     Buffers (Buffer_Index ((Sound_Frame - 1) mod 2)).all);
               end if;
            end;
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
        Natural'Min (Self.Tick / Ticks_Per_Frame, Last_Frame);

   begin
      if Frame /= 0 then
         Nu_Pogodi.Matrix_Printer.Draw
           (Framebuffer,
            Nu_Pogodi.Logo.X,
            Nu_Pogodi.Logo.Y,
            Nu_Pogodi.Logo.Descriptor,
            Frame);
      end if;
   end Render;

end Nu_Pogodi.States.Splash;
