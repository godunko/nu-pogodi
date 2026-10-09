--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Awaits;

package body Nu_Pogodi.Hardware.SSD1683.Synchronous is

   -------------------------------------------
   -- Auto_Write_BW_RAM_For_Regular_Pattern --
   -------------------------------------------

   procedure Auto_Write_BW_RAM_For_Regular_Pattern
     (Value    : A0B.Types.Unsigned_1;
      Width    : Width_Pattern_Step;
      Height   : Height_Pattern_Step;
      Success  : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Auto_Write_BW_RAM_For_Regular_Pattern
        (Value, Width, Height, A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Auto_Write_BW_RAM_For_Regular_Pattern;

   --------------------------------------------
   -- Auto_Write_RED_RAM_For_Regular_Pattern --
   --------------------------------------------

   procedure Auto_Write_RED_RAM_For_Regular_Pattern
     (Value    : A0B.Types.Unsigned_1;
      Width    : Width_Pattern_Step;
      Height   : Height_Pattern_Step;
      Success  : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Auto_Write_RED_RAM_For_Regular_Pattern
        (Value, Width, Height, A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Auto_Write_RED_RAM_For_Regular_Pattern;

   --------------------------------
   -- Booster_Soft_Start_Control --
   --------------------------------

   procedure Booster_Soft_Start_Control
     (B1      : A0B.Types.Unsigned_8;
      B2      : A0B.Types.Unsigned_8;
      B3      : A0B.Types.Unsigned_8;
      B4      : A0B.Types.Unsigned_8;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Booster_Soft_Start_Control
        (B1, B2, B3, B4, A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Booster_Soft_Start_Control;

   -----------------------------
   -- Data_Entry_Mode_Setting --
   -----------------------------

   procedure Data_Entry_Mode_Setting
     (X_Axis  : Address_Direction;
      Y_Axis  : Address_Direction;
      Primary : Direction;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Data_Entry_Mode_Setting
        (X_Axis, Y_Axis, Primary, A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Data_Entry_Mode_Setting;

   ------------------------------
   -- Display_Update_Control_1 --
   ------------------------------

   procedure Display_Update_Control_1
     (BW_RAM  : RAM_Content;
      RED_RAM : RAM_Content;
      Cascade : Boolean;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Display_Update_Control_1
        (BW_RAM   => BW_RAM,
         RED_RAM  => RED_RAM,
         Cascade  => Cascade,
         Callback => A0B.Awaits.Create_Callback (Await),
         Success  => Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Display_Update_Control_1;

   ------------------------------
   -- Display_Update_Control_2 --
   ------------------------------

   procedure Display_Update_Control_2
     (Sequence : Update_Sequence;
      Success  : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Display_Update_Control_2
        (Sequence, A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Display_Update_Control_2;

   -----------------------
   -- Master_Activation --
   -----------------------

   procedure Master_Activation (Success : in out Boolean) is
      Await : aliased A0B.Awaits.Await;

   begin
      Master_Activation (A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Master_Activation;

   -----------------------------
   -- OTP_Read_Display_Option --
   -----------------------------

   procedure OTP_Read_Display_Option
     (Options : aliased out OTP_Display_Option_Registers;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      OTP_Read_Display_Option
        (Options, A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end OTP_Read_Display_Option;

   --------------
   -- Read_RAM --
   --------------

   procedure Read_RAM
     (Data    : in out A0B.Buffers.Abstract_Buffer'Class;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Read_RAM (Data, A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Read_RAM;

   ---------------------
   -- Read_RAM_Option --
   ---------------------

   procedure Read_RAM_Option
     (Bank     : RAM_Bank;
      CRC_Mode : CRC_Check_Mode;
      Count    : A0B.Types.Unsigned_16;
      Success  : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Read_RAM_Option
        (Bank, CRC_Mode, Count, A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Read_RAM_Option;

   -----------
   -- Reset --
   -----------

   procedure Reset (Success : in out Boolean) is
      Await : aliased A0B.Awaits.Await;

   begin
      if not Success then
         return;
      end if;

      Reset (A0B.Awaits.Create_Callback (Await));
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Reset;

   -------------------------------
   -- Set_RAM_X_Address_Counter --
   -------------------------------

   procedure Set_RAM_X_Address_Counter
     (X       : A0B.Types.Unsigned_6;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Set_RAM_X_Address_Counter
        (X, A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Set_RAM_X_Address_Counter;

   ------------------------------------------
   -- Set_RAM_X_Address_Start_End_Position --
   ------------------------------------------

   procedure Set_RAM_X_Address_Start_End_Position
     (X_Start : A0B.Types.Unsigned_6;
      X_End   : A0B.Types.Unsigned_6;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Set_RAM_X_Address_Start_End_Position
        (X_Start, X_End, A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Set_RAM_X_Address_Start_End_Position;

   -------------------------------
   -- Set_RAM_Y_Address_Counter --
   -------------------------------

   procedure Set_RAM_Y_Address_Counter
     (Y       : A0B.Types.Unsigned_9;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Set_RAM_Y_Address_Counter
        (Y, A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Set_RAM_Y_Address_Counter;

   ------------------------------------------
   -- Set_RAM_Y_Address_Start_End_Position --
   ------------------------------------------

   procedure Set_RAM_Y_Address_Start_End_Position
     (Y_Start : A0B.Types.Unsigned_9;
      Y_End   : A0B.Types.Unsigned_9;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Set_RAM_Y_Address_Start_End_Position
        (Y_Start, Y_End, A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Set_RAM_Y_Address_Start_End_Position;

   --------------------------------
   -- Temperature_Sensor_Control --
   --------------------------------

   procedure Temperature_Sensor_Control
     (Sensor  : Temperature_Sensor;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      if not Success then
         return;
      end if;

      Temperature_Sensor_Control
        (Sensor, A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Temperature_Sensor_Control;

   --------------------------
   -- Write_Display_Option --
   --------------------------

   procedure Write_Display_Option
     (Options : Display_Option_Registers;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Write_Display_Option
        (Options, A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Write_Display_Option;

   ---------------------------
   -- Write_RAM_Black_White --
   ---------------------------

   procedure Write_RAM_Black_White
     (Data    : A0B.Buffers.Abstract_Buffer'Class;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Write_RAM_Black_White
        (Data, A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Write_RAM_Black_White;

   -------------------
   -- Write_RAM_Red --
   -------------------

   procedure Write_RAM_Red
     (Data    : A0B.Buffers.Abstract_Buffer'Class;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Write_RAM_Red
        (Data, A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Write_RAM_Red;

end Nu_Pogodi.Hardware.SSD1683.Synchronous;
