--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Callbacks.Generic_Parameterless;
with A0B.Time;
with A0B.Time.Clock;
with A0B.Timer;
--  with A0B.Types;

with Nu_Pogodi.Hardware.MIPI;
with Nu_Pogodi.Hardware.Pin_Control;

package body Nu_Pogodi.Hardware.SSD1683 is

   SW_RESET_Command : constant Nu_Pogodi.Hardware.MIPI.Command_Code := 16#12#;

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
      SW_Reset_Wait,
      Ready);

   State   : State_Kind := Initial with Volatile;
   Timeout : aliased A0B.Timer.Timeout_Control_Block;

   RESET_LOW_START  : A0B.Time.Monotonic_Time with Volatile;
   RESET_HIGH_START : A0B.Time.Monotonic_Time with Volatile;
   RESET_BUSY       : A0B.Time.Monotonic_Time with Volatile;

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

      --  RESET_DONE  : A0B.Time.Monotonic_Time with Volatile;
      --  Counter     : Natural := 0 with Volatile;

      procedure On_Timeout is
      begin
         HW_Reset_Low_State.Enter;

         --
         --  Nu_Pogodi.Hardware.Pin_Control.Enable_SSD1683_BUSY
         --    (On_Busy_Callbacks.Create_Callback);
         --  Nu_Pogodi.Hardware.Pin_Control.Set_SSD1683_RES (False);
         --
         --  if Nu_Pogodi.Hardware.Pin_Control.Get_SSD1683_BUSY then
         --     raise Program_Error;
         --  end if;
         --
         --  while Nu_Pogodi.Hardware.Pin_Control.Get_SSD1683_BUSY loop
         --     --  Counter := @ + 1;
         --     null;
         --  end loop;
         --
         --  for J in 1 .. 1_000_000 loop
         --     Counter := @ + 1;
         --  end loop;
         --
         --  RESET_DONE := A0B.Time.Clock;
         --
         --  raise Program_Error;
      end On_Timeout;

   end VCI_Wait_State;

end Nu_Pogodi.Hardware.SSD1683;
