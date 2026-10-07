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
with Nu_Pogodi.Clock;
with Nu_Pogodi.Display;
with Nu_Pogodi.Hardware.RTC;
with Nu_Pogodi.Hardware.SSD1683.Synchronous;
with Nu_Pogodi.Scene.Drawing;

package body Nu_Pogodi.Application is

   use type A0B.Time.Monotonic_Time;

   Tick_Duration : constant A0B.Time.Duration := 0.031_25;
   --  Duration of physics update tick, running @32Hz

   procedure On_Display_Updated;

   package On_Display_Updated_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Display_Updated);

   procedure On_Wakeup;

   package On_Wakeup_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Wakeup);

   procedure Delay_Until (Time : A0B.Time.Monotonic_Time);

   procedure Full_Clean;

   procedure Partial
     (Active_Buffer : in out A0B.Buffers.Abstract_Buffer'Class;
      Backup_Buffer : in out A0B.Buffers.Abstract_Buffer'Class;
      Success       : in out Boolean);

   subtype Pixbuf is A0B.Buffers.Static.Static_Buffer (15_000);

   Pixel_Buffer : array (Natural range 0 .. 1) of Pixbuf;
   Cycle        : Natural := 0;
   Wakeup       : Boolean := False with Volatile;

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
      --  Clear panel to white color. Implementation minimize unnecessary data
      --  transfers and utilize display controller's features:
      --   * content of RED RAM are fixed to all zeros
      --   * content of BW RAM is filled by ones

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

      --  Revert to normal use of both RAM, fill RED RAM to match an "empty"
      --  content on the panel, and fill back buffer in MCU memory.

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Display_Update_Control_1
        (BW_RAM  => Nu_Pogodi.Hardware.SSD1683.Normal,
         RED_RAM => Nu_Pogodi.Hardware.SSD1683.Normal,
         Cascade => False,
         Success => Success);

      Nu_Pogodi.Hardware.SSD1683.Synchronous
        .Auto_Write_RED_RAM_For_Regular_Pattern
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
      Cycle := @ + 1;
   end On_Display_Updated;

   ---------------
   -- On_Wakeup --
   ---------------

   procedure On_Wakeup is
   begin
      Wakeup := True;
   end On_Wakeup;

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
      declare
         FB : Nu_Pogodi.Bitmaps.Framebuffer
           with Import, Address => Data'Address;

      begin
         Data := [others => 16#FF#];
         Nu_Pogodi.Scene.Drawing.Draw (FB);
         Nu_Pogodi.Clock.Draw (Active_Buffer);
      end;

      Active_Buffer.Set_Actual_Length (15_000);

      Nu_Pogodi.Display.Update
        (Active_Buffer,
         Backup_Buffer,
         On_Display_Updated_Callbacks.Create_Callback,
         Success);
   end Partial;

   -------------------
   -- Partial_Clock --
   -------------------

   procedure Partial_Clock
     (Active_Buffer : in out A0B.Buffers.Abstract_Buffer'Class;
      Backup_Buffer : in out A0B.Buffers.Abstract_Buffer'Class;
      Success       : in out Boolean)
   is
      Data  : A0B.Types.Arrays.Unsigned_8_Array (1 .. 15_000)
        with Import, Address => Active_Buffer.Address;

   begin
      declare
         FB : Nu_Pogodi.Bitmaps.Framebuffer
           with Import, Address => Data'Address;

      begin
         Data := [others => 16#FF#];
         Nu_Pogodi.Scene.Drawing.Draw (FB);
         Nu_Pogodi.Clock.Draw (Active_Buffer);
      end;

      Active_Buffer.Set_Actual_Length (15_000);

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Write_RAM_Black_White
        (Active_Buffer, Success);
      Nu_Pogodi.Hardware.SSD1683.Synchronous.Write_RAM_Red
        (Backup_Buffer, Success);
      Nu_Pogodi.Hardware.SSD1683.Synchronous.Display_Update_Control_2
        ((Enable_Clock      => True,
          Enable_Analog     => True,
          Load_Temperature  => True,
          Loat_LUT_From_OTP => True,
          Update_Mode       => True,
          Update_Display    => True,
          Disable_Analog    => True,
          Disable_Clock     => True),
         Success);
      Nu_Pogodi.Hardware.SSD1683.Synchronous.Master_Activation
        (Success);

      Cycle := @ + 1;
   end Partial_Clock;

   ---------
   -- Run --
   ---------

   procedure Run is
      Next    : A0B.Time.Monotonic_Time;
      Refresh : Boolean;
      Success : Boolean := True;

   begin
      Nu_Pogodi.Hardware.RTC.Set_Wakeup (On_Wakeup_Callbacks.Create_Callback);

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
         exit when Nu_Pogodi.Scene.Is_Game_Over;

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

      loop
         A0B.ARMv7M.Instructions.Wait_For_Interrupt;

         if Wakeup then
            Wakeup := False;

            Partial_Clock
              (Pixel_Buffer (Cycle mod 2),
               Pixel_Buffer ((Cycle - 1) mod 2),
               Success);
         end if;
      end loop;
   end Run;

end Nu_Pogodi.Application;
