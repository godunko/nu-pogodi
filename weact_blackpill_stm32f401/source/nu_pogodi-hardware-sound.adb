--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

--  This is WeAct BlackPill STM32F401 version of the package.

with Nu_Pogodi.Hardware.Pin_Control;
with Nu_Pogodi.Hardware.TIM;

package body Nu_Pogodi.Hardware.Sound is

   use type A0B.Asynchronous_Transfers.Operation_State;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Nu_Pogodi.Hardware.TIM.Initialize;
      Nu_Pogodi.Hardware.Pin_Control.Configure_Buzzer_Pin;
   end Initialize;

   -----------
   -- Start --
   -----------

   procedure Start
     (Descriptor :
        aliased in out A0B.Asynchronous_Transfers.Transfer_Descriptor;
      Finished   : A0B.Callbacks.Callback;
      Success    : in out Boolean) is
   begin
      if not Success then
         return;
      end if;

      if Descriptor.State /= A0B.Asynchronous_Transfers.Inactive then
         Success := False;

         return;
      end if;

      Nu_Pogodi.Hardware.TIM.Transmit (Descriptor, Finished, Success);
   end Start;

end Nu_Pogodi.Hardware.Sound;
