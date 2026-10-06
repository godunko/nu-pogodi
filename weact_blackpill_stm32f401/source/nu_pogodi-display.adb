--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Nu_Pogodi.Hardware.SSD1683.Synchronous;

package body Nu_Pogodi.Display is

   ------------
   -- Update --
   ------------

   procedure Update
     (New_Buffer : A0B.Buffers.Abstract_Buffer'Class;
      Old_Buffer : A0B.Buffers.Abstract_Buffer'Class;
      Callback   : A0B.Callbacks.Callback;
      Success    : in out Boolean) is
   begin
      Nu_Pogodi.Hardware.SSD1683.Synchronous.Write_RAM_Black_White
        (New_Buffer, Success);

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Write_RAM_Red
        (Old_Buffer, Success);

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Master_Activation (Success);

      A0B.Callbacks.Emit (Callback);
   end Update;

end Nu_Pogodi.Display;
