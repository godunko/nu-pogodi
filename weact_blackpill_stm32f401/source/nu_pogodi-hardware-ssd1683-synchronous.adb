--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Awaits;

package body Nu_Pogodi.Hardware.SSD1683.Synchronous is

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
