--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Asynchronous_Operations;
with A0B.Callbacks.Generic_Parameterless;

with Nu_Pogodi.Hardware.Pin_Control;
with Nu_Pogodi.Hardware.SPI;

package body Nu_Pogodi.Hardware.MIPI is

   type States is
     (Inactive,
      Transmit_Command,
      Transmit_Command_Transmit_Data,
      Transmit_Data,
      Transmit_Command_Receive_Data,
      Receive_Data);

   procedure On_Transfer;

   package On_Transfer_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Transfer);

   State : States := Inactive;

   Transfer_Callback : aliased A0B.Callbacks.Callback;

   Command_Storage    : aliased A0B.Types.Unsigned_8;
   Command_Descriptor : aliased
     A0B.Asynchronous_Operations.Transfer_Descriptor;
   Data_Buffer        : access A0B.Buffers.Abstract_Buffer'Class;
   Data_Descriptor    : aliased
     A0B.Asynchronous_Operations.Transfer_Descriptor;
   Ignore_First_Byte  : Boolean;

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

      Nu_Pogodi.Hardware.SPI.Acquire_MIPI_Write;
      Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (False);  --  Command mode

      State := Transmit_Command;
      Transfer_Callback := Finished;
      Command_Storage := A0B.Types.Unsigned_8 (Command);
      Command_Descriptor.Buffer := Command_Storage'Address;
      Command_Descriptor.Length := 1;

      Nu_Pogodi.Hardware.SPI.Transmit
        (Command_Descriptor, On_Transfer_Callbacks.Create_Callback, Success);

      if not Success then
         Nu_Pogodi.Hardware.SPI.Release;
      end if;
   end Command;

   ------------------
   -- Command_Read --
   ------------------

   procedure Command_Read
     (Command           : Command_Code;
      Buffer            : aliased in out A0B.Buffers.Abstract_Buffer'Class;
      Finished          : A0B.Callbacks.Callback;
      Success           : in out Boolean;
      Ignore_First_Byte : Boolean := False) is
   begin
      if not Success then
         return;
      end if;

      Nu_Pogodi.Hardware.SPI.Acquire_MIPI_Read;
      Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (False);  --  Command mode

      State := Transmit_Command_Receive_Data;
      Transfer_Callback := Finished;
      Data_Buffer := Buffer'Unchecked_Access;
      MIPI.Ignore_First_Byte := Ignore_First_Byte;

      Command_Storage := A0B.Types.Unsigned_8 (Command);
      Command_Descriptor.Buffer := Command_Storage'Address;
      Command_Descriptor.Length := 1;

      Nu_Pogodi.Hardware.SPI.Transmit
        (Command_Descriptor, On_Transfer_Callbacks.Create_Callback, Success);

      if not Success then
         Nu_Pogodi.Hardware.SPI.Release;
      end if;
   end Command_Read;

   -------------------
   -- Command_Write --
   -------------------

   procedure Command_Write
     (Command  : Command_Code;
      Buffer   : aliased A0B.Buffers.Abstract_Buffer'Class;
      Finished : A0B.Callbacks.Callback;
      Success  : in out Boolean)
   is
   begin
      if not Success then
         return;
      end if;

      Nu_Pogodi.Hardware.SPI.Acquire_MIPI_Write;
      Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (False);  --  Command mode

      State := Transmit_Command_Transmit_Data;
      Transfer_Callback := Finished;
      Data_Buffer := Buffer'Unrestricted_Access;

      Command_Storage := A0B.Types.Unsigned_8 (Command);
      Command_Descriptor.Buffer := Command_Storage'Address;
      Command_Descriptor.Length := 1;

      Nu_Pogodi.Hardware.SPI.Transmit
        (Command_Descriptor, On_Transfer_Callbacks.Create_Callback, Success);

      if not Success then
         Nu_Pogodi.Hardware.SPI.Release;
      end if;
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
      Success : Boolean := True;

   begin
      case State is
         when Inactive =>
            raise Program_Error;

         when Transmit_Command =>
            State := Inactive;

            Nu_Pogodi.Hardware.SPI.Release;

            A0B.Callbacks.Emit_Once (Transfer_Callback);

         when Transmit_Command_Transmit_Data =>
            State := Transmit_Data;

            Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (True);  --  Data mode

            Data_Descriptor.Buffer := Data_Buffer.Address;
            Data_Descriptor.Length :=
              A0B.Types.Unsigned_32 (Data_Buffer.Length);

            Nu_Pogodi.Hardware.SPI.Transmit
              (Data_Descriptor,
               On_Transfer_Callbacks.Create_Callback,
               Success);

            if not Success then
               State := Inactive;

               Nu_Pogodi.Hardware.SPI.Release;

               A0B.Callbacks.Emit_Once (Transfer_Callback);
            end if;

         when Transmit_Data =>
            State := Inactive;

            Nu_Pogodi.Hardware.SPI.Release;

            A0B.Callbacks.Emit_Once (Transfer_Callback);

         when Transmit_Command_Receive_Data =>
            State := Receive_Data;

            Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (True);  --  Data mode

            if Ignore_First_Byte then
               Nu_Pogodi.Hardware.SPI.Receive
                 (Data_Buffer.all,
                  On_Transfer_Callbacks.Create_Callback,
                  Success,
                  Ignore_First_Byte);

            else
               Data_Descriptor.Buffer := Data_Buffer.Address;
               Data_Descriptor.Length :=
                 A0B.Types.Unsigned_32 (Data_Buffer.Expected_Length);

               Nu_Pogodi.Hardware.SPI.Receive
                 (Data_Descriptor,
                  On_Transfer_Callbacks.Create_Callback,
                  Success);
            end if;

            if not Success then
               State := Inactive;

               Nu_Pogodi.Hardware.SPI.Release;

               A0B.Callbacks.Emit_Once (Transfer_Callback);
            end if;

         when Receive_Data =>
            State := Inactive;

            if not Ignore_First_Byte then
               Data_Buffer.Set_Actual_Length
                 (A0B.Buffers.Storage_Count (Data_Descriptor.Transferred));
            end if;

            Nu_Pogodi.Hardware.SPI.Release;

            A0B.Callbacks.Emit_Once (Transfer_Callback);
      end case;
   end On_Transfer;

end Nu_Pogodi.Hardware.MIPI;
