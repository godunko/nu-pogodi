--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

--  Potential improvements:
--   * don't enter VCI wait state at initialization, move this responsibility
--     to application. While adds one more state to application, it allows to
--     suppot cases when panel's power is managed by application.

pragma Ada_2022;

with A0B;
with A0B.Buffers.Static;
with A0B.Callbacks.Generic_Parameterless;
with A0B.Time;
with A0B.Timer;

with A0B.Types.Arrays;
with Nu_Pogodi.Hardware.MIPI;
with Nu_Pogodi.Hardware.Pin_Control;

package body Nu_Pogodi.Hardware.SSD1683 is

   Booster_Soft_Start_Control_Command           : constant
     Nu_Pogodi.Hardware.MIPI.Command_Code := 16#0C#;
   Data_Entry_Mode_Setting_Command              : constant
     Nu_Pogodi.Hardware.MIPI.Command_Code := 16#11#;
   SW_RESET_Command                             : constant
     Nu_Pogodi.Hardware.MIPI.Command_Code := 16#12#;
   Temperature_Sensor_Control_Command           : constant
     Nu_Pogodi.Hardware.MIPI.Command_Code := 16#18#;
   Master_Activation_Command                    : constant
     Nu_Pogodi.Hardware.MIPI.Command_Code := 16#20#;
   Display_Update_Control_2_Command             : constant
     Nu_Pogodi.Hardware.MIPI.Command_Code := 16#22#;
   Write_RAM_Black_White_Command                : constant
     Nu_Pogodi.Hardware.MIPI.Command_Code := 16#24#;
   Write_RAM_Red_Command                        : constant
     Nu_Pogodi.Hardware.MIPI.Command_Code := 16#26#;
   --  Load_WS_OTP_Command                        : constant
   --    Nu_Pogodi.Hardware.MIPI.Command_Code := 16#31#;
   Set_RAM_X_Address_Start_End_Position_Command : constant
     Nu_Pogodi.Hardware.MIPI.Command_Code := 16#44#;
   Set_RAM_Y_Address_Start_End_Position_Command : constant
     Nu_Pogodi.Hardware.MIPI.Command_Code := 16#45#;

   procedure On_Timeout;

   procedure On_Busy;

   package On_Timeout_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Timeout);

   package On_Busy_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Busy);

   type State_Kind is
     (Initial,        --  Not initialized
      Ready,          --  Initialized, ready to execute actions
      VCI_Wait,       --  Power-on procedure, wait panel to power-on
      HW_Reset_Low,   --  Push RES to low, and wait 10 milliseconds
      HW_Reset_High,  --  Push RES to high, wait till BUSY released
      Command,        --  Execute command
      Command_Busy);  --  Execute command, wait till BUSY released

   State            : State_Kind := Initial with Atomic, Volatile;
   Timeout          : aliased A0B.Timer.Timeout_Control_Block;
   Reset_After_VCI  : Boolean := False with Atomic, Volatile;
   Command_Callback : A0B.Callbacks.Callback;
   Parameter_Buffer : A0B.Buffers.Static.Static_Buffer (4);

   package State_Machine_VCI_Wait_State is

      --  Power-on state, wait 10 milliseconds to complete panel's power-on
      --  operations.
      --
      --  Note, as recommended by MIPI specification, RES signal should low
      --  during this time.

      procedure Enter;

      procedure On_Timeout;

   end State_Machine_VCI_Wait_State;

   package State_Machine_HW_Reset_Low_State is

      --  Start of reset sequence, push RES to low state and wait 10
      --  milliseconds, then enter `HW_Reset_High` state.

      procedure Enter;

      procedure On_Timeout;

   end State_Machine_HW_Reset_Low_State;

   package State_Machine_HW_Reset_High_State is

      --  Sets RES to high and wait for release of BUSY line, then executes
      --  `SW_RESET` command.

      procedure Enter;

      procedure On_Timeout;

      procedure On_Busy;

   end State_Machine_HW_Reset_High_State;

   package State_Machine_Command_State is

      --  Executes given command.
      --
      --  Emits `Command_Callback` when transfer is completed.

      procedure Enter
        (Command     : Nu_Pogodi.Hardware.MIPI.Command_Code;
         Data_Buffer : A0B.Buffers.Abstract_Buffer'Class;
         Callback    : A0B.Callbacks.Callback;
         Success     : in out Boolean);

   end State_Machine_Command_State;

   package State_Machine_Command_Busy_State is

      --  Executes given command and wait till release of BUSY line.
      --
      --  Emits `Command_Callback` when transfer is completed and BUSY line is
      --  released.

      procedure Enter (Command : Nu_Pogodi.Hardware.MIPI.Command_Code);
      --  This subprogram is used only by reset sequence.

      procedure Enter
        (Command  : Nu_Pogodi.Hardware.MIPI.Command_Code;
         Callback : A0B.Callbacks.Callback;
         Success  : in out Boolean);

      procedure On_Busy;

   end State_Machine_Command_Busy_State;

   --------------------------------
   -- Booster_Soft_Start_Control --
   --------------------------------

   procedure Booster_Soft_Start_Control
     (B1       : A0B.Types.Unsigned_8;
      B2       : A0B.Types.Unsigned_8;
      B3       : A0B.Types.Unsigned_8;
      B4       : A0B.Types.Unsigned_8;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      declare
         Data : A0B.Types.Arrays.Unsigned_8_Array (1 .. 4)
           with Import, Address => Parameter_Buffer.Address;

      begin
         Data (1) := B1;
         Data (2) := B2;
         Data (3) := B3;
         Data (4) := B4;
         Parameter_Buffer.Set_Actual_Length (4);
      end;

      State_Machine_Command_State.Enter
        (Booster_Soft_Start_Control_Command,
         Parameter_Buffer,
         Callback,
         Success);
   end Booster_Soft_Start_Control;

   -----------------------------
   -- Data_Entry_Mode_Setting --
   -----------------------------

   procedure Data_Entry_Mode_Setting
     (X_Axis   : Address_Direction;
      Y_Axis   : Address_Direction;
      Primary  : Direction;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      declare
         use type A0B.Types.Unsigned_8;

         Data : A0B.Types.Unsigned_8
           with Import, Address => Parameter_Buffer.Address;

      begin
         Data := 16#00#;

         if X_Axis = Increment then
            Data := @ or 2#0000_0001#;
         end if;

         if Y_Axis = Increment then
            Data := @ or 2#0000_0010#;
         end if;

         if Primary = SSD1683.Y_Axis then
            Data := @ or 2#0000_0100#;
         end if;

         Parameter_Buffer.Set_Actual_Length (1);
      end;

      State_Machine_Command_State.Enter
        (Data_Entry_Mode_Setting_Command,
         Parameter_Buffer,
         Callback,
         Success);
   end Data_Entry_Mode_Setting;

   ------------------------------
   -- Display_Update_Control_2 --
   ------------------------------

   procedure Display_Update_Control_2
     (Sequence : Update_Sequence;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      declare
         Code : Update_Sequence
           with Import, Address => Parameter_Buffer.Address;

      begin
         Code := Sequence;
         Parameter_Buffer.Set_Actual_Length (1);
      end;

      State_Machine_Command_State.Enter
        (Display_Update_Control_2_Command,
         Parameter_Buffer,
         Callback,
         Success);
   end Display_Update_Control_2;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Nu_Pogodi.Hardware.MIPI.Initialize;

      State_Machine_VCI_Wait_State.Enter;
   end Initialize;

   -----------------------
   -- Master_Activation --
   -----------------------

   procedure Master_Activation
     (Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      State_Machine_Command_Busy_State.Enter
        (Master_Activation_Command,
         Callback,
         Success);
   end Master_Activation;

   -----------
   -- Reset --
   -----------

   procedure Reset (Callback : A0B.Callbacks.Callback) is
      Entry_State : constant State_Kind := State;

   begin
      Command_Callback := Callback;

      if Entry_State = VCI_Wait then
         --  VCI Wait is in progress, attempt to equeue request

         Reset_After_VCI := True;

         if State = Ready
           and then A0B.Callbacks.Is_Set (Command_Callback)
         then
            --  VCI state was left before enqueue completed, cleanup request
            --  and enter `HW_Reset_Low` state.

            Reset_After_VCI := False;
            State_Machine_HW_Reset_Low_State.Enter;
         end if;

      else
         State_Machine_HW_Reset_Low_State.Enter;
      end if;
   end Reset;

   -------------
   -- On_Busy --
   -------------

   procedure On_Busy is
   begin
      case State is
         when HW_Reset_High =>
            State_Machine_HW_Reset_High_State.On_Busy;

         when Command_Busy =>
            State_Machine_Command_Busy_State.On_Busy;

         when others =>
            raise Program_Error;
      end case;
   end On_Busy;

   ----------------
   -- On_Timeout --
   ----------------

   procedure On_Timeout is
   begin
      case State is
         when VCI_Wait =>
            State_Machine_VCI_Wait_State.On_Timeout;

         when HW_Reset_Low =>
            State_Machine_HW_Reset_Low_State.On_Timeout;

         when HW_Reset_High =>
            State_Machine_HW_Reset_High_State.On_Timeout;

         when others =>
            raise Program_Error;
      end case;
   end On_Timeout;

   ------------------------------------------
   -- Set_RAM_X_Address_Start_End_Position --
   ------------------------------------------

   procedure Set_RAM_X_Address_Start_End_Position
     (X_Start  : A0B.Types.Unsigned_6;
      X_End    : A0B.Types.Unsigned_6;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      declare
         Data : A0B.Types.Arrays.Unsigned_8_Array (1 .. 2)
           with Import, Address => Parameter_Buffer.Address;

      begin
         Data (1) := A0B.Types.Unsigned_8 (X_Start);
         Data (2) := A0B.Types.Unsigned_8 (X_End);
         Parameter_Buffer.Set_Actual_Length (2);
      end;

      State_Machine_Command_State.Enter
        (Set_RAM_X_Address_Start_End_Position_Command,
         Parameter_Buffer,
         Callback,
         Success);
   end Set_RAM_X_Address_Start_End_Position;

   ------------------------------------------
   -- Set_RAM_Y_Address_Start_End_Position --
   ------------------------------------------

   procedure Set_RAM_Y_Address_Start_End_Position
     (Y_Start  : A0B.Types.Unsigned_9;
      Y_End    : A0B.Types.Unsigned_9;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      declare
         use type A0B.Types.Unsigned_9;

         Data : A0B.Types.Arrays.Unsigned_8_Array (1 .. 4)
           with Import, Address => Parameter_Buffer.Address;

      begin
         Data (1) := A0B.Types.Unsigned_8 (Y_Start mod 256);
         Data (2) := A0B.Types.Unsigned_8 (Y_Start / 256);
         Data (3) := A0B.Types.Unsigned_8 (Y_End mod 256);
         Data (4) := A0B.Types.Unsigned_8 (Y_End / 256);
         Parameter_Buffer.Set_Actual_Length (4);
      end;

      State_Machine_Command_State.Enter
        (Set_RAM_Y_Address_Start_End_Position_Command,
         Parameter_Buffer,
         Callback,
         Success);
   end Set_RAM_Y_Address_Start_End_Position;

   --------------------------------------
   -- State_Machine_Command_Busy_State --
   --------------------------------------

   package body State_Machine_Command_Busy_State is

      procedure On_Transfer_Finished;

      package On_Transfer_Finished_Callbacks is
        new A0B.Callbacks.Generic_Parameterless (On_Transfer_Finished);

      -----------
      -- Enter --
      -----------

      procedure Enter (Command : Nu_Pogodi.Hardware.MIPI.Command_Code) is
         Success : Boolean := True;

      begin
         State := Command_Busy;

         Nu_Pogodi.Hardware.Pin_Control.Enable_SSD1683_BUSY
           (On_Busy_Callbacks.Create_Callback);
         Nu_Pogodi.Hardware.MIPI.Command
           (Command,
            On_Transfer_Finished_Callbacks.Create_Callback,
            Success);

         if not Success then
            --  XXX Not implemented, MIPI can't start transfer of the command.

            raise Program_Error;
         end if;
      end Enter;

      -----------
      -- Enter --
      -----------

      procedure Enter
        (Command  : Nu_Pogodi.Hardware.MIPI.Command_Code;
         Callback : A0B.Callbacks.Callback;
         Success  : in out Boolean) is
      begin
         if not Success then
            return;
         end if;

         State            := Command_Busy;
         Command_Callback := Callback;

         Nu_Pogodi.Hardware.Pin_Control.Enable_SSD1683_BUSY
           (On_Busy_Callbacks.Create_Callback);
         Nu_Pogodi.Hardware.MIPI.Command
           (Command,
            On_Transfer_Finished_Callbacks.Create_Callback,
            Success);

         if not Success then
            --  XXX Not implemented, MIPI can't start transfer of the command.

            raise Program_Error;
         end if;
      end Enter;

      -------------
      -- On_Busy --
      -------------

      procedure On_Busy is
      begin
         State := Ready;

         A0B.Callbacks.Emit_Once (Command_Callback);
      end On_Busy;

      --------------------------
      -- On_Transfer_Finished --
      --------------------------

      procedure On_Transfer_Finished is
      begin
         --  XXX Transfer error handling is not implemented.

         null;
      end On_Transfer_Finished;

   end State_Machine_Command_Busy_State;

   ---------------------------------
   -- State_Machine_Command_State --
   ---------------------------------

   package body State_Machine_Command_State is

      procedure On_Transfer_Finished;

      package On_Transfer_Finished_Callbacks is
        new A0B.Callbacks.Generic_Parameterless (On_Transfer_Finished);

      -----------
      -- Enter --
      -----------

      procedure Enter
        (Command     : Nu_Pogodi.Hardware.MIPI.Command_Code;
         Data_Buffer : A0B.Buffers.Abstract_Buffer'Class;
         Callback    : A0B.Callbacks.Callback;
         Success     : in out Boolean) is
      begin
         State := SSD1683.Command;
         Command_Callback := Callback;

         Nu_Pogodi.Hardware.MIPI.Command_Write
           (Command,
            Data_Buffer,
            On_Transfer_Finished_Callbacks.Create_Callback,
            Success);

         if not Success then
            --  XXX Not implemented, MIPI can't start transfer of the command.

            raise Program_Error;
         end if;
      end Enter;

      --------------------------
      -- On_Transfer_Finished --
      --------------------------

      procedure On_Transfer_Finished is
      begin
         --  XXX Transfer error handling is not implemented.

         State := Ready;

         A0B.Callbacks.Emit_Once (Command_Callback);
      end On_Transfer_Finished;

   end State_Machine_Command_State;

   ---------------------------------------
   -- State_Machine_HW_Reset_High_State --
   ---------------------------------------

   package body State_Machine_HW_Reset_High_State is

      -----------
      -- Enter --
      -----------

      procedure Enter is
      begin
         State := HW_Reset_High;

         Nu_Pogodi.Hardware.Pin_Control.Enable_SSD1683_BUSY
           (On_Busy_Callbacks.Create_Callback);
         A0B.Timer.Enqueue
           (Timeout,
            On_Timeout_Callbacks.Create_Callback,
            A0B.Time.Milliseconds (10));

         Nu_Pogodi.Hardware.Pin_Control.Set_SSD1683_RES (True);
      end Enter;

      -------------
      -- On_Busy --
      -------------

      procedure On_Busy is
      begin
         A0B.Timer.Cancel (Timeout);

         State_Machine_Command_Busy_State.Enter (SW_RESET_Command);
      end On_Busy;

      ----------------
      -- On_Timeout --
      ----------------

      procedure On_Timeout is
      begin
         --  Display controller doesn't respond to RES signal, indicating a
         --  hardware failure.

         Nu_Pogodi.Hardware.Pin_Control.Disable_SSD1683_BUSY;

         --  XXX Not implemented: proper error handling for hardware failure.

         raise Program_Error;
      end On_Timeout;

   end State_Machine_HW_Reset_High_State;

   --------------------------------------
   -- State_Machine_HW_Reset_Low_State --
   --------------------------------------

   package body State_Machine_HW_Reset_Low_State is

      -----------
      -- Enter --
      -----------

      procedure Enter is
      begin
         State := HW_Reset_Low;

         Nu_Pogodi.Hardware.Pin_Control.Set_SSD1683_RES (False);

         A0B.Timer.Enqueue
           (Timeout,
            On_Timeout_Callbacks.Create_Callback,
            A0B.Time.Milliseconds (10));
      end Enter;

      ----------------
      -- On_Timeout --
      ----------------

      procedure On_Timeout is
      begin
         State_Machine_HW_Reset_High_State.Enter;
      end On_Timeout;

   end State_Machine_HW_Reset_Low_State;

   ----------------------------------
   -- State_Machine_VCI_Wait_State --
   ----------------------------------

   package body State_Machine_VCI_Wait_State is

      -----------
      -- Enter --
      -----------

      procedure Enter is
      begin
         State := VCI_Wait;
         A0B.Timer.Enqueue
           (Timeout,
            On_Timeout_Callbacks.Create_Callback,
            A0B.Time.Milliseconds (10));
      end Enter;

      ----------------
      -- On_Timeout --
      ----------------

      procedure On_Timeout is
      begin
         if Reset_After_VCI
           and then A0B.Callbacks.Is_Set (Command_Callback)
         then
            Reset_After_VCI := False;

            State_Machine_HW_Reset_Low_State.Enter;

         else
            State := Ready;
         end if;
      end On_Timeout;

   end State_Machine_VCI_Wait_State;

   --------------------------------
   -- Temperature_Sensor_Control --
   --------------------------------

   procedure Temperature_Sensor_Control
     (Sensor   : Temperature_Sensor;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      declare
         Code : A0B.Types.Unsigned_8
           with Import, Address => Parameter_Buffer.Address;

      begin
         Code :=
           (case Sensor is
              when External => 16#48#,
              when Internal => 16#80#);
         Parameter_Buffer.Set_Actual_Length (1);
      end;

      State_Machine_Command_State.Enter
        (Temperature_Sensor_Control_Command,
         Parameter_Buffer,
         Callback,
         Success);
   end Temperature_Sensor_Control;

   ---------------------------
   -- Write_RAM_Black_White --
   ---------------------------

   procedure Write_RAM_Black_White
     (Data     : A0B.Buffers.Abstract_Buffer'Class;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      State_Machine_Command_State.Enter
        (Write_RAM_Black_White_Command, Data, Callback, Success);
   end Write_RAM_Black_White;

   -------------------
   -- Write_RAM_Red --
   -------------------

   procedure Write_RAM_Red
     (Data     : A0B.Buffers.Abstract_Buffer'Class;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      State_Machine_Command_State.Enter
        (Write_RAM_Red_Command, Data, Callback, Success);
   end Write_RAM_Red;

end Nu_Pogodi.Hardware.SSD1683;
