--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

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
   Data_Descriptor    : access
     A0B.Asynchronous_Operations.Transfer_Descriptor;
   Data_Descriptors   : access
     A0B.Asynchronous_Operations.Transfer_Descriptor_Array;

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
     (Command    : Command_Code;
      Descriptor : aliased in out
        A0B.Asynchronous_Operations.Transfer_Descriptor;
      Finished   : A0B.Callbacks.Callback;
      Success    : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      Nu_Pogodi.Hardware.SPI.Acquire_MIPI_Read;
      Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (False);  --  Command mode

      State := Transmit_Command_Receive_Data;
      Transfer_Callback := Finished;
      Data_Descriptor  := Descriptor'Unchecked_Access;
      Data_Descriptors := null;

      Command_Storage := A0B.Types.Unsigned_8 (Command);
      Command_Descriptor.Buffer := Command_Storage'Address;
      Command_Descriptor.Length := 1;

      Nu_Pogodi.Hardware.SPI.Transmit
        (Command_Descriptor, On_Transfer_Callbacks.Create_Callback, Success);

      if not Success then
         State := Inactive;
         Nu_Pogodi.Hardware.SPI.Release;
         A0B.Callbacks.Unset (Transfer_Callback);
      end if;
   end Command_Read;

   ------------------
   -- Command_Read --
   ------------------

   procedure Command_Read
     (Command     : Command_Code;
      Descriptors : aliased in out
        A0B.Asynchronous_Operations.Transfer_Descriptor_Array;
      Finished    : A0B.Callbacks.Callback;
      Success     : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      Nu_Pogodi.Hardware.SPI.Acquire_MIPI_Read;
      Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (False);  --  Command mode

      State := Transmit_Command_Receive_Data;
      Transfer_Callback := Finished;
      Data_Descriptor  := null;
      Data_Descriptors := Descriptors'Unchecked_Access;

      Command_Storage := A0B.Types.Unsigned_8 (Command);
      Command_Descriptor.Buffer := Command_Storage'Address;
      Command_Descriptor.Length := 1;

      Nu_Pogodi.Hardware.SPI.Transmit
        (Command_Descriptor, On_Transfer_Callbacks.Create_Callback, Success);

      if not Success then
         State := Inactive;
         Nu_Pogodi.Hardware.SPI.Release;
         A0B.Callbacks.Unset (Transfer_Callback);
      end if;
   end Command_Read;

   -------------------
   -- Command_Write --
   -------------------

   procedure Command_Write
     (Command    : Command_Code;
      Descriptor : aliased in out
        A0B.Asynchronous_Operations.Transfer_Descriptor;
      Finished   : A0B.Callbacks.Callback;
      Success    : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      Nu_Pogodi.Hardware.SPI.Acquire_MIPI_Write;
      Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (False);  --  Command mode

      State := Transmit_Command_Transmit_Data;
      Transfer_Callback := Finished;
      Data_Descriptor := Descriptor'Unchecked_Access;

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

      procedure Finish;

      ------------
      -- Finish --
      ------------

      procedure Finish is
      begin
         State := Inactive;

         Nu_Pogodi.Hardware.SPI.Release;

         A0B.Callbacks.Emit_Once (Transfer_Callback);
      end Finish;

      Success : Boolean := True;

   begin
      case State is
         when Inactive =>
            raise Program_Error;

         when Transmit_Command =>
            Finish;

         when Transmit_Command_Transmit_Data =>
            State := Transmit_Data;

            Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (True);  --  Data mode

            Nu_Pogodi.Hardware.SPI.Transmit
              (Data_Descriptor.all,
               On_Transfer_Callbacks.Create_Callback,
               Success);

            if not Success then
               Finish;
            end if;

         when Transmit_Data =>
            Finish;

         when Transmit_Command_Receive_Data =>
            State := Receive_Data;

            Nu_Pogodi.Hardware.Pin_Control.Set_MIPI_D_C (True);  --  Data mode

            if Data_Descriptors /= null then
               Nu_Pogodi.Hardware.SPI.Receive
                 (Data_Descriptors.all,
                  On_Transfer_Callbacks.Create_Callback,
                  Success);

            else
               Nu_Pogodi.Hardware.SPI.Receive
                 (Data_Descriptor.all,
                  On_Transfer_Callbacks.Create_Callback,
                  Success);
            end if;

            if not Success then
               if Data_Descriptors /= null then
                  for Descriptor of Data_Descriptors.all loop
                     if Descriptor /= null then
                        Descriptor.State :=
                          A0B.Asynchronous_Operations.Failure;
                        Descriptor.Transferred := 0;
                     end if;
                  end loop;

               else
                  Data_Descriptor.State := A0B.Asynchronous_Operations.Failure;
                  Data_Descriptor.Transferred := 0;
               end if;

               Finish;
            end if;

         when Receive_Data =>
            Finish;
      end case;
   end On_Transfer;

end Nu_Pogodi.Hardware.MIPI;
