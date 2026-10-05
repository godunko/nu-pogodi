--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.ARMv7M.Instructions;
with A0B.Buffers.Static;
--  with A0B.Callbacks.Generic_Parameterless;
with A0B.Types.Arrays;

with Nu_Pogodi.Hardware.SSD1683.Synchronous;

package body Nu_Pogodi.Application is

   --  procedure On_SSD1683_Reset;
   --
   --  package On_SSD1683_Reset_Callbacks is
   --    new A0B.Callbacks.Generic_Parameterless (On_SSD1683_Reset);

   --  procedure On_Write_BW;
   --
   --  package On_Write_BW_Callbacks is
   --    new A0B.Callbacks.Generic_Parameterless (On_Write_BW);

   --  procedure On_Write_Red;

   --  package On_Write_Red_Callbacks is
   --    new A0B.Callbacks.Generic_Parameterless (On_Write_Red);

   --  procedure On_DUC2;

   --  package On_DUC2_Callbacks is
   --    new A0B.Callbacks.Generic_Parameterless (On_DUC2);

   --  procedure On_MA;

   --  package On_MA_Callbacks is
   --    new A0B.Callbacks.Generic_Parameterless (On_MA);

   Pixel_Buffer : A0B.Buffers.Static.Static_Buffer (15_000);

   ----------------------
   -- On_SSD1683_Reset --
   ----------------------

   --  procedure On_SSD1683_Reset is
   --     Success : Boolean := True;
   --
   --  begin
   --     declare
   --        Data : A0B.Types.Arrays.Unsigned_8_Array (1 .. 15_000)
   --          with Import, Address => Pixel_Buffer.Address;
   --
   --     begin
   --        Data := [others => 16#FF#];
   --        Pixel_Buffer.Set_Actual_Length (15_000);
   --     end;
   --
   --     Nu_Pogodi.Hardware.SSD1683.Write_RAM_Black_White
   --       (Pixel_Buffer,
   --        On_Write_BW_Callbacks.Create_Callback,
   --        Success);
   --
   --     if not Success then
   --        raise Program_Error;
   --     end if;
   --  end On_SSD1683_Reset;

   -----------------
   -- On_Write_BW --
   -----------------

   --  procedure On_Write_BW is
   --     Success : Boolean := True;
   --
   --  begin
   --     declare
   --        Data : A0B.Types.Arrays.Unsigned_8_Array (1 .. 15_000)
   --          with Import, Address => Pixel_Buffer.Address;
   --
   --     begin
   --        Data := [others => 16#00#];
   --        Pixel_Buffer.Set_Actual_Length (15_000);
   --     end;
   --
   --     Nu_Pogodi.Hardware.SSD1683.Write_RAM_Red
   --       (Pixel_Buffer,
   --        On_Write_Red_Callbacks.Create_Callback,
   --        Success);
   --
   --     if not Success then
   --        raise Program_Error;
   --     end if;
   --  end On_Write_BW;

   ------------------
   -- On_Write_Red --
   ------------------

   --  procedure On_Write_Red is
   --     Success : Boolean := True;
   --
   --  begin
   --     Nu_Pogodi.Hardware.SSD1683.Display_Update_Control_2
   --       ((Enable_Clock      => True,
   --         Enable_Analog     => True,
   --         Load_Temperature  => True,
   --         Loat_LUT_From_OTP => True,
   --         Update_Mode       => False,
   --         Update_Display    => True,
   --         Disable_Analog    => True,
   --         Disable_Clock     => True),
   --        On_DUC2_Callbacks.Create_Callback,
   --        Success);
   --
   --     if not Success then
   --        raise Program_Error;
   --     end if;
   --  end On_Write_Red;

   -------------
   -- On_DUC2 --
   -------------

   --  procedure On_DUC2 is
   --     Success : Boolean := True;
   --
   --  begin
   --     Nu_Pogodi.Hardware.SSD1683.Master_Activation
   --       (On_MA_Callbacks.Create_Callback, Success);
   --
   --     if not Success then
   --        raise Program_Error;
   --     end if;
   --  end On_DUC2;

   -----------
   -- On_MA --
   -----------

   --  procedure On_MA is
   --  begin
   --     raise Program_Error;
   --  end On_MA;

   ---------
   -- Run --
   ---------

   procedure Run is
      Success : Boolean := True;

   begin
      --  Nu_Pogodi.Hardware.SSD1683.Reset
      --    (On_SSD1683_Reset_Callbacks.Create_Callback);

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Reset (Success);

      declare
         Data : A0B.Types.Arrays.Unsigned_8_Array (1 .. 15_000)
           with Import, Address => Pixel_Buffer.Address;

      begin
         Data := [others => 16#FF#];
         Pixel_Buffer.Set_Actual_Length (15_000);
      end;

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Write_RAM_Black_White
        (Pixel_Buffer, Success);

      declare
         Data : A0B.Types.Arrays.Unsigned_8_Array (1 .. 15_000)
           with Import, Address => Pixel_Buffer.Address;

      begin
         Data := [others => 16#00#];
         Pixel_Buffer.Set_Actual_Length (15_000);
      end;

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Write_RAM_Red
        (Pixel_Buffer, Success);

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Display_Update_Control_2
        ((Enable_Clock      => True,
          Enable_Analog     => True,
          Load_Temperature  => True,
          Loat_LUT_From_OTP => True,
          Update_Mode       => False,
          Update_Display    => True,
          Disable_Analog    => True,
          Disable_Clock     => True),
         Success);
      Nu_Pogodi.Hardware.SSD1683.Synchronous.Master_Activation (Success);

      loop
         A0B.ARMv7M.Instructions.Wait_For_Interrupt;
      end loop;
   end Run;

end Nu_Pogodi.Application;
