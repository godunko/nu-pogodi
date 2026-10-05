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

   procedure Write_RAM_Red
     (Data    : A0B.Buffers.Abstract_Buffer'Class;
      Success : in out Boolean);
   --  Write given data to RED RAM

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

end Nu_Pogodi.Hardware.SSD1683.Synchronous;
