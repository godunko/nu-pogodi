--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with System.Storage_Elements;

with A0B.Asynchronous_Transfers;

with Nu_Pogodi.Hardware.Pin_Control;
with Nu_Pogodi.Hardware.TIM;

package body Nu_Pogodi.Hardware.Sound is

   use type System.Storage_Elements.Storage_Count;
   use type A0B.Asynchronous_Transfers.Operation_State;

   Descriptor : aliased A0B.Asynchronous_Transfers.Transfer_Descriptor;

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
     (Data     : aliased Sample_Array;
      Finished : A0B.Callbacks.Callback;
      Success  : out Boolean) is
   begin
      if Descriptor.State = A0B.Asynchronous_Transfers.Active then
         Success := False;

         return;
      end if;

      A0B.Asynchronous_Transfers.Initialize
        (Self   => Descriptor,
         Data   => Data'Address,
         Length => Data'Size / System.Storage_Unit);

      Success := True;
      Nu_Pogodi.Hardware.TIM.Transmit (Descriptor, Finished, Success);
   end Start;

end Nu_Pogodi.Hardware.Sound;
