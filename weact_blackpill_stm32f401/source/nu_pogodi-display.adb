--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Callbacks.Generic_Parameterless;

with Nu_Pogodi.Hardware.SSD1683;

package body Nu_Pogodi.Display is

   type State_Kind is (Initial, Write_Black_White, Activation);

   State              : State_Kind := Initial with Volatile;
   Completed_Callback : A0B.Callbacks.Callback;

   procedure On_Completed;

   package On_Completed_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Completed);

   ------------------
   -- On_Completed --
   ------------------

   procedure On_Completed is
      Success : Boolean := True;

   begin
      case State is
         when Initial =>
            raise Program_Error;

         when Write_Black_White =>
            State := Activation;
            Nu_Pogodi.Hardware.SSD1683.Master_Activation
              (On_Completed_Callbacks.Create_Callback, Success);

         when Activation =>
            State := Initial;
            A0B.Callbacks.Emit (Completed_Callback);
      end case;
   end On_Completed;

   ------------
   -- Update --
   ------------

   procedure Update
     (Buffer   : aliased A0B.Buffers.Abstract_Buffer'Class;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean) is
   begin
      pragma Assert (State = Initial);

      Completed_Callback := Callback;

      State := Write_Black_White;
      Nu_Pogodi.Hardware.SSD1683.Write_RAM_Black_White
        (Buffer, On_Completed_Callbacks.Create_Callback, Success);
   end Update;

end Nu_Pogodi.Display;
