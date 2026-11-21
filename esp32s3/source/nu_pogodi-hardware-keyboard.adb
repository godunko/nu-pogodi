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
with System.Storage_Elements;

with ESPIDF.Button;
with ESPIDF.Driver.GPIO;

package body Nu_Pogodi.Hardware.Keyboard is

   No_Keys : constant Nu_Pogodi.Keyboard.Key_State := [others => False];

   Keyboard_Pins : constant array (Nu_Pogodi.Keyboard.Key)
     of ESPIDF.Driver.GPIO.gpio_num_t :=
       [Nu_Pogodi.Keyboard.Left_Top     => 17,
        Nu_Pogodi.Keyboard.Right_Top    => 7,
        Nu_Pogodi.Keyboard.Left_Bottom  => 15,
        Nu_Pogodi.Keyboard.Right_Bottom => 16,
        Nu_Pogodi.Keyboard.Middle       => 6,
        Nu_Pogodi.Keyboard.Game_A       => 5,
        Nu_Pogodi.Keyboard.Game_B       => 4];

   Buttons : array (Nu_Pogodi.Keyboard.Key) of ESPIDF.Button.button_handle_t;

   Known : aliased Nu_Pogodi.Keyboard.Keyboard_State :=
     (State => No_Keys, Pressed => No_Keys, Released => No_Keys)
       with Atomic, Alignment => 4;

   State_Changed : A0B.Callbacks.Callback;

   procedure Change_State (Key : Nu_Pogodi.Keyboard.Key; Pressed : Boolean);

   function Update_Current_State
     (Old_State : aliased in out Nu_Pogodi.Keyboard.Keyboard_State;
      New_State : Nu_Pogodi.Keyboard.Keyboard_State) return Boolean;
   --  Update current state of the keyboard atomically. When update fails,
   --  `Old_State` is set to new value and function returns `False`.

   procedure On_Press
     (Button : in out ESPIDF.Button.button_dev_t; Data : System.Address)
   with Convention => C;

   procedure On_Release
     (Button : in out ESPIDF.Button.button_dev_t; Data : System.Address)
   with Convention => C;

   ------------------
   -- Change_State --
   ------------------

   procedure Change_State (Key : Nu_Pogodi.Keyboard.Key; Pressed : Boolean) is
      Old : aliased Nu_Pogodi.Keyboard.Keyboard_State := Known;
      Updated : Nu_Pogodi.Keyboard.Keyboard_State;

   begin
      loop
         if Old.State (Key) = Pressed then
            return;
         end if;

         Updated := Old;
         Updated.State (Key) := Pressed;
         Updated.Pressed (Key) := @ or Pressed;
         Updated.Released (Key) := @ or not Pressed;

         exit when Update_Current_State (Old, Updated);
      end loop;

      A0B.Callbacks.Emit (State_Changed);
   end Change_State;

   ---------
   -- Get --
   ---------

   function Get return Nu_Pogodi.Keyboard.Keyboard_State is
      Result  : aliased Nu_Pogodi.Keyboard.Keyboard_State := Known;
      Updated : Nu_Pogodi.Keyboard.Keyboard_State;

   begin
      loop
         Updated :=
           (Result with delta Pressed => No_Keys, Released => No_Keys);

         exit when Update_Current_State (Result, Updated);
      end loop;

      return Result;
   end Get;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      use type ESPIDF.int;

   begin
      for Key in Keyboard_Pins'Range loop
         declare
            Config      : ESPIDF.Button.button_config_t;
            GPIO_Config : ESPIDF.Button.button_gpio_config_t;
            Event_Args  : ESPIDF.Button.button_event_args_t;
            Data        : constant System.Address :=
              System.Storage_Elements.To_Address
                (Nu_Pogodi.Keyboard.Key'Pos (Key));
            Old         : aliased Nu_Pogodi.Keyboard.Keyboard_State;
            Updated     : Nu_Pogodi.Keyboard.Keyboard_State;
            Pressed     : Boolean;

         begin
            ESPIDF.Button.Set_gpio_num (GPIO_Config, Keyboard_Pins (Key));
            ESPIDF.Button.Set_active_level (GPIO_Config, 0);
            ESPIDF.Button.iot_button_new_gpio_device
              (Config, GPIO_Config, Buttons (Key));

            --  Set current state of the key before registering its callbacks.

            Pressed :=
              ESPIDF.Driver.GPIO.gpio_get_level (Keyboard_Pins (Key)) = 0;
            Old     := Known;

            loop
               Updated := Old;
               Updated.State (Key) := Pressed;
               exit when Update_Current_State (Old, Updated);
            end loop;

            ESPIDF.Button.iot_button_register_cb
              (Buttons (Key).all,
               ESPIDF.Button.BUTTON_PRESS_DOWN,
               Event_Args,
               On_Press'Access,
               Data);
            ESPIDF.Button.iot_button_register_cb
              (Buttons (Key).all,
               ESPIDF.Button.BUTTON_PRESS_UP,
               Event_Args,
               On_Release'Access,
               Data);
         end;
      end loop;
   end Initialize;

   --------------
   -- On_Press --
   --------------

   procedure On_Press
     (Button : in out ESPIDF.Button.button_dev_t with Unreferenced;
      Data   : System.Address) is
   begin
      Change_State
        (Nu_Pogodi.Keyboard.Key'Val (System.Storage_Elements.To_Integer (Data)),
         True);
   end On_Press;

   ----------------
   -- On_Release --
   ----------------

   procedure On_Release
     (Button : in out ESPIDF.Button.button_dev_t with Unreferenced;
      Data   : System.Address) is
   begin
      Change_State
        (Nu_Pogodi.Keyboard.Key'Val (System.Storage_Elements.To_Integer (Data)),
         False);
   end On_Release;

   -----------------------
   -- Set_State_Changed --
   -----------------------

   procedure Set_State_Changed (Callback : A0B.Callbacks.Callback) is
   begin
      State_Changed := Callback;
   end Set_State_Changed;

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
