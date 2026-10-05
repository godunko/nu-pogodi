--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.ARMv7M.Instructions;
with A0B.Time.Clock;
with A0B.Buffers.Static;
--  with A0B.Callbacks.Generic_Parameterless;
with A0B.Types.Arrays;

with Nu_Pogodi.Bitmaps;
with Nu_Pogodi.Hardware.SSD1683.Synchronous;
with Nu_Pogodi.Scene.Draw;

package body Nu_Pogodi.Application is

   use type A0B.Time.Monotonic_Time;

   --  procedure On_SSD1683_Reset;
   --
   --  package On_SSD1683_Reset_Callbacks is
   --    new A0B.Callbacks.Generic_Parameterless (On_SSD1683_Reset);

   --  procedure On_Write_BW;
   --
   --  package On_Write_BW_Callbacks is
   --    new A0B.Callbacks.Generic_Parameterless (On_Write_BW);

   --  procedure On_Write_Red;

   --  package On_Write_Red_Callbacks is
   --    new A0B.Callbacks.Generic_Parameterless (On_Write_Red);

   --  procedure On_DUC2;

   --  package On_DUC2_Callbacks is
   --    new A0B.Callbacks.Generic_Parameterless (On_DUC2);

   --  procedure On_MA;

   --  package On_MA_Callbacks is
   --    new A0B.Callbacks.Generic_Parameterless (On_MA);

   procedure Full_Clean;

   procedure Partial
     (Active_Buffer : in out A0B.Buffers.Abstract_Buffer'Class;
      Backup_Buffer : in out A0B.Buffers.Abstract_Buffer'Class;
      Success       : in out Boolean);

   subtype Pixbuf is A0B.Buffers.Static.Static_Buffer (15_000);

   Pixel_Buffer :
     array (Natural range 0 .. 1) of Pixbuf;

   type Span_Record is record
      Upload : A0B.Time.Duration;
      Update : A0B.Time.Duration;
   end record;

   Span  : array (Natural range 0 .. 10) of Span_Record with Volatile;
   Cycle : Natural := 0;

   ----------------------
   -- On_SSD1683_Reset --
   ----------------------

   --  procedure On_SSD1683_Reset is
   --     Success : Boolean := True;
   --
   --  begin
   --     declare
   --        Data : A0B.Types.Arrays.Unsigned_8_Array (1 .. 15_000)
   --          with Import, Address => Pixel_Buffer.Address;
   --
   --     begin
   --        Data := [others => 16#FF#];
   --        Pixel_Buffer.Set_Actual_Length (15_000);
   --     end;
   --
   --     Nu_Pogodi.Hardware.SSD1683.Write_RAM_Black_White
   --       (Pixel_Buffer,
   --        On_Write_BW_Callbacks.Create_Callback,
   --        Success);
   --
   --     if not Success then
   --        raise Program_Error;
   --     end if;
   --  end On_SSD1683_Reset;

   -----------------
   -- On_Write_BW --
   -----------------

   --  procedure On_Write_BW is
   --     Success : Boolean := True;
   --
   --  begin
   --     declare
   --        Data : A0B.Types.Arrays.Unsigned_8_Array (1 .. 15_000)
   --          with Import, Address => Pixel_Buffer.Address;
   --
   --     begin
   --        Data := [others => 16#00#];
   --        Pixel_Buffer.Set_Actual_Length (15_000);
   --     end;
   --
   --     Nu_Pogodi.Hardware.SSD1683.Write_RAM_Red
   --       (Pixel_Buffer,
   --        On_Write_Red_Callbacks.Create_Callback,
   --        Success);
   --
   --     if not Success then
   --        raise Program_Error;
   --     end if;
   --  end On_Write_BW;

   ------------------
   -- On_Write_Red --
   ------------------

   --  procedure On_Write_Red is
   --     Success : Boolean := True;
   --
   --  begin
   --     Nu_Pogodi.Hardware.SSD1683.Display_Update_Control_2
   --       ((Enable_Clock      => True,
   --         Enable_Analog     => True,
   --         Load_Temperature  => True,
   --         Loat_LUT_From_OTP => True,
   --         Update_Mode       => False,
   --         Update_Display    => True,
   --         Disable_Analog    => True,
   --         Disable_Clock     => True),
   --        On_DUC2_Callbacks.Create_Callback,
   --        Success);
   --
   --     if not Success then
   --        raise Program_Error;
   --     end if;
   --  end On_Write_Red;

   -------------
   -- On_DUC2 --
   -------------

   --  procedure On_DUC2 is
   --     Success : Boolean := True;
   --
   --  begin
   --     Nu_Pogodi.Hardware.SSD1683.Master_Activation
   --       (On_MA_Callbacks.Create_Callback, Success);
   --
   --     if not Success then
   --        raise Program_Error;
   --     end if;
   --  end On_DUC2;

   -----------
   -- On_MA --
   -----------

   --  procedure On_MA is
   --  begin
   --     raise Program_Error;
   --  end On_MA;

   ----------------
   -- Full_Clean --
   ----------------

   procedure Full_Clean is
      Start   : constant A0B.Time.Monotonic_Time := A0B.Time.Clock;
      Success : Boolean := True;

   begin
      declare
         Data : A0B.Types.Arrays.Unsigned_8_Array (1 .. 15_000)
           with Import, Address => Pixel_Buffer (0).Address;

      begin
         Data := [others => 16#FF#];
         Pixel_Buffer (0).Set_Actual_Length (15_000);

         Nu_Pogodi.Hardware.SSD1683.Synchronous.Write_RAM_Black_White
           (Pixel_Buffer (0), Success);
      end;

      declare
         Data : A0B.Types.Arrays.Unsigned_8_Array (1 .. 15_000)
           with Import, Address => Pixel_Buffer (1).Address;

      begin
         Data := [others => 16#00#];
         Pixel_Buffer (1).Set_Actual_Length (15_000);

         Nu_Pogodi.Hardware.SSD1683.Synchronous.Write_RAM_Red
           (Pixel_Buffer (1), Success);
      end;

      Span (Cycle).Upload := A0B.Time.To_Duration (A0B.Time.Clock - Start);

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

      Span (Cycle).Update := A0B.Time.To_Duration (A0B.Time.Clock - Start);
      Cycle := @ + 1;

      if not Success then
         raise Program_Error;
      end if;
   end Full_Clean;

   -------------
   -- Partial --
   -------------

   procedure Partial
     (Active_Buffer : in out A0B.Buffers.Abstract_Buffer'Class;
      Backup_Buffer : in out A0B.Buffers.Abstract_Buffer'Class;
      Success       : in out Boolean)
   is
      Start : constant A0B.Time.Monotonic_Time := A0B.Time.Clock;
      Data  : A0B.Types.Arrays.Unsigned_8_Array (1 .. 15_000)
        with Import, Address => Active_Buffer.Address;

   begin
      declare
         FB : Nu_Pogodi.Bitmaps.Framebuffer
           with Import, Address => Data'Address;

      begin
         Data := [others => 16#FF#];
         Nu_Pogodi.Scene.Draw (FB);
      end;

      Active_Buffer.Set_Actual_Length (15_000);

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Write_RAM_Black_White
        (Active_Buffer, Success);

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Write_RAM_Red
        (Backup_Buffer, Success);

      Span (Cycle).Upload := A0B.Time.To_Duration (A0B.Time.Clock - Start);

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Master_Activation (Success);

      Span (Cycle).Update := A0B.Time.To_Duration (A0B.Time.Clock - Start);
      Cycle := @ + 1;
   end Partial;

   ---------
   -- Run --
   ---------

   procedure Run is
      Success : Boolean := True;

   begin
      --  Nu_Pogodi.Hardware.SSD1683.Reset
      --    (On_SSD1683_Reset_Callbacks.Create_Callback);

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

      loop
         exit when Cycle > Span'Last;

         Nu_Pogodi.Scene.Update_Physics_Tick;
         Partial
           (Pixel_Buffer (Cycle mod 2),
            Pixel_Buffer ((Cycle - 1) mod 2),
            Success);
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
