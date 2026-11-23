--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Interfaces.C;
with System.Storage_Elements;

with A0B.Callbacks.Generic_Parameterless;
with A0B.Callbacks.Task_Context;
with A0B.Storage;

with ESPIDF.Driver.RMT.Encoder;
with ESPIDF.Driver.RMT.TX;
with ESPIDF.SOC.Clk_Tree;

package body Nu_Pogodi.Hardware.Sound is

   function On_Transmission_Done
     (TX_Channel : ESPIDF.Driver.RMT.rmt_channel_handle_t;
      Event      : ESPIDF.Driver.RMT.TX.rmt_tx_done_event_data_t;
      Context    : System.Address) return ESPIDF.bool
   with Convention => C;

   procedure On_Finished;

   package On_Finished_Callbacks is new
     A0B.Callbacks.Generic_Parameterless (On_Finished);

   Channel    : ESPIDF.Driver.RMT.rmt_channel_handle_t;
   Encoder    : ESPIDF.Driver.RMT.Encoder.rmt_encoder_handle_t;
   Descriptor : A0B.Asynchronous_Transfers.Transfer_Descriptor_Access;
   Callback   : A0B.Callbacks.Callback;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      Channel_Config : ESPIDF.Driver.RMT.TX.rmt_tx_channel_config_t;
      Encoder_Config : ESPIDF.Driver.RMT.Encoder.rmt_copy_encoder_config_t;
      Callbacks      : ESPIDF.Driver.RMT.TX.rmt_tx_event_callbacks_t;

   begin
      ESPIDF.Driver.RMT.TX.Set_gpio_num (Channel_Config, 18);
      ESPIDF.Driver.RMT.TX.Set_clk_src
        (Channel_Config, ESPIDF.SOC.Clk_Tree.RMT_CLK_SRC_DEFAULT);
      ESPIDF.Driver.RMT.TX.Set_resolution_hz (Channel_Config, 2_000_000);
      ESPIDF.Driver.RMT.TX.Set_mem_block_symbols (Channel_Config, 64);
      ESPIDF.Driver.RMT.TX.Set_trans_queue_depth (Channel_Config, 1);
      ESPIDF.Driver.RMT.TX.Set_with_dma (Channel_Config, 1);
      ESPIDF.Driver.RMT.TX.rmt_new_tx_channel (Channel_Config, Channel);
      ESPIDF.Driver.RMT.Encoder.rmt_new_copy_encoder (Encoder_Config, Encoder);

      ESPIDF.Driver.RMT.TX.Set_on_trans_done
        (Callbacks, On_Transmission_Done'Access);
      ESPIDF.Driver.RMT.TX.rmt_tx_register_event_callbacks
        (Channel, Callbacks, System.Null_Address);

      ESPIDF.Driver.RMT.rmt_enable (Channel);
   end Initialize;

   -----------------
   -- On_Finished --
   -----------------

   procedure On_Finished is
   begin
      A0B.Asynchronous_Transfers.Set_Success
        (Descriptor.all, Descriptor.Length);
      Descriptor := null;

      A0B.Callbacks.Emit (Callback);
   end On_Finished;

   --------------------------
   -- On_Transmission_Done --
   --------------------------

   function On_Transmission_Done
     (TX_Channel : ESPIDF.Driver.RMT.rmt_channel_handle_t with Unreferenced;
      Event      : ESPIDF.Driver.RMT.TX.rmt_tx_done_event_data_t with
        Unreferenced;
      Context    : System.Address with Unreferenced) return ESPIDF.bool is
   begin
      --  Starting another RMT transmission is a task-context operation,
      --  redirect execution to task context.

      A0B.Callbacks.Task_Context.Emit (On_Finished_Callbacks.Create);

      return Interfaces.C.False;
   end On_Transmission_Done;

   -----------
   -- Start --
   -----------

   procedure Start
     (Descriptor :
        aliased in out A0B.Asynchronous_Transfers.Transfer_Descriptor;
      Finished   : A0B.Callbacks.Callback;
      Success    : in out Boolean)
   is
      use type A0B.Asynchronous_Transfers.Operation_State;
      use type A0B.Storage.Address;
      use type A0B.Storage.Storage_Count;
      use type System.Storage_Elements.Integer_Address;

      Config : ESPIDF.Driver.RMT.TX.rmt_transmit_config_t;

   begin
      if not Success then
         return;
      end if;

      if Descriptor.State /= A0B.Asynchronous_Transfers.Inactive
        or else Descriptor.Length <= 0
        or else Descriptor.Length mod 4 /= 0
        or else Descriptor.Buffer = A0B.Storage.Null_Address
        or else A0B.Storage.As_Integer (Descriptor.Buffer) mod 4 /= 0
        or else Descriptor.Length > A0B.Storage.Storage_Count (Natural'Last)
      then
         Success := False;

         return;
      end if;

      Callback := Finished;
      Sound.Descriptor := Descriptor'Unchecked_Access;
      A0B.Asynchronous_Transfers.Set_Active (Sound.Descriptor.all);

      ESPIDF.Driver.RMT.TX.rmt_transmit
        (Channel,
         Encoder,
         A0B.Storage.As_Address (Descriptor.Buffer),
         ESPIDF.size_t (Descriptor.Length),
         Config);
   end Start;

end Nu_Pogodi.Hardware.Sound;
