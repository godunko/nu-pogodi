--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

--  with A0B.Buffers.Static;

with Nu_Pogodi.Hardware.Pin_Control;
with Nu_Pogodi.Hardware.SPI;

package body Nu_Pogodi.Hardware.MIPI is

   --  Aux : A0B.Types.Unsigned_8 with Export, Volatile;

   --  Command_Buffer : A0B.Buffers.Static.Static_Buffer (1);

   -------------
   -- Command --
   -------------

   procedure Command
     (Command  : Command_Code;
      Finished : A0B.Callbacks.Callback;
      Success  : in out Boolean)
   is
   begin
      if not Success then
         return;
      end if;

      --  XXX Rewrite to use asynchronous SPI transfer, not implemented yet.

      Nu_Pogodi.Hardware.SPI.Acquire_MIPI_Write;
      Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (False);  --  Command mode
      Nu_Pogodi.Hardware.SPI.Transmit (A0B.Types.Unsigned_8 (Command));
      Nu_Pogodi.Hardware.SPI.Release;

      A0B.Callbacks.Emit (Finished);
   end Command;

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

      --  XXX Rewrite to use asynchronous SPI transfer, not implemented yet.

      Nu_Pogodi.Hardware.SPI.Acquire_MIPI_Write;

      Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (False);  --  Command mode
      Nu_Pogodi.Hardware.SPI.Transmit (A0B.Types.Unsigned_8 (Command));

      Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (True);  --  Data mode
      Nu_Pogodi.Hardware.SPI.Transmit (Buffer);

      Nu_Pogodi.Hardware.SPI.Release;

      A0B.Callbacks.Emit (Finished);
   end Command_Write;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Nu_Pogodi.Hardware.Pin_Control.Configure_MIPI_Pins;
      Nu_Pogodi.Hardware.SPI.Initialize;

      --  Nu_Pogodi.Hardware.SPI.Acquire_MIPI_Read;
      --  Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (False);  --  Command mode
      --  Nu_Pogodi.Hardware.SPI.Transmit (16#2F#);  --  Status Bit Read

      --  Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (True);  --  Data mode
      --  Nu_Pogodi.Hardware.SPI.Receive (Aux);
   end Initialize;

end Nu_Pogodi.Hardware.MIPI;
