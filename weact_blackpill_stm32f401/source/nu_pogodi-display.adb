--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Buffers.External;
with A0B.Callbacks.Generic_Parameterless;
with A0B.Types;

with Nu_Pogodi.Hardware.SSD1683.Utilities;
with System.Storage_Elements;

package body Nu_Pogodi.Display is

   type State_Kind is
     (Initial,

      --  Read Waveforms Setting from display's OTP into MCU's RAM.

      Read_Waveforms_Enable_Clock_Display_Update_Control_2,
      Read_Waveforms_Enable_Clock_Master_Activation,
      Read_Waveforms_Load_OTP_X_Address,
      Read_Waveforms_Load_OTP_Y_Address,
      Read_Waveforms_Load_OTP,
      Read_Waveforms_Read_RAM_X_Address,
      Read_Waveforms_Read_RAM_Y_Address,
      Read_Waveforms_Read_RAM_Option,
      Read_Waveforms_Read_RAM,
      Read_Waveforms_Read_OTP_Display_Option,
      Read_Waveforms_Disable_Clock_Display_Update_Control_2,
      Read_Waveforms_Disable_Clock_Master_Activate,

      --  Select Waveforms Setting for fast partial update mode, change
      --  refresh frequency, and load into display.

      Write_Waveforms_Read_Temperature,
      Write_Waveforms_LUT,
      Write_Waveforms_End_Option,
      Write_Waveforms_Gate_Driving_Voltage,
      Write_Waveforms_Source_Driving_Voltage,
      Write_Waveforms_VCOM,

      --  Write BW RAM and update panel in preselected update mode.

      Update_Write_Black_White,
      Update_Master_Activation);

   State              : State_Kind := Initial with Volatile;
   Completed_Callback : A0B.Callbacks.Callback;
   Factory_Waveforms  : aliased
     Nu_Pogodi.Hardware.SSD1683.Waveform_Setting_2C_Mapping;
   Factory_Options    : aliased
     Nu_Pogodi.Hardware.SSD1683.OTP_Display_Option_Registers;
   Temperature        : aliased A0B.Types.Integer_8;
   Selected_Waveforms : Nu_Pogodi.Hardware.SSD1683.Waveform_Setting_Index;
   Modified_LUT       : aliased Nu_Pogodi.Hardware.SSD1683.Waveform_LUT_2C;

   Buffer             : A0B.Buffers.External.External_Buffer;

   procedure On_Completed;

   package On_Completed_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Completed);

   ------------------
   -- On_Completed --
   ------------------

   procedure On_Completed is
      use type System.Storage_Elements.Storage_Count;
      use type A0B.Types.Unsigned_8;

      Success : Boolean := True;

   begin
      case State is
         when Initial =>
            raise Program_Error;

         when Read_Waveforms_Enable_Clock_Display_Update_Control_2 =>
            State := Read_Waveforms_Enable_Clock_Master_Activation;
            Nu_Pogodi.Hardware.SSD1683.Master_Activation
              (On_Completed_Callbacks.Create_Callback, Success);

         when Read_Waveforms_Enable_Clock_Master_Activation =>
            State := Read_Waveforms_Load_OTP_X_Address;
            Nu_Pogodi.Hardware.SSD1683.Set_RAM_X_Address_Counter
              (0, On_Completed_Callbacks.Create_Callback, Success);

         when Read_Waveforms_Load_OTP_X_Address =>
            State := Read_Waveforms_Load_OTP_Y_Address;
            Nu_Pogodi.Hardware.SSD1683.Set_RAM_Y_Address_Counter
              (0, On_Completed_Callbacks.Create_Callback, Success);

         when Read_Waveforms_Load_OTP_Y_Address =>
            State := Read_Waveforms_Load_OTP;
            Nu_Pogodi.Hardware.SSD1683.Load_WS_OTP
              (On_Completed_Callbacks.Create_Callback, Success);

         when Read_Waveforms_Load_OTP =>
            State := Read_Waveforms_Read_RAM_X_Address;
            Nu_Pogodi.Hardware.SSD1683.Set_RAM_X_Address_Counter
              (0, On_Completed_Callbacks.Create_Callback, Success);

         when Read_Waveforms_Read_RAM_X_Address =>
            State := Read_Waveforms_Read_RAM_Y_Address;
            Nu_Pogodi.Hardware.SSD1683.Set_RAM_Y_Address_Counter
              (0, On_Completed_Callbacks.Create_Callback, Success);

         when Read_Waveforms_Read_RAM_Y_Address =>
            State := Read_Waveforms_Read_RAM_Option;
            Nu_Pogodi.Hardware.SSD1683.Read_RAM_Option
              (Nu_Pogodi.Hardware.SSD1683.Black_White,
               Nu_Pogodi.Hardware.SSD1683.Window,
               Nu_Pogodi.Hardware.SSD1683.Waveform_Setting_2C_Mapping_Length,
               On_Completed_Callbacks.Create_Callback,
               Success);

         when Read_Waveforms_Read_RAM_Option =>
            State := Read_Waveforms_Read_RAM;
            A0B.Buffers.External.Initialize
              (Buffer,
               Factory_Waveforms'Address,
               Nu_Pogodi.Hardware.SSD1683.Waveform_Setting_2C_Mapping_Length);
            Buffer.Set_Allocation_Length
              (Nu_Pogodi.Hardware.SSD1683.Waveform_Setting_2C_Mapping_Length);
            Nu_Pogodi.Hardware.SSD1683.Read_RAM
              (Buffer, On_Completed_Callbacks.Create_Callback, Success);

         when Read_Waveforms_Read_RAM =>
            State := Read_Waveforms_Read_OTP_Display_Option;
            Nu_Pogodi.Hardware.SSD1683.OTP_Read_Display_Option
              (Factory_Options,
               On_Completed_Callbacks.Create_Callback,
               Success);

         when Read_Waveforms_Read_OTP_Display_Option =>
            State := Read_Waveforms_Disable_Clock_Display_Update_Control_2;
            Success := Buffer.Length = Buffer.Allocation_Length;
            Buffer.Finalize;
            Nu_Pogodi.Hardware.SSD1683.Display_Update_Control_2
              ((Disable_Clock => True, others => False),
               On_Completed_Callbacks.Create_Callback,
               Success);

         when Read_Waveforms_Disable_Clock_Display_Update_Control_2 =>
            State := Read_Waveforms_Disable_Clock_Master_Activate;
            Nu_Pogodi.Hardware.SSD1683.Master_Activation
              (On_Completed_Callbacks.Create_Callback, Success);

         when Read_Waveforms_Disable_Clock_Master_Activate =>
            State := Initial;
            A0B.Callbacks.Emit (Completed_Callback);

         when Write_Waveforms_Read_Temperature =>
            State := Write_Waveforms_LUT;
            Nu_Pogodi.Hardware.SSD1683.Utilities.Select_Partial
              (Factory_Waveforms.TR,
               Factory_Options.WS,
               Temperature,
               Selected_Waveforms,
               Success);
            Modified_LUT := Factory_Waveforms.WS (Selected_Waveforms).LUT;
            Modified_LUT.FR := (@ and 16#F0#) or 16#04#;
            --  Preserve the factory waveform except FR[3:0]: 100 Hz.

            Nu_Pogodi.Hardware.SSD1683.Write_LUT_Register
              (Modified_LUT,
               On_Completed_Callbacks.Create_Callback,
               Success);

         when Write_Waveforms_LUT =>
            State := Write_Waveforms_End_Option;
            Nu_Pogodi.Hardware.SSD1683.End_Option
              (Factory_Waveforms.WS (Selected_Waveforms).EOPT,
               On_Completed_Callbacks.Create_Callback,
               Success);

         when Write_Waveforms_End_Option =>
            State := Write_Waveforms_Gate_Driving_Voltage;
            Nu_Pogodi.Hardware.SSD1683.Gate_Driving_Voltage_Control
              (Factory_Waveforms.WS (Selected_Waveforms).VGH,
               On_Completed_Callbacks.Create_Callback,
               Success);

         when Write_Waveforms_Gate_Driving_Voltage =>
            State := Write_Waveforms_Source_Driving_Voltage;
            Nu_Pogodi.Hardware.SSD1683.Source_Driving_Voltage_Control
              (Factory_Waveforms.WS (Selected_Waveforms).VSH1_VSH2_VSL,
               On_Completed_Callbacks.Create_Callback,
               Success);

         when Write_Waveforms_Source_Driving_Voltage =>
            State := Write_Waveforms_VCOM;
            Nu_Pogodi.Hardware.SSD1683.Write_VCOM_Register
              (Factory_Waveforms.WS (Selected_Waveforms).VCOM,
               On_Completed_Callbacks.Create_Callback,
               Success);

         when Write_Waveforms_VCOM =>
            State := Initial;
            A0B.Callbacks.Emit (Completed_Callback);

         when Update_Write_Black_White =>
            State := Update_Master_Activation;
            Nu_Pogodi.Hardware.SSD1683.Master_Activation
              (On_Completed_Callbacks.Create_Callback, Success);

         when Update_Master_Activation =>
            State := Initial;
            A0B.Callbacks.Emit (Completed_Callback);
      end case;

      if not Success then
         --  XXX Error handling is not implemented yet

         raise Program_Error;
      end if;
   end On_Completed;

   ----------------------------
   -- Read_Factory_Waveforms --
   ----------------------------

   procedure Read_Factory_Waveforms
     (Callback : A0B.Callbacks.Callback; Success : in out Boolean) is
   begin
      pragma Assert (State = Initial);

      Completed_Callback := Callback;

      State := Read_Waveforms_Enable_Clock_Display_Update_Control_2;
      Nu_Pogodi.Hardware.SSD1683.Display_Update_Control_2
        ((Enable_Clock => True, others => False),
         On_Completed_Callbacks.Create_Callback,
         Success);
   end Read_Factory_Waveforms;

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

      State := Update_Write_Black_White;
      Nu_Pogodi.Hardware.SSD1683.Write_RAM_Black_White
        (Buffer, On_Completed_Callbacks.Create_Callback, Success);
   end Update;

   ----------------------------------------------------
   -- Write_Waveform_Setting_For_Fast_Partial_Update --
   ----------------------------------------------------

   procedure Write_Waveform_Setting_For_Fast_Partial_Update
     (Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean) is
   begin
      pragma Assert (State = Initial);

      Completed_Callback := Callback;

      State := Write_Waveforms_Read_Temperature;
      Nu_Pogodi.Hardware.SSD1683.Read_From_Temperature_Register
        (Temperature, On_Completed_Callbacks.Create_Callback, Success);
   end Write_Waveform_Setting_For_Fast_Partial_Update;

end Nu_Pogodi.Display;
