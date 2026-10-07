--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.ARMv7M.Instructions;
with A0B.Awaits;
with A0B.Callbacks.Generic_Parameterless;
with A0B.Time.Clock;
with A0B.Timer;
with A0B.Buffers.Static;
with A0B.Types.Arrays;

with Nu_Pogodi.Bitmaps;
with Nu_Pogodi.Display;
with Nu_Pogodi.Hardware.SSD1683.Synchronous;
with Nu_Pogodi.Scene.Drawing;

package body Nu_Pogodi.Application is

   use type A0B.Time.Monotonic_Time;

   Tick_Duration : constant A0B.Time.Duration := 0.031_25;
   --  Duration of physics update tick, running @32Hz

   procedure On_Display_Updated;

   package On_Display_Updated_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Display_Updated);

   procedure Delay_Until (Time : A0B.Time.Monotonic_Time);

   procedure Full_Clean;

   procedure Partial
     (Active_Buffer : in out A0B.Buffers.Abstract_Buffer'Class;
      Backup_Buffer : in out A0B.Buffers.Abstract_Buffer'Class;
      Success       : in out Boolean);

   subtype Pixbuf is A0B.Buffers.Static.Static_Buffer (15_000);

   Pixel_Buffer :
     array (Natural range 0 .. 1) of Pixbuf;

   type Span_Record is record
      Start   : A0B.Time.Monotonic_Time;
      Release : A0B.Time.Duration;
      Update  : A0B.Time.Duration;
   end record;

   Span  : array (Natural range 0 .. 10) of Span_Record with Volatile;
   Cycle : Natural := 0;

   -----------------
   -- Delay_Until --
   -----------------

   procedure Delay_Until (Time : A0B.Time.Monotonic_Time) is
      Timeout : aliased A0B.Timer.Timeout_Control_Block;
      Await   : aliased A0B.Awaits.Await;
      Success : Boolean := True;

   begin
      A0B.Timer.Enqueue (Timeout, A0B.Awaits.Create_Callback (Await), Time);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
   end Delay_Until;

   ----------------
   -- Full_Clean --
   ----------------

   procedure Full_Clean is
      Success : Boolean := True;

   begin
      Span (Cycle).Start := A0B.Time.Clock;

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Display_Update_Control_1
        (BW_RAM  => Nu_Pogodi.Hardware.SSD1683.Normal,
         RED_RAM => Nu_Pogodi.Hardware.SSD1683.Bypass,
         Cascade => False,
         Success => Success);

      Nu_Pogodi.Hardware.SSD1683.Synchronous
        .Auto_Write_BW_RAM_For_Regular_Pattern
          (1,
           Nu_Pogodi.Hardware.SSD1683.Width_Full,
           Nu_Pogodi.Hardware.SSD1683.Height_Full,
           Success);

      declare
         Data : A0B.Types.Arrays.Unsigned_8_Array (1 .. 15_000)
           with Import, Address => Pixel_Buffer (0).Address;

      begin
         Data := [others => 16#FF#];
         Pixel_Buffer (0).Set_Actual_Length (15_000);
      end;

      Span (Cycle).Release :=
        A0B.Time.To_Duration (A0B.Time.Clock - Span (Cycle).Start);

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Display_Update_Control_2
        ((Enable_Clock      => True,
          Enable_Analog     => True,
          Load_Temperature  => True,
          Loat_LUT_From_OTP => True,
          Update_Mode       => False,
          Update_Display    => True,
          Disable_Analog    => True,
          Disable_Clock     => True),
         Success);
      Nu_Pogodi.Hardware.SSD1683.Synchronous.Master_Activation (Success);

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Display_Update_Control_1
        (BW_RAM  => Nu_Pogodi.Hardware.SSD1683.Normal,
         RED_RAM => Nu_Pogodi.Hardware.SSD1683.Normal,
         Cascade => False,
         Success => Success);

      Span (Cycle).Update :=
        A0B.Time.To_Duration (A0B.Time.Clock - Span (Cycle).Start);
      Cycle := @ + 1;

      if not Success then
         raise Program_Error;
      end if;
   end Full_Clean;

   ------------------------
   -- On_Display_Updated --
   ------------------------

   procedure On_Display_Updated is
   begin
      Span (Cycle).Update :=
        A0B.Time.To_Duration (A0B.Time.Clock - Span (Cycle).Start);
      Cycle := @ + 1;
   end On_Display_Updated;

   -------------
   -- Partial --
   -------------

   procedure Partial
     (Active_Buffer : in out A0B.Buffers.Abstract_Buffer'Class;
      Backup_Buffer : in out A0B.Buffers.Abstract_Buffer'Class;
      Success       : in out Boolean)
   is
      Data  : A0B.Types.Arrays.Unsigned_8_Array (1 .. 15_000)
        with Import, Address => Active_Buffer.Address;

   begin
      Span (Cycle).Start := A0B.Time.Clock;

      declare
         FB : Nu_Pogodi.Bitmaps.Framebuffer
           with Import, Address => Data'Address;

      begin
         Data := [others => 16#FF#];
         Nu_Pogodi.Scene.Drawing.Draw (FB);
      end;

      Active_Buffer.Set_Actual_Length (15_000);

      Nu_Pogodi.Display.Update
        (Active_Buffer,
         Backup_Buffer,
         On_Display_Updated_Callbacks.Create_Callback,
         Success);

      Span (Cycle).Release :=
        A0B.Time.To_Duration (A0B.Time.Clock - Span (Cycle).Start);
   end Partial;

   ---------
   -- Run --
   ---------

   procedure Run is
      Next    : A0B.Time.Monotonic_Time;
      Refresh : Boolean;
      Success : Boolean := True;

   begin
      Nu_Pogodi.Hardware.SSD1683.Synchronous.Reset (Success);

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Data_Entry_Mode_Setting
        (Nu_Pogodi.Hardware.SSD1683.Increment,
         Nu_Pogodi.Hardware.SSD1683.Increment,
         Nu_Pogodi.Hardware.SSD1683.X_Axis,
         Success);
      Nu_Pogodi.Hardware.SSD1683.Synchronous
        .Set_RAM_X_Address_Start_End_Position (0, 49, Success);
      --  0 .. 400 / 8 - 1
      Nu_Pogodi.Hardware.SSD1683.Synchronous
        .Set_RAM_Y_Address_Start_End_Position (0, 299, Success);

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Temperature_Sensor_Control
        (Nu_Pogodi.Hardware.SSD1683.Internal, Success);

      Full_Clean;

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Display_Update_Control_2
        ((Enable_Clock      => True,
          Enable_Analog     => True,
          Load_Temperature  => True,
          Loat_LUT_From_OTP => True,
          Update_Mode       => True,
          Update_Display    => False,
          Disable_Analog    => False,
          Disable_Clock     => False),
         Success);
      Nu_Pogodi.Hardware.SSD1683.Synchronous.Master_Activation (Success);
      --  Enable clock, analog, load temperature and load LUT for partial
      --  update mode. Don't disable analog and clock at the end of the
      --  sequence.
      --
      --  Execution of the sequence allows to cache some of internal parameters
      --  and use them, instead of rebuild them by each partial update command.
      --  It save significant amount of time on each update, thus improve
      --  refresh rate (single optimized partial update takes about 0.277
      --  second instead of non optimized 0.450 second).

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Display_Update_Control_2
        ((Enable_Clock      => False,
          Enable_Analog     => False,
          Load_Temperature  => False,
          Loat_LUT_From_OTP => False,
          Update_Mode       => True,
          Update_Display    => True,
          Disable_Analog    => False,
          Disable_Clock     => False),
         Success);
      --  Set partial update mode once, to exclude command's transfer time from
      --  critical path.

      Nu_Pogodi.Scene.Initialize (Nu_Pogodi.Scene.Mode_A);

      Next := A0B.Time.Clock;

      loop
         exit when Cycle > Span'Last;

         Nu_Pogodi.Scene.Update_Physics_Tick (Refresh);

         if Refresh then
            Partial
              (Pixel_Buffer (Cycle mod 2),
               Pixel_Buffer ((Cycle - 1) mod 2),
               Success);
         end if;

         Next := @ + Tick_Duration;
         Delay_Until (Next);
      end loop;

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Display_Update_Control_2
        ((Enable_Clock      => True,
          Enable_Analog     => True,
          Load_Temperature  => False,
          Loat_LUT_From_OTP => False,
          Update_Mode       => False,
          Update_Display    => False,
          Disable_Analog    => True,
          Disable_Clock     => True),
         Success);
      Nu_Pogodi.Hardware.SSD1683.Synchronous.Master_Activation (Success);

      if Success then
         raise Program_Error;
      end if;

      loop
         A0B.ARMv7M.Instructions.Wait_For_Interrupt;
      end loop;
   end Run;

end Nu_Pogodi.Application;
