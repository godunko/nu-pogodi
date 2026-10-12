--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Ada.Unchecked_Conversion;
pragma Warnings (Off, "* is an internal GNAT unit");
with System.Atomic_Primitives;
pragma Warnings (On, "* is an internal GNAT unit");

with A0B.Callbacks.Generic_Parameterless;

with Nu_Pogodi.Hardware.Pin_Control;
with Nu_Pogodi.Hardware.RTC;

package body Nu_Pogodi.Hardware.Keyboard is

   use type Nu_Pogodi.Keyboard.Key_State;

   No_Keys  : constant Nu_Pogodi.Keyboard.Key_State := [others => False];
   All_Keys : constant Nu_Pogodi.Keyboard.Key_State := [others => True];

   Known  : aliased Nu_Pogodi.Keyboard.Keyboard_State :=
     (State => No_Keys, Pressed => No_Keys, Released => No_Keys)
       with Atomic, Alignment => 4;
   Active : Nu_Pogodi.Keyboard.Key_State := No_Keys;
   --  Keyboard EXTI and RTC wakeup have equal preemption priorities, so their
   --  callbacks serialize access to Active without masking other interrupts.

   procedure On_Edge;

   package On_Edge_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Edge);

   procedure On_Timer;

   package On_Timer_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Timer);

   function Update_Current_State
     (Old_State : aliased in out Nu_Pogodi.Keyboard.Keyboard_State;
      New_State : Nu_Pogodi.Keyboard.Keyboard_State) return Boolean;
   --  Update current state of the keyboard atomically. When update fails,
   --  `Old_State` is set to new value and function returns `False`.

   ---------
   -- Get --
   ---------

   function Get return Nu_Pogodi.Keyboard.Keyboard_State is
      Result  : aliased Nu_Pogodi.Keyboard.Keyboard_State := Known;
      Updated : Nu_Pogodi.Keyboard.Keyboard_State;

   begin
      loop
         Updated :=
           (Result with delta
              Pressed  => No_Keys,
              Released => No_Keys);

         exit when Update_Current_State (Result, Updated);
      end loop;

      return Result;
   end Get;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Nu_Pogodi.Hardware.Pin_Control.Configure_Keyboard_Pins
        (On_Edge_Callbacks.Create_Callback);

      Known :=
        (State    => not Nu_Pogodi.Hardware.Pin_Control.Get_Keyboard_State,
         Pressed  => No_Keys,
         Released => No_Keys);
      Nu_Pogodi.Hardware.Pin_Control.Clear_Keyboard_Pending (All_Keys);
      Nu_Pogodi.Hardware.Pin_Control.Enable_Keyboard_Interrupt;
   end Initialize;

   -------------
   -- On_Edge --
   -------------

   procedure On_Edge is
      Changed : constant Nu_Pogodi.Keyboard.Key_State :=
        Nu_Pogodi.Hardware.Pin_Control.Get_Keyboard_Pending;

   begin
      if Active /= No_Keys then
         --  Debounce procedure is ongoing. Ignore edge events for now.
         --
         --  It might happen that multiple edges are detected simultaneously,
         --  and belongs to different EXTI groups (15..10 and 9..5).

         return;
      end if;

      --  Get set of detected key line changes, clear them, and disbale key
      --  line change interrupt.

      Active := Changed;
      Nu_Pogodi.Hardware.Pin_Control.Clear_Keyboard_Pending (Active);
      Nu_Pogodi.Hardware.Pin_Control.Disable_Keyboard_Interrupt;

      --  Start wakeup timer to debounce

      Nu_Pogodi.Hardware.RTC.Schedule_Timer_Wakeup
        (On_Timer_Callbacks.Create_Callback);
   end On_Edge;

   --------------
   -- On_Timer --
   --------------

   procedure On_Timer is
      Sample  : Nu_Pogodi.Keyboard.Key_State;
      Changed : Nu_Pogodi.Keyboard.Key_State;
      Old     : aliased Nu_Pogodi.Keyboard.Keyboard_State;
      Updated : Nu_Pogodi.Keyboard.Keyboard_State;
      Stable  : Nu_Pogodi.Keyboard.Key_State;

   begin
      Sample  := not Nu_Pogodi.Hardware.Pin_Control.Get_Keyboard_State;
      Changed := Nu_Pogodi.Hardware.Pin_Control.Get_Keyboard_Pending;

      Stable  := Active and not Changed;

      if Stable /= No_Keys then
         --  Debounce of some lines hes been completed.

         Old := Known;

         loop
            Updated := Old;

            Updated.Pressed  := @ or (Stable and Sample and not Updated.State);
            Updated.Released := @ or (Stable and not Sample and Updated.State);
            Updated.State    := (@ and not Stable) or (Sample and Stable);

            exit when Update_Current_State (Old, Updated);
         end loop;
      end if;

      Active := Changed;

      if Active /= No_Keys then
         Nu_Pogodi.Hardware.Pin_Control.Clear_Keyboard_Pending (Active);
         Nu_Pogodi.Hardware.RTC.Schedule_Timer_Wakeup
           (On_Timer_Callbacks.Create_Callback);

      else
         Nu_Pogodi.Hardware.Pin_Control.Enable_Keyboard_Interrupt;
      end if;
   end On_Timer;

   --------------------------
   -- Update_Current_State --
   --------------------------

   function Update_Current_State
     (Old_State : aliased in out Nu_Pogodi.Keyboard.Keyboard_State;
      New_State : Nu_Pogodi.Keyboard.Keyboard_State) return Boolean
   is
      function As_uint32 is
        new Ada.Unchecked_Conversion
          (Nu_Pogodi.Keyboard.Keyboard_State, System.Atomic_Primitives.uint32);

   begin
      return
        System.Atomic_Primitives.Atomic_Compare_Exchange_32
          (Ptr      => Known'Address,
           Expected => Old_State'Address,
           Desired  => As_uint32 (New_State));
   end Update_Current_State;
end Nu_Pogodi.Hardware.Keyboard;
