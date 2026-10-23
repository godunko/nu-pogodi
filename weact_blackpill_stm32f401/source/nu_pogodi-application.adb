--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Awaits;
with A0B.Callbacks.Generic_Parameterless;
with A0B.Time.Clock;
with A0B.Timer;
with A0B.Buffers.Static;

with Nu_Pogodi.Display;
with Nu_Pogodi.Drawing;
with Nu_Pogodi.Framebuffers;
with Nu_Pogodi.Hardware.Keyboard;
with Nu_Pogodi.Hardware.RTC;
with Nu_Pogodi.Hardware.SSD1683.Synchronous;
with Nu_Pogodi.States.Clock;
with Nu_Pogodi.States.Game;

package body Nu_Pogodi.Application is

   use type A0B.Time.Monotonic_Time;

   Tick_Duration : constant A0B.Time.Duration := 0.025;
   --  Duration of physics update tick, running @40Hz. It means minimum game
   --  tick 0.200 seconds, and maximum game tick 0.800 seconds.

   procedure On_Display_Updated;

   package On_Display_Updated_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Display_Updated);

   procedure On_Wakeup;

   package On_Wakeup_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Wakeup);

   procedure On_Keyboard;

   package On_Keyboard_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Keyboard);

   procedure Delay_Until (Time : A0B.Time.Monotonic_Time);

   procedure Full_Clean;

   procedure Partial
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      Success     : in out Boolean);

   type State_Access is access all Nu_Pogodi.States.Abstract_State'Class;

   Mode         : Nu_Pogodi.Scene.Game_Mode := Nu_Pogodi.Scene.Mode_A;
   Game         : aliased Nu_Pogodi.States.Game.Game_State;
   Clock        : aliased Nu_Pogodi.States.Clock.Clock_State;
   Active       : State_Access := null;
   Requested    : State_Access := null;

   Display_Busy : Boolean := False with Volatile;
   Wakeup       : Boolean := False with Volatile;
   Keyboard     : Boolean := False with Volatile;

   Framebuffer_Storage : aliased A0B.Buffers.Static.Static_Buffer (15_000);
   Framebuffer         : Nu_Pogodi.Framebuffers.Framebuffer :=
     (Buffer => Framebuffer_Storage'Access,
      Width  => 400,
      Height => 300,
      Stride => 50);

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

   -----------------------
   -- Enter_Clock_State --
   -----------------------

   procedure Enter_Clock_State is
      Success : Boolean := True;

   begin
      Active := Clock'Access;

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
   end Enter_Clock_State;

   ----------------------
   -- Enter_Game_State --
   ----------------------

   procedure Enter_Game_State is
      Await   : aliased A0B.Awaits.Await;
      Success : Boolean := True;

   begin
      Active := Game'Access;

      Nu_Pogodi.Display.Write_Waveform_Setting_For_Fast_Partial_Update
        (A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      Nu_Pogodi.Hardware.SSD1683.Synchronous.Display_Update_Control_2
        ((Enable_Clock      => True,
          Enable_Analog     => True,
          Load_Temperature  => False,
          Loat_LUT_From_OTP => False,
          Update_Mode       => True,
          Update_Display    => False,
          Disable_Analog    => False,
          Disable_Clock     => False),
         Success);
      Nu_Pogodi.Hardware.SSD1683.Synchronous.Master_Activation (Success);
      --  Enable clock, analog, select partial update mode. Don't disable
      --  analog and clock at the end of the sequence.

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

      if not Success then
         raise Program_Error;
      end if;

      Scene.Initialize (Mode);
   end Enter_Game_State;

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

      Framebuffer_Storage.Set_Actual_Length (15_000);
      Nu_Pogodi.Drawing.Fill (Framebuffer);

      if not Success then
         raise Program_Error;
      end if;
   end Full_Clean;

   ------------------------
   -- On_Display_Updated --
   ------------------------

   procedure On_Display_Updated is
   begin
      Display_Busy := False;
   end On_Display_Updated;

   -----------------
   -- On_Keyboard --
   -----------------

   procedure On_Keyboard is
   begin
      Keyboard := True;
   end On_Keyboard;

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
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      Success     : in out Boolean) is
   begin
      Framebuffer.Buffer.Set_Actual_Length (15_000);

      Nu_Pogodi.Drawing.Fill (Framebuffer);
      Active.Render (Framebuffer);

      Display_Busy := True;
      Nu_Pogodi.Display.Update
        (Framebuffer.Buffer.all,
         On_Display_Updated_Callbacks.Create_Callback,
         Success);

      if not Success then
         Display_Busy := False;
      end if;
   end Partial;

   -------------------------
   -- Request_Clock_State --
   -------------------------

   procedure Request_Clock_State is
   begin
      Requested := Clock'Access;
   end Request_Clock_State;

   ------------------------
   -- Request_Game_State --
   ------------------------

   procedure Request_Game_State (Mode : Nu_Pogodi.Scene.Game_Mode) is
   begin
      Requested := Game'Access;
      Application.Mode := Mode;
   end Request_Game_State;

   ---------
   -- Run --
   ---------

   procedure Run is
      Await           : aliased A0B.Awaits.Await;
      Next            : A0B.Time.Monotonic_Time;
      Refresh_Pending : Boolean;
      Success         : Boolean := True;

   begin
      Nu_Pogodi.Hardware.Keyboard.Set_State_Changed
        (On_Keyboard_Callbacks.Create_Callback);
      Nu_Pogodi.Hardware.RTC.Set_Clock_Wakeup
        (On_Wakeup_Callbacks.Create_Callback);

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

      Nu_Pogodi.Display.Read_Factory_Waveforms
        (A0B.Awaits.Create_Callback (Await), Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      --  Check that automatic switching of RAM banks after partial update is
      --  enabled in the display option registers. Enable it if it is not.

      declare
         OTP_Options : aliased
           Nu_Pogodi.Hardware.SSD1683.OTP_Display_Option_Registers;
         Options     : Nu_Pogodi.Hardware.SSD1683.Display_Option_Registers;

      begin
         Nu_Pogodi.Hardware.SSD1683.Synchronous.OTP_Read_Display_Option
           (OTP_Options, Success);

         --  if Success then
         --     Factory_Modes := OTP_Options.WS;
         --  end if;

         if Success and then not OTP_Options.RAM_Ping_Pong then
            Options := Nu_Pogodi.Hardware.SSD1683.Get_Display_Option_Registers
              (OTP_Options);
            Options.RAM_Ping_Pong := True;

            Nu_Pogodi.Hardware.SSD1683.Synchronous.Write_Display_Option
              (Options, Success);
         end if;
      end;

      if not Success then
         raise Program_Error;
      end if;

      Full_Clean;
      Display_Busy    := False;
      Refresh_Pending := False;

      Request_Clock_State;

      Next := A0B.Time.Clock;

      loop
         if Requested /= null then
            if not Display_Busy then
               if Requested = Clock'Access then
                  Enter_Clock_State;

               elsif Requested = Game'Access then
                  Enter_Game_State;
               end if;

               Requested       := null;
               Refresh_Pending := True;
            end if;
         end if;

         Active.Physics_Tick (Refresh_Pending);

         if (Refresh_Pending or (Active = Clock'Access and Wakeup))
           and then not Display_Busy
         then
            Wakeup          := False;
            Refresh_Pending := False;

            Partial (Framebuffer, Success);
         end if;

         if Keyboard then
            Keyboard := False;

            Active.Keyboard (Nu_Pogodi.Hardware.Keyboard.Get);
         end if;

         Next := @ + Tick_Duration;
         Delay_Until (Next);
      end loop;
   end Run;

end Nu_Pogodi.Application;
