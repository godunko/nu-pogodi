
with Ada.Text_IO; use Ada.Text_IO;

with A0B.Awaits;
with A0B.ESPIDF_Timer_Clock_Timer;
with A0B.Timer;

with Nu_Pogodi.Hardware.Pin_Control;
with Nu_Pogodi.Hardware.SSD1683.Synchronous;

procedure Main is
   Timer   : aliased A0B.Timer.Timeout_Control_Block;
   Await   : aliased A0B.Awaits.Await;
   Success : Boolean := True;

begin
   A0B.ESPIDF_Timer_Clock_Timer.Initialize;

   Nu_Pogodi.Hardware.Pin_Control.Initialize;
   Nu_Pogodi.Hardware.SSD1683.Initialize;

   Put_Line ("Hello, Ada world! Nu Pogodi on ESP32-S3.");

   --  Nu_Pogodi.Hardware.SSD1683.Reset (A0B.Awaits.Create_Callback (Await));
   --  A0B.Awaits.Suspend_Until_Callback (Await, Success);

   Nu_Pogodi.Hardware.SSD1683.Synchronous.Reset (Success);
   Nu_Pogodi.Hardware.SSD1683.Synchronous.Display_Update_Control_1
     (BW_RAM  => Nu_Pogodi.Hardware.SSD1683.Normal,
      RED_RAM => Nu_Pogodi.Hardware.SSD1683.Bypass,
      Cascade => False,
      Success => Success);
   Nu_Pogodi.Hardware.SSD1683.Synchronous.Auto_Write_BW_RAM_For_Regular_Pattern
     (Value   => 1,
      Width   => Nu_Pogodi.Hardware.SSD1683.Width_Full,
      Height  => Nu_Pogodi.Hardware.SSD1683.Height_Full,
      Success => Success);
   Nu_Pogodi.Hardware.SSD1683.Synchronous.Master_Activation (Success);

   Put_Line ("Timer started.");

   A0B.Timer.Enqueue
     (Timer, A0B.Awaits.Create_Callback (Await), 1.0);
   A0B.Awaits.Suspend_Until_Callback (Await, Success);

   Put_Line ("Timer completed.");
end Main;
