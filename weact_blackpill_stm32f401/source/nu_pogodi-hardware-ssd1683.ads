--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

--  Driver of the SSD1683 display driver controller.
--
--  Framebuffer transfers use MSB-leftmost pixel format.
--
--  SPI is expected to be configured in MSB-first mode.

with A0B.Buffers;
with A0B.Callbacks;
with A0B.Types;

package Nu_Pogodi.Hardware.SSD1683 is

   type Update_Sequence is record
      Enable_Clock      : Boolean;
      Enable_Analog     : Boolean;
      Load_Temperature  : Boolean;
      Loat_LUT_From_OTP : Boolean;
      Update_Mode       : Boolean;
      Update_Display    : Boolean;
      Disable_Analog    : Boolean;
      Disable_Clock     : Boolean;
   end record with Size => 8;

   for Update_Sequence use record
      Enable_Clock      at 0 range 7 .. 7;
      Enable_Analog     at 0 range 6 .. 6;
      Load_Temperature  at 0 range 5 .. 5;
      Loat_LUT_From_OTP at 0 range 4 .. 4;
      Update_Mode       at 0 range 3 .. 3;
      Update_Display    at 0 range 2 .. 2;
      Disable_Analog    at 0 range 1 .. 1;
      Disable_Clock     at 0 range 0 .. 0;
   end record;

   type Temperature_Sensor is (External, Internal);

   type Address_Direction is (Decrement, Increment);

   type Direction is (X_Axis, Y_Axis);

   type RAM_Content is (Normal, Bypass, Inverse) with Size => 4;

   for RAM_Content use
     (Normal  => 2#0000#,
      Bypass  => 2#0100#,
      Inverse => 2#1000#);

   type RAM_Bank is (Black_White, Red);

   type CRC_Check_Mode is (Window, Counter);

   type Width_Pattern_Step is
     (Width_8,
      Width_16,
      Width_32,
      Width_64,
      Width_128,
      Width_256,
      Width_Full);

   for Width_Pattern_Step use
     (Width_8    => 2#000#,
      Width_16   => 2#001#,
      Width_32   => 2#010#,
      Width_64   => 2#011#,
      Width_128  => 2#100#,
      Width_256  => 2#101#,
      Width_Full => 2#110#);

   type Height_Pattern_Step is
     (Height_8,
      Height_16,
      Height_32,
      Height_64,
      Height_128,
      Height_256,
      Height_Full);

   for Height_Pattern_Step use
     (Height_8    => 2#000#,
      Height_16   => 2#001#,
      Height_32   => 2#010#,
      Height_64   => 2#011#,
      Height_128  => 2#100#,
      Height_256  => 2#101#,
      Height_Full => 2#110#);

   Display_Option_Registers_Length     : constant := 10;
   OTP_Display_Option_Registers_Length : constant := 11;

   type Display_Option_Registers is record
      Spare_VCOM_OTP : Boolean;
      Reserved_0_6_0 : A0B.Types.Reserved_7;
      WS             : A0B.Types.Unsigned_24;
      Reserved_4     : A0B.Types.Reserved_8;
      Reserved_5_7   : A0B.Types.Reserved_1;
      RAM_Ping_Pong  : Boolean;
      Reserved_5_5_0 : A0B.Types.Unsigned_6;
      ID_Version     : A0B.Types.Unsigned_32;
   end record with Size => 8 * Display_Option_Registers_Length;

   for Display_Option_Registers use record
      Reserved_0_6_0 at 0 range 0 .. 6;
      Spare_VCOM_OTP at 0 range 7 .. 7;
      WS             at 1 range 0 .. 23;
      Reserved_4     at 4 range 0 .. 7;
      Reserved_5_5_0 at 5 range 0 .. 5;
      RAM_Ping_Pong  at 5 range 6 .. 6;
      Reserved_5_7   at 5 range 7 .. 7;
      ID_Version     at 6 range 0 .. 31;
   end record;

   type OTP_Display_Option_Registers is record
      Spare_VCOM_OTP : Boolean;
      Reserved_0_6_0 : A0B.Types.Reserved_7;
      VCOM           : A0B.Types.Unsigned_8;
      WS             : A0B.Types.Unsigned_24;
      Reserved_5     : A0B.Types.Reserved_8;
      Reserved_6_7   : A0B.Types.Reserved_1;
      RAM_Ping_Pong  : Boolean;
      Reserved_6_5_0 : A0B.Types.Unsigned_6;
      ID_Version     : A0B.Types.Unsigned_32;
   end record with Size => 8 * OTP_Display_Option_Registers_Length;

   for OTP_Display_Option_Registers use record
      Reserved_0_6_0 at 0 range 0 .. 6;
      Spare_VCOM_OTP at 0 range 7 .. 7;
      VCOM           at 1 range 0 .. 7;
      WS             at 2 range 0 .. 23;
      Reserved_5     at 5 range 0 .. 7;
      Reserved_6_5_0 at 6 range 0 .. 5;
      RAM_Ping_Pong  at 6 range 6 .. 6;
      Reserved_6_7   at 6 range 7 .. 7;
      ID_Version     at 7 range 0 .. 31;
   end record;

   Waveform_Phase_2C_Length                : constant := 1;
   Waveform_Group_2C_Length                : constant := 7;
   Waveform_Sequence_2C_Length             : constant := 42;
   Waveform_LUT_2C_Length                  : constant := 227;
   Waveform_Setting_2C_Length              : constant := 233;
   Waveform_Temperature_Range_Length       : constant := 2;
   Waveform_Setting_2C_Array_Length        : constant := 5_592;
   Waveform_Temperature_Range_Array_Length : constant := 48;
   Waveform_Setting_2C_Mapping_Length      : constant := 5_640;

   type Waveform_Phase_2C is record
      TP : A0B.Types.Unsigned_6;
      VS : A0B.Types.Unsigned_2;
   end record with Size => Waveform_Phase_2C_Length * 8;

   for Waveform_Phase_2C use record
      TP at 0 range 0 .. 5;
      VS at 0 range 6 .. 7;
   end record;

   type Waveform_Group_2C is record
      RP    : A0B.Types.Unsigned_8;
      A     : Waveform_Phase_2C;
      B     : Waveform_Phase_2C;
      C     : Waveform_Phase_2C;
      D     : Waveform_Phase_2C;
      SR_AB : A0B.Types.Unsigned_8;
      SR_CD : A0B.Types.Unsigned_8;
   end record with Size => Waveform_Group_2C_Length * 8;

   for Waveform_Group_2C use record
      RP    at 0 range 0 .. 7;
      A     at 1 range 0 .. 7;
      B     at 2 range 0 .. 7;
      C     at 3 range 0 .. 7;
      D     at 4 range 0 .. 7;
      SR_AB at 5 range 0 .. 7;
      SR_CD at 6 range 0 .. 7;
   end record;

   type Waveform_Sequence_2C is array (0 .. 5) of Waveform_Group_2C
     with Component_Size => Waveform_Group_2C_Length * 8,
          Size           => Waveform_Sequence_2C_Length * 8;

   type Waveform_LUT_2C is record
      LUTC             : Waveform_Sequence_2C;
      LUTWW            : Waveform_Sequence_2C;
      LUTBW            : Waveform_Sequence_2C;
      LUTWB            : Waveform_Sequence_2C;
      LUTBB            : Waveform_Sequence_2C;
      Reserved_210     : A0B.Types.Reserved_8;
      Reserved_211     : A0B.Types.Reserved_8;
      Reserved_212     : A0B.Types.Reserved_8;
      Reserved_213     : A0B.Types.Reserved_8;
      Reserved_214     : A0B.Types.Reserved_8;
      Reserved_215     : A0B.Types.Reserved_8;
      Reserved_216     : A0B.Types.Reserved_8;
      Reserved_217     : A0B.Types.Reserved_8;
      Reserved_218     : A0B.Types.Reserved_8;
      Reserved_219     : A0B.Types.Reserved_8;
      Reserved_220     : A0B.Types.Reserved_8;
      Reserved_221     : A0B.Types.Reserved_8;
      Reserved_222     : A0B.Types.Reserved_8;
      Reserved_223     : A0B.Types.Reserved_8;
      FR               : A0B.Types.Unsigned_8;
      XON0AB           : Boolean;
      XON0CD           : Boolean;
      XON1AB           : Boolean;
      XON1CD           : Boolean;
      XON2AB           : Boolean;
      XON2CD           : Boolean;
      XON3AB           : Boolean;
      XON3CD           : Boolean;
      XON4AB           : Boolean;
      XON4CD           : Boolean;
      XON5AB           : Boolean;
      XON5CD           : Boolean;
      Reserved_226_7_4 : A0B.Types.Reserved_4;
   end record with Size => Waveform_LUT_2C_Length * 8;

   for Waveform_LUT_2C use record
      LUTC             at   0 range 0 .. 335;
      LUTWW            at  42 range 0 .. 335;
      LUTBW            at  84 range 0 .. 335;
      LUTWB            at 126 range 0 .. 335;
      LUTBB            at 168 range 0 .. 335;
      Reserved_210     at 210 range 0 .. 7;
      Reserved_211     at 211 range 0 .. 7;
      Reserved_212     at 212 range 0 .. 7;
      Reserved_213     at 213 range 0 .. 7;
      Reserved_214     at 214 range 0 .. 7;
      Reserved_215     at 215 range 0 .. 7;
      Reserved_216     at 216 range 0 .. 7;
      Reserved_217     at 217 range 0 .. 7;
      Reserved_218     at 218 range 0 .. 7;
      Reserved_219     at 219 range 0 .. 7;
      Reserved_220     at 220 range 0 .. 7;
      Reserved_221     at 221 range 0 .. 7;
      Reserved_222     at 222 range 0 .. 7;
      Reserved_223     at 223 range 0 .. 7;
      FR               at 224 range 0 .. 7;
      XON0AB           at 225 range 0 .. 0;
      XON0CD           at 225 range 1 .. 1;
      XON1AB           at 225 range 2 .. 2;
      XON1CD           at 225 range 3 .. 3;
      XON2AB           at 225 range 4 .. 4;
      XON2CD           at 225 range 5 .. 5;
      XON3AB           at 225 range 6 .. 6;
      XON3CD           at 225 range 7 .. 7;
      XON4AB           at 226 range 0 .. 0;
      XON4CD           at 226 range 1 .. 1;
      XON5AB           at 226 range 2 .. 2;
      XON5CD           at 226 range 3 .. 3;
      Reserved_226_7_4 at 226 range 4 .. 7;
   end record;

   type Waveform_Setting_2C is record
      LUT              : Waveform_LUT_2C;
      EOPT             : A0B.Types.Unsigned_8;
      VGH              : A0B.Types.Unsigned_8;
      VSH1             : A0B.Types.Unsigned_8;
      VSH2             : A0B.Types.Unsigned_8;
      VSL              : A0B.Types.Unsigned_8;
      VCOM             : A0B.Types.Unsigned_8;
   end record with Size => 8 * Waveform_Setting_2C_Length;
   --  SSD1683 Rev 1.0, Figure 6-7. Bytes
   --   *   0 .. 226  belong to register 0x32;
   --   *     227     EOPT, belong to register 0x3F;
   --   *     228     VGH, belongs to register 0x03;
   --   * 229 .. 231  VSH1/VSH2/VSL, belongs to register 0x04;
   --   *     232     VCOM, belongs to register 0x2C.

   for Waveform_Setting_2C use record
      LUT              at   0 range 0 .. 1815;
      EOPT             at 227 range 0 .. 7;
      VGH              at 228 range 0 .. 7;
      VSH1             at 229 range 0 .. 7;
      VSH2             at 230 range 0 .. 7;
      VSL              at 231 range 0 .. 7;
      VCOM             at 232 range 0 .. 7;
   end record;

   type Waveform_Temperature_Range is record
      Temp_Low  : A0B.Types.Integer_8;
      Temp_High : A0B.Types.Integer_8;
   end record with Size => Waveform_Temperature_Range_Length * 8;
   --  The matching interval is `Temp_Low` < temperature <= `Temp_High`.

   for Waveform_Temperature_Range use record
      Temp_Low  at 0 range 0 .. 7;
      Temp_High at 1 range 0 .. 7;
   end record;

   type Waveform_Setting_Index is range 0 .. 23;

   type Waveform_Setting_2C_Array is
     array (Waveform_Setting_Index) of Waveform_Setting_2C
       with Component_Size => Waveform_Setting_2C_Length * 8,
            Size           => Waveform_Setting_2C_Array_Length * 8;

   type Waveform_Temperature_Range_Array is
     array (Waveform_Setting_Index) of Waveform_Temperature_Range
       with Component_Size => Waveform_Temperature_Range_Length * 8,
            Size           => Waveform_Temperature_Range_Array_Length * 8;

   type Waveform_Setting_2C_Mapping is record
      WS : Waveform_Setting_2C_Array;
      TR : Waveform_Temperature_Range_Array;
   end record with Size => Waveform_Setting_2C_Mapping_Length * 8;

   for Waveform_Setting_2C_Mapping use record
      WS at 0     range 0 .. 44_735;
      TR at 5_592 range 0 .. 383;
   end record;

   function Get_Display_Option_Registers
     (Item : OTP_Display_Option_Registers) return Display_Option_Registers;

   procedure Initialize;

   procedure Reset (Callback : A0B.Callbacks.Callback);
   --  Do hardware reset and software reset of the panel.

   procedure Write_RAM_Black_White
     (Data     : A0B.Buffers.Abstract_Buffer'Class;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Write given data to BW RAM

   procedure Auto_Write_BW_RAM_For_Regular_Pattern
     (Value    : A0B.Types.Unsigned_1;
      Width    : Width_Pattern_Step;
      Height   : Height_Pattern_Step;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Auto Write BW RAM for Regular Pattern

   procedure Write_RAM_Red
     (Data     : A0B.Buffers.Abstract_Buffer'Class;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Write given data to RED RAM

   procedure Auto_Write_RED_RAM_For_Regular_Pattern
     (Value    : A0B.Types.Unsigned_1;
      Width    : Width_Pattern_Step;
      Height   : Height_Pattern_Step;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Auto Write RED RAM for Regular Pattern

   procedure Display_Update_Control_1
     (BW_RAM   : RAM_Content;
      RED_RAM  : RAM_Content;
      Cascade  : Boolean;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Sets RAM content option for Display Update

   procedure Display_Update_Control_2
     (Sequence : Update_Sequence;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Sets display update sequence.

   procedure Master_Activation
     (Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Activate Display Update Sequence

   procedure Temperature_Sensor_Control
     (Sensor   : Temperature_Sensor;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Temperature Sensor Selection

   procedure Booster_Soft_Start_Control
     (B1       : A0B.Types.Unsigned_8;
      B2       : A0B.Types.Unsigned_8;
      B3       : A0B.Types.Unsigned_8;
      B4       : A0B.Types.Unsigned_8;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Booster Enable with Phase 1, Phase 2 and Phase 3 for soft start current
   --  and duration setting.
   --
   --  XXX It is raw version, should be replaced by typed interface.

   procedure Data_Entry_Mode_Setting
     (X_Axis   : Address_Direction;
      Y_Axis   : Address_Direction;
      Primary  : Direction;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Define data entry sequence.

   procedure Set_RAM_X_Address_Counter
     (X        : A0B.Types.Unsigned_6;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Set the RAM X address counter in byte address units.

   procedure Set_RAM_X_Address_Start_End_Position
     (X_Start  : A0B.Types.Unsigned_6;
      X_End    : A0B.Types.Unsigned_6;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Specify the start/end positions of the window address in the X direction
   --  by an address unit for RAM.

   procedure Set_RAM_Y_Address_Counter
     (Y        : A0B.Types.Unsigned_9;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Set the RAM Y address counter in row address units.

   procedure Set_RAM_Y_Address_Start_End_Position
     (Y_Start  : A0B.Types.Unsigned_9;
      Y_End    : A0B.Types.Unsigned_9;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Specify the start/end positions of the window address in the Y direction
   --  by an address unit for RAM.

   procedure Read_RAM
     (Data     : in out A0B.Buffers.Abstract_Buffer'Class;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Read data from RAM, selected by `Read_RAM_Option`
   --
   --  Note, first dummy byte is ignored. Size of the data to be received
   --  should be by `Set_Allocation_Length`, or full buffer be filled.

   procedure Read_RAM_Option
     (Bank     : RAM_Bank;
      CRC_Mode : CRC_Check_Mode;
      Count    : A0B.Types.Unsigned_16;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Read RAM Option.

   procedure OTP_Read_Display_Option
     (Options  : aliased out OTP_Display_Option_Registers;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Read Register for Display Option.

   procedure Write_Display_Option
     (Options  : Display_Option_Registers;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Write Register for Display Option.

   procedure Load_WS_OTP
     (Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Load OTP of Waveform Setting. Clocks must be enabled by Display Update
   --  Control 2 command.

   procedure Write_LUT_Register
     (LUT      : aliased Waveform_LUT_2C;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Write LUT register from MCU interface [227 bytes], which contains the
   --  content of VS[nX-LUTm], TP[nX], RP[n], SR[nXY], FR and XON[nXY].

end Nu_Pogodi.Hardware.SSD1683;
