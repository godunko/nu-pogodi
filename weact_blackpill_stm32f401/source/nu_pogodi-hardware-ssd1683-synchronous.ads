--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

package Nu_Pogodi.Hardware.SSD1683.Synchronous is

   procedure Reset (Success : in out Boolean);
   --  Do hardware reset and software reset of the panel.

   procedure Write_RAM_Black_White
     (Data    : A0B.Buffers.Abstract_Buffer'Class;
      Success : in out Boolean);
   --  Write given data to BW RAM

   procedure Auto_Write_BW_RAM_For_Regular_Pattern
     (Value    : A0B.Types.Unsigned_1;
      Width    : Width_Pattern_Step;
      Height   : Height_Pattern_Step;
      Success  : in out Boolean);
   --  Auto Write BW RAM for Regular Pattern

   procedure Write_RAM_Red
     (Data    : A0B.Buffers.Abstract_Buffer'Class;
      Success : in out Boolean);
   --  Write given data to RED RAM

   procedure Auto_Write_RED_RAM_For_Regular_Pattern
     (Value    : A0B.Types.Unsigned_1;
      Width    : Width_Pattern_Step;
      Height   : Height_Pattern_Step;
      Success  : in out Boolean);
   --  Auto Write RED RAM for Regular Pattern

   procedure Display_Update_Control_1
     (BW_RAM  : RAM_Content;
      RED_RAM : RAM_Content;
      Cascade : Boolean;
      Success : in out Boolean);
   --  Sets RAM content option for Display Update

   procedure Display_Update_Control_2
     (Sequence : Update_Sequence;
      Success  : in out Boolean);
   --  Sets display update sequence.

   procedure Master_Activation
     (Success : in out Boolean);
   --  Activate Display Update Sequence

   procedure Temperature_Sensor_Control
     (Sensor  : Temperature_Sensor;
      Success : in out Boolean);
   --  Temperature Sensor Selection

   procedure Booster_Soft_Start_Control
     (B1      : A0B.Types.Unsigned_8;
      B2      : A0B.Types.Unsigned_8;
      B3      : A0B.Types.Unsigned_8;
      B4      : A0B.Types.Unsigned_8;
      Success : in out Boolean);
   --  Booster Enable with Phase 1, Phase 2 and Phase 3 for soft start current
   --  and duration setting.
   --
   --  XXX It is raw version, should be replaced by typed interface.

   procedure Data_Entry_Mode_Setting
     (X_Axis  : Address_Direction;
      Y_Axis  : Address_Direction;
      Primary : Direction;
      Success : in out Boolean);
   --  Define data entry sequence.

   procedure Set_RAM_X_Address_Counter
     (X       : A0B.Types.Unsigned_6;
      Success : in out Boolean);
   --  Set the RAM X address counter in byte address units.

   procedure Set_RAM_X_Address_Start_End_Position
     (X_Start : A0B.Types.Unsigned_6;
      X_End   : A0B.Types.Unsigned_6;
      Success : in out Boolean);
   --  Specify the start/end positions of the window address in the X direction
   --  by an address unit for RAM.

   procedure Set_RAM_Y_Address_Counter
     (Y       : A0B.Types.Unsigned_9;
      Success : in out Boolean);
   --  Set the RAM Y address counter in row address units.

   procedure Set_RAM_Y_Address_Start_End_Position
     (Y_Start : A0B.Types.Unsigned_9;
      Y_End   : A0B.Types.Unsigned_9;
      Success : in out Boolean);
   --  Specify the start/end positions of the window address in the Y direction
   --  by an address unit for RAM.

   procedure Read_RAM
     (Data    : in out A0B.Buffers.Abstract_Buffer'Class;
      Success : in out Boolean);
   --  Read data from RAM, selected by `Read_RAM_Option`
   --
   --  Note, first dummy byte is ignored. Size of the data to be received
   --  should be by `Set_Allocation_Length`, or full buffer be filled.

   procedure Read_RAM_Option
     (Bank     : RAM_Bank;
      CRC_Mode : CRC_Check_Mode;
      Count    : A0B.Types.Unsigned_16;
      Success  : in out Boolean);
   --  Read RAM Option.

end Nu_Pogodi.Hardware.SSD1683.Synchronous;
