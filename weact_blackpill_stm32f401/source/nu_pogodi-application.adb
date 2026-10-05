--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.ARMv7M.Instructions;
with A0B.Callbacks.Generic_Parameterless;

with Nu_Pogodi.Hardware.SSD1683;

package body Nu_Pogodi.Application is

   procedure On_SSD1683_Reset;

   package On_SSD1683_Reset_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_SSD1683_Reset);

   ----------------------
   -- On_SSD1683_Reset --
   ----------------------

   procedure On_SSD1683_Reset is
   begin
      null;

      raise Program_Error;
   end On_SSD1683_Reset;

   ---------
   -- Run --
   ---------

   procedure Run is
   begin
      Nu_Pogodi.Hardware.SSD1683.Reset
        (On_SSD1683_Reset_Callbacks.Create_Callback);

      loop
         A0B.ARMv7M.Instructions.Wait_For_Interrupt;
      end loop;
   end Run;

end Nu_Pogodi.Application;
