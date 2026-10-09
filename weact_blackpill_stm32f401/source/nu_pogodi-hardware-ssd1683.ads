--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

--  Driver of the SSD1683 display driver controller.
--
--  Note: it is expected that framebuffer data use LSB-first format (the
--  leftmost pixel maps to the least significant bit. It is most efficient
--  format for pixel processing by MCU.
--
--  Implementation note: SSD1683 accepts bytes in MSB format; underlying SPI is
--  configured to use LSB transfer mode, and driver do conversion of bit order
--  for commands and their parameters.

with A0B.Buffers;
with A0B.Callbacks;
with A0B.Types.Arrays;

package Nu_Pogodi.Hardware.SSD1683 is

   type Display_Option_Registers is
     new A0B.Types.Arrays.Unsigned_8_Array (1 .. 11);
   --  1: VCOM OTP selection
   --  2: VCOM register
   --  3..7: display mode
   --  8..11: waveform version

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

   procedure OTP_Register_Read_For_Display_Option
     (Data     : out Display_Option_Registers;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Read Register for Display Option.

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

end Nu_Pogodi.Hardware.SSD1683;
