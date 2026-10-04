--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Buffers.Static;
with A0B.Callbacks.Generic_Parameterless;
with A0B.Time;
with A0B.Time.Clock;
with A0B.Timer;
--  with A0B.Types;

with A0B.Types;
with A0B.Types.Arrays;
with Nu_Pogodi.Hardware.MIPI;
with Nu_Pogodi.Hardware.Pin_Control;

package body Nu_Pogodi.Hardware.SSD1683 is

   SW_RESET_Command                 : constant
     Nu_Pogodi.Hardware.MIPI.Command_Code := 16#12#;
   Master_Activation_Command        : constant
     Nu_Pogodi.Hardware.MIPI.Command_Code := 16#20#;
   Display_Update_Control_2_Command : constant
     Nu_Pogodi.Hardware.MIPI.Command_Code := 16#22#;
   Write_RAM_Black_White_Command    : constant
     Nu_Pogodi.Hardware.MIPI.Command_Code := 16#24#;
   Write_RAM_Red_Command            : constant
     Nu_Pogodi.Hardware.MIPI.Command_Code := 16#26#;

   procedure On_Timeout;

   procedure On_Busy;

   package On_Timeout_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Timeout);

   package On_Busy_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Busy);

   type State_Kind is
     (Initial,
      VCI_Wait,
      HW_Reset_Low,
      HW_Reset_High,
      SW_Reset_Transfer,
      Write_BW,
      Write_Red,
      Display_Update_Control_2,
      Master_Activation);

   Pixel_Buffer : A0B.Buffers.Static.Static_Buffer (15_000);

   State   : State_Kind := Initial with Volatile;
   Timeout : aliased A0B.Timer.Timeout_Control_Block;

   RESET_LOW_START  : A0B.Time.Monotonic_Time with Volatile;
   RESET_HIGH_START : A0B.Time.Monotonic_Time with Volatile;
   RESET_BUSY       : A0B.Time.Monotonic_Time with Volatile;
   WRITE_BW_START   : A0B.Time.Monotonic_Time with Volatile;
   WRITE_BW_DONE    : A0B.Time.Monotonic_Time with Volatile;
   WRITE_RED_START  : A0B.Time.Monotonic_Time with Volatile;
   WRITE_RED_DONE   : A0B.Time.Monotonic_Time with Volatile;

   package HW_Reset_Low_State is

      procedure Enter;

      procedure On_Timeout;

   end HW_Reset_Low_State;

   package HW_Reset_High_State is

      procedure Enter;

      procedure On_Timeout;

      procedure On_Busy;

   end HW_Reset_High_State;

   package VCI_Wait_State is

      procedure Enter;

      procedure On_Timeout;

   end VCI_Wait_State;

   package SW_Reset_Transfer_State is

      procedure Enter;

      procedure On_Busy;

   end SW_Reset_Transfer_State;

   package Write_BW_State is

      procedure Enter;

   end Write_BW_State;

   package Write_Red_State is

      procedure Enter;

   end Write_Red_State;

   package Display_Update_Control_2_State is

      procedure Enter;

   end Display_Update_Control_2_State;

   package Master_Activation_State is

      procedure Enter;

      procedure On_Busy;

   end Master_Activation_State;

   -----------------------------
   -- Master_Activation_State --
   -----------------------------

   package body Master_Activation_State is

      procedure On_Transfer_Finished;

      package On_Transfer_Finished_Callbacks is
        new A0B.Callbacks.Generic_Parameterless (On_Transfer_Finished);

      -----------
      -- Enter --
      -----------

      procedure Enter is
         Success : Boolean := True;

      begin
         State := Master_Activation;

         Nu_Pogodi.Hardware.Pin_Control.Enable_SSD1683_BUSY
           (On_Busy_Callbacks.Create_Callback);
         Nu_Pogodi.Hardware.MIPI.Command
           (Master_Activation_Command,
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
         --  Write_BW_State.Enter;

         --  XXX Not implemented !!!
         raise Program_Error;
      end On_Busy;

      --------------------------
      -- On_Transfer_Finished --
      --------------------------

      procedure On_Transfer_Finished is
      begin
         --  XXX Transfer error handling is not implemented.

         null;
      end On_Transfer_Finished;

   end Master_Activation_State;

   ------------------------------------
   -- Display_Update_Control_2_State --
   ------------------------------------

   package body Display_Update_Control_2_State is

      procedure On_Transfer_Finished;

      package On_Transfer_Finished_Callbacks is
        new A0B.Callbacks.Generic_Parameterless (On_Transfer_Finished);

      -----------
      -- Enter --
      -----------

      procedure Enter is
         Success : Boolean := True;

      begin
         State := Display_Update_Control_2;
         --  WRITE_BW_START := A0B.Time.Clock;

         declare
            Code : A0B.Types.Unsigned_8
              with Import, Address => Pixel_Buffer.Address;

         begin
            Code := 16#F7#;  --  Full refresh
            --  Code := 16#FF#;  --  Partial refresh
            Pixel_Buffer.Set_Actual_Length (1);
         end;

         Nu_Pogodi.Hardware.MIPI.Command_Write
           (Display_Update_Control_2_Command,
            Pixel_Buffer,
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
         --  XXX Not implemented !!!

         --  WRITE_BW_DONE := A0B.Time.Clock;

         Master_Activation_State.Enter;
         --  raise Program_Error;
      end On_Transfer_Finished;

   end Display_Update_Control_2_State;

   --------------------
   -- Write_BW_State --
   --------------------

   package body Write_BW_State is

      procedure On_Transfer_Finished;

      package On_Transfer_Finished_Callbacks is
        new A0B.Callbacks.Generic_Parameterless (On_Transfer_Finished);

      -----------
      -- Enter --
      -----------

      procedure Enter is
         Success : Boolean := True;

      begin
         State := Write_BW;
         WRITE_BW_START := A0B.Time.Clock;

         declare
            Data : A0B.Types.Arrays.Unsigned_8_Array (1 .. 15_000)
              with Import, Address => Pixel_Buffer.Address;

         begin
            Data := [others => 16#FF#];
            Pixel_Buffer.Set_Actual_Length (15_000);
         end;

         Nu_Pogodi.Hardware.MIPI.Command_Write
           (Write_RAM_Black_White_Command,
            Pixel_Buffer,
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
         --  XXX Not implemented !!!

         WRITE_BW_DONE := A0B.Time.Clock;

         Write_Red_State.Enter;
         --  raise Program_Error;
      end On_Transfer_Finished;

   end Write_BW_State;

   ---------------------
   -- Write_Red_State --
   ---------------------

   package body Write_Red_State is

      procedure On_Transfer_Finished;

      package On_Transfer_Finished_Callbacks is
        new A0B.Callbacks.Generic_Parameterless (On_Transfer_Finished);

      -----------
      -- Enter --
      -----------

      procedure Enter is
         Success : Boolean := True;

      begin
         State := Write_Red;
         WRITE_RED_START := A0B.Time.Clock;

         declare
            Data : A0B.Types.Arrays.Unsigned_8_Array (1 .. 15_000)
              with Import, Address => Pixel_Buffer.Address;

         begin
            Data := [others => 16#00#];
            Pixel_Buffer.Set_Actual_Length (15_000);
         end;

         Nu_Pogodi.Hardware.MIPI.Command_Write
           (Write_RAM_Red_Command,
            Pixel_Buffer,
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
         --  XXX Not implemented !!!

         WRITE_RED_DONE := A0B.Time.Clock;

         Display_Update_Control_2_State.Enter;
         --  raise Program_Error;
      end On_Transfer_Finished;

   end Write_Red_State;

   -------------------------
   -- HW_Reset_High_State --
   -------------------------

   package body HW_Reset_High_State is

      -----------
      -- Enter --
      -----------

      procedure Enter is
      begin
         State := HW_Reset_High;
         RESET_HIGH_START := A0B.Time.Clock;

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

         SW_Reset_Transfer_State.Enter;
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

   end HW_Reset_High_State;

   ------------------------
   -- HW_Reset_Low_State --
   ------------------------

   package body HW_Reset_Low_State is

      -----------
      -- Enter --
      -----------

      procedure Enter is
      begin
         State := HW_Reset_Low;
         RESET_LOW_START := A0B.Time.Clock;

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
         HW_Reset_High_State.Enter;
      end On_Timeout;

   end HW_Reset_Low_State;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Nu_Pogodi.Hardware.MIPI.Initialize;

      VCI_Wait_State.Enter;
   end Initialize;

   -------------
   -- On_Busy --
   -------------

   procedure On_Busy is
   begin
      RESET_BUSY := A0B.Time.Clock;

      case State is
         when HW_Reset_High =>
            HW_Reset_High_State.On_Busy;

         when SW_Reset_Transfer =>
            SW_Reset_Transfer_State.On_Busy;

         when Master_Activation =>
            Master_Activation_State.On_Busy;

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
            VCI_Wait_State.On_Timeout;

         when HW_Reset_Low =>
            HW_Reset_Low_State.On_Timeout;

         when HW_Reset_High =>
            HW_Reset_High_State.On_Timeout;

         when others =>
            raise Program_Error;
      end case;
   end On_Timeout;

   -----------------------------
   -- SW_Reset_Transfer_State --
   -----------------------------

   package body SW_Reset_Transfer_State is

      procedure On_Transfer_Finished;

      package On_Transfer_Finished_Callbacks is
        new A0B.Callbacks.Generic_Parameterless (On_Transfer_Finished);

      -----------
      -- Enter --
      -----------

      procedure Enter is
         Success : Boolean := True;

      begin
         State := SW_Reset_Transfer;

         Nu_Pogodi.Hardware.Pin_Control.Enable_SSD1683_BUSY
           (On_Busy_Callbacks.Create_Callback);
         Nu_Pogodi.Hardware.MIPI.Command
           (SW_RESET_Command,
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
         Write_BW_State.Enter;

         --  XXX Not implemented !!!
         --  raise Program_Error;
      end On_Busy;

      --------------------------
      -- On_Transfer_Finished --
      --------------------------

      procedure On_Transfer_Finished is
      begin
         --  XXX Transfer error handling is not implemented.

         null;
      end On_Transfer_Finished;

   end SW_Reset_Transfer_State;

   --------------------
   -- VCI_Wait_State --
   --------------------

   package body VCI_Wait_State is

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
         HW_Reset_Low_State.Enter;
      end On_Timeout;

   end VCI_Wait_State;

end Nu_Pogodi.Hardware.SSD1683;
