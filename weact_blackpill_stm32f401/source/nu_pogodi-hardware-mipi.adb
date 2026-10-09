--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

--  with A0B.Buffers.Static;
with A0B.Callbacks.Generic_Parameterless;

with Nu_Pogodi.Hardware.Pin_Control;
with Nu_Pogodi.Hardware.SPI;

package body Nu_Pogodi.Hardware.MIPI is

   --  Aux : A0B.Types.Unsigned_8 with Export, Volatile;

   --  Command_Buffer : A0B.Buffers.Static.Static_Buffer (1);

   procedure On_Transfer;

   package On_Transfer_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Transfer);

   Transfer_Callback : A0B.Callbacks.Callback;

   -------------
   -- Command --
   -------------

   procedure Command
     (Command  : Command_Code;
      Finished : A0B.Callbacks.Callback;
      Success  : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      --  XXX Rewrite to use asynchronous SPI transfer, not implemented yet.

      Nu_Pogodi.Hardware.SPI.Acquire_MIPI_Write;
      Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (False);  --  Command mode
      Nu_Pogodi.Hardware.SPI.Transmit
        (A0B.Types.Unsigned_8 (Command));
      Nu_Pogodi.Hardware.SPI.Release;

      A0B.Callbacks.Emit (Finished);
   end Command;

   ------------------
   -- Command_Read --
   ------------------

   procedure Command_Read
     (Command           : Command_Code;
      Buffer            : in out A0B.Buffers.Abstract_Buffer'Class;
      Finished          : A0B.Callbacks.Callback;
      Success           : in out Boolean;
      Ignore_First_Byte : Boolean := False) is
   begin
      if not Success then
         return;
      end if;

      Transfer_Callback := Finished;

      Nu_Pogodi.Hardware.SPI.Acquire_MIPI_Read;

      Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (False);
      Nu_Pogodi.Hardware.SPI.Transmit (A0B.Types.Unsigned_8 (Command));

      Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (True);
      Nu_Pogodi.Hardware.SPI.Receive
        (Buffer,
         On_Transfer_Callbacks.Create_Callback,
         Success,
         Ignore_First_Byte);

      if not Success then
         Nu_Pogodi.Hardware.SPI.Release;
      end if;
   end Command_Read;

   -------------------
   -- Command_Write --
   -------------------

   procedure Command_Write
     (Command  : Command_Code;
      Buffer   : A0B.Buffers.Abstract_Buffer'Class;
      Finished : A0B.Callbacks.Callback;
      Success  : in out Boolean)
   is
   begin
      if not Success then
         return;
      end if;

      Transfer_Callback := Finished;

      --  XXX Rewrite to use asynchronous SPI transfer, not implemented yet.
      --  Transfer of the buffer is done asynchronously, it might be enough,
      --  because transfer of single byte of the command with DMA/interrupts
      --  might take more CPU clock cycles than software polling.

      Nu_Pogodi.Hardware.SPI.Acquire_MIPI_Write;

      Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (False);  --  Command mode
      Nu_Pogodi.Hardware.SPI.Transmit
        (A0B.Types.Unsigned_8 (Command));

      Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (True);  --  Data mode
      Nu_Pogodi.Hardware.SPI.Transmit
        (Buffer, On_Transfer_Callbacks.Create_Callback, Success);
   end Command_Write;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Nu_Pogodi.Hardware.Pin_Control.Configure_MIPI_Pins;
      Nu_Pogodi.Hardware.SPI.Initialize;
   end Initialize;

   -----------------
   -- On_Transfer --
   -----------------

   procedure On_Transfer is
   begin
      Nu_Pogodi.Hardware.SPI.Release;

      A0B.Callbacks.Emit_Once (Transfer_Callback);
   end On_Transfer;

end Nu_Pogodi.Hardware.MIPI;
