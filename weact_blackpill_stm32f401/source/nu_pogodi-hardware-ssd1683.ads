--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

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

   procedure Initialize;

   procedure Reset (Callback : A0B.Callbacks.Callback);
   --  Do hardware reset and software reset of the panel.

   procedure Write_RAM_Black_White
     (Data     : A0B.Buffers.Abstract_Buffer'Class;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Write given data to BW RAM

   procedure Write_RAM_Red
     (Data     : A0B.Buffers.Abstract_Buffer'Class;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Write given data to RED RAM

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

   procedure Set_RAM_X_Address_Start_End_Position
     (X_Start  : A0B.Types.Unsigned_6;
      X_End    : A0B.Types.Unsigned_6;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Specify the start/end positions of the window address in the X direction
   --  by an address unit for RAM.

   procedure Set_RAM_Y_Address_Start_End_Position
     (Y_Start  : A0B.Types.Unsigned_9;
      Y_End    : A0B.Types.Unsigned_9;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean);
   --  Specify the start/end positions of the window address in the Y direction
   --  by an address unit for RAM.

end Nu_Pogodi.Hardware.SSD1683;
