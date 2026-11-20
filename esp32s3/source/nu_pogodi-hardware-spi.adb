--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Callbacks.Generic_Parameterless;
with A0B.Callbacks.Task_Context;
with A0B.Storage;
with A0B.Types;

with ESPIDF.Driver.SPI.Master;

package body Nu_Pogodi.Hardware.SPI is

   --  --  procedure Transmit
   --  --    (Descriptors : aliased in out
   --  --       A0B.Asynchronous_Transfers.Transfer_Descriptor_Array;
   --  --     Finished    : A0B.Callbacks.Callback;
   --  --     Success     : in out Boolean);
   --  --  --  The array contract is the same as for Receive below.

   Max_Transfer_Length : constant A0B.Storage.Storage_Count := 32_768;

   Device_Handle        : ESPIDF.Driver.SPI.Master.spi_device_handle_t;
   Transfer_Callback    : aliased A0B.Callbacks.Callback;
   Transmit_Transaction : aliased ESPIDF.Driver.SPI.Master.spi_transaction_t;
   Transmit_Descriptor  :
     A0B.Asynchronous_Transfers.Transfer_Descriptor_Access;
   Receive_Transaction  : aliased ESPIDF.Driver.SPI.Master.spi_transaction_t;
   Receive_Descriptor   :
     A0B.Asynchronous_Transfers.Transfer_Descriptor_Access;
   Receive_Descriptors  :
     access A0B.Asynchronous_Transfers.Transfer_Descriptor_Array;
   Receive_Index        : A0B.Types.Unsigned_32;

   procedure On_Transaction_Complete;

   package On_Transaction_Complete_Callbacks is new
     A0B.Callbacks.Generic_Parameterless (On_Transaction_Complete);

   procedure Start_Receive (Success : in out Boolean);
   --  Start receive operation

   procedure Finish_Receive;

   procedure On_post_cb
     (Trans : in out ESPIDF.Driver.SPI.Master.spi_transaction_t)
   with Convention => C;

   -----------------------
   -- Acquire_MIPI_Read --
   -----------------------

   procedure Acquire_MIPI_Read is
   begin
      ESPIDF.Driver.SPI.Master.spi_device_acquire_bus (Device_Handle);
      ESPIDF.Driver.SPI.Master.Set_override_freq_hz
        (Transmit_Transaction, 2_500_000);
      ESPIDF.Driver.SPI.Master.Set_override_freq_hz
        (Receive_Transaction, 2_500_000);
   end Acquire_MIPI_Read;

   ------------------------
   -- Acquire_MIPI_Write --
   ------------------------

   procedure Acquire_MIPI_Write is
   begin
      ESPIDF.Driver.SPI.Master.spi_device_acquire_bus (Device_Handle);
      ESPIDF.Driver.SPI.Master.Set_override_freq_hz
        (Transmit_Transaction, 20_000_000);
   end Acquire_MIPI_Write;

   --------------------
   -- Finish_Receive --
   --------------------

   procedure Finish_Receive is
   begin
      Receive_Descriptor  := null;
      Receive_Descriptors := null;
      Receive_Index       := 0;

      A0B.Callbacks.Task_Context.Emit_Once (Transfer_Callback);
   end Finish_Receive;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      use type ESPIDF.uint32_t;

      Bus_Config    : ESPIDF.Driver.SPI.spi_bus_config_t;
      Device_Config : ESPIDF.Driver.SPI.Master.spi_device_interface_config_t;

   begin
      ESPIDF.Driver.SPI.Set_mosi_io_num (Bus_Config, 11);
      ESPIDF.Driver.SPI.Set_sclk_io_num (Bus_Config, 12);
      ESPIDF.Driver.SPI.Set_max_transfer_sz
        (Bus_Config, ESPIDF.int (Max_Transfer_Length));

      ESPIDF.Driver.SPI.Master.spi_bus_initialize
        (host_id    => ESPIDF.Driver.SPI.SPI2_HOST,
         bus_config => Bus_Config,
         dma_chan   => ESPIDF.Driver.SPI.SPI_DMA_CH_AUTO);

      ESPIDF.Driver.SPI.Master.Set_clock_speed_hz (Device_Config, 20_000_000);
      ESPIDF.Driver.SPI.Master.Set_spics_io_num (Device_Config, 10);
      ESPIDF.Driver.SPI.Master.Set_queue_size (Device_Config, 2);
      ESPIDF.Driver.SPI.Master.Set_flags
        (Device_Config,
         ESPIDF.Driver.SPI.Master.SPI_DEVICE_HALFDUPLEX
         or ESPIDF.Driver.SPI.Master.SPI_DEVICE_3WIRE);
      ESPIDF.Driver.SPI.Master.Set_post_cb
        (Device_Config, On_post_cb'Access);

      ESPIDF.Driver.SPI.Master.spi_bus_add_device
        (host_id    => ESPIDF.Driver.SPI.SPI2_HOST,
         dev_config => Device_Config,
         handle     => Device_Handle);
   end Initialize;

   ----------------
   -- On_post_cb --
   ----------------

   procedure On_post_cb
     (Trans : in out ESPIDF.Driver.SPI.Master.spi_transaction_t with
        Unreferenced) is
   begin
      --  This procedure is called as the `post_cb` for SPI transactions in
      --  ISR context. It redirects the completion handling to the task
      --  context.

      A0B.Callbacks.Task_Context.Emit
        (On_Transaction_Complete_Callbacks.Create);
   end On_post_cb;

   -----------------------------
   -- On_Transaction_Complete --
   -----------------------------

   procedure On_Transaction_Complete is
      use type A0B.Types.Unsigned_32;
      use type ESPIDF.Driver.SPI.Master.spi_transaction_t_Access;
      use type ESPIDF.esp_err_t;

      Transaction : ESPIDF.Driver.SPI.Master.spi_transaction_t_Access;
      Error       : ESPIDF.esp_err_t;
      Success     : Boolean := True;

   begin
      --  This subprogram is called in the task context after a SPI transaction
      --  completes.

      Error :=
        ESPIDF.Driver.SPI.Master.spi_device_get_trans_result
          (Device_Handle, Transaction);

      if Transaction = Receive_Transaction'Access then
         if Error /= ESPIDF.ESP_OK then
            A0B.Asynchronous_Transfers.Set_Failure (Receive_Descriptor.all, 0);
            Finish_Receive;

            return;
         end if;

         A0B.Asynchronous_Transfers.Set_Success
           (Receive_Descriptor.all, Receive_Descriptor.Length);

         if Receive_Descriptors /= null
           and then Receive_Index /= Receive_Descriptors'Last
         then
            Receive_Index      := @ + 1;
            Receive_Descriptor := Receive_Descriptors (Receive_Index);

            Start_Receive (Success);

            if not Success then
               Finish_Receive;
            end if;

         else
            Finish_Receive;
         end if;

      elsif Transaction = Transmit_Transaction'Access then
         if Error /= ESPIDF.ESP_OK then
            A0B.Asynchronous_Transfers.Set_Failure
              (Transmit_Descriptor.all, 0);

         else
            A0B.Asynchronous_Transfers.Set_Success
              (Transmit_Descriptor.all, Transmit_Descriptor.Length);
         end if;

         Transmit_Descriptor := null;

         A0B.Callbacks.Task_Context.Emit_Once (Transfer_Callback);

      else
         --  Unexpected transaction pointer returned. Should not happen in
         --  normal operation.

         raise Program_Error;
      end if;
   end On_Transaction_Complete;

   -------------
   -- Receive --
   -------------

   procedure Receive
     (Descriptor :
        aliased in out A0B.Asynchronous_Transfers.Transfer_Descriptor;
      Callback   : A0B.Callbacks.Callback;
      Success    : in out Boolean)
   is
      use type A0B.Asynchronous_Transfers.Transfer_Descriptor_Access;
      use type A0B.Storage.Storage_Count;

   begin
      if not Success then
         return;
      end if;

      if Descriptor.Length > Max_Transfer_Length
        or else Receive_Descriptor /= null
        or else Transmit_Descriptor /= null
      then
         Success := False;

         return;
      end if;

      A0B.Asynchronous_Transfers.Set_Inactive (Descriptor);

      Receive_Descriptor  := Descriptor'Unchecked_Access;
      Receive_Descriptors := null;
      Receive_Index       := 0;

      Transfer_Callback := Callback;

      Start_Receive (Success);

      if not Success then
         Receive_Descriptor := null;
         A0B.Callbacks.Unset (Transfer_Callback);
      end if;
   end Receive;

   -------------
   -- Receive --
   -------------

   procedure Receive
     (Descriptors :
        aliased in out A0B.Asynchronous_Transfers.Transfer_Descriptor_Array;
      Callback    : A0B.Callbacks.Callback;
      Success     : in out Boolean)
   is
      use type A0B.Asynchronous_Transfers.Transfer_Descriptor_Access;
      use type A0B.Storage.Storage_Count;

   begin
      if not Success then
         return;
      end if;

      if Receive_Descriptor /= null or else Transmit_Descriptor /= null then
         Success := False;

         return;
      end if;

      if Descriptors'Length = 0 then
         Transfer_Callback := Callback;
         A0B.Callbacks.Task_Context.Emit_Once (Transfer_Callback);

         return;
      end if;

      --  Check descriptors

      for Descriptor of Descriptors loop
         if Descriptor = null or else Descriptor.Length > Max_Transfer_Length
         then
            Success := False;

            return;
         end if;
      end loop;

      --  Reset state of all descriptors

      for Descriptor of Descriptors loop
         A0B.Asynchronous_Transfers.Set_Inactive (Descriptor.all);
      end loop;

      Receive_Descriptors := Descriptors'Unchecked_Access;
      Receive_Index       := Descriptors'First;
      Receive_Descriptor  := Descriptors (Receive_Index);

      Transfer_Callback := Callback;

      Start_Receive (Success);

      if not Success then
         Receive_Descriptor := null;
         Receive_Descriptors := null;
         A0B.Callbacks.Unset (Transfer_Callback);
      end if;
   end Receive;

   -------------
   -- Release --
   -------------

   procedure Release is
   begin
      ESPIDF.Driver.SPI.Master.spi_device_release_bus (Device_Handle);
   end Release;

   --------------
   -- Transmit --
   --------------

   procedure Transmit
     (Descriptor :
        aliased in out A0B.Asynchronous_Transfers.Transfer_Descriptor;
      Finished   : A0B.Callbacks.Callback;
      Success    : in out Boolean)
   is
      use type A0B.Asynchronous_Transfers.Transfer_Descriptor_Access;
      use type A0B.Storage.Storage_Count;
      use type ESPIDF.esp_err_t;
      use type ESPIDF.size_t;

   begin
      if not Success then
         return;
      end if;

      if Descriptor.Length > Max_Transfer_Length
        or else Transmit_Descriptor /= null
        or else Receive_Descriptor /= null
      then
         Success := False;

         return;
      end if;

      A0B.Asynchronous_Transfers.Set_Inactive (Descriptor);

      if Descriptor.Length = 0 then
         A0B.Asynchronous_Transfers.Set_Active (Descriptor);
         A0B.Asynchronous_Transfers.Set_Success (Descriptor, 0);
         Transfer_Callback := Finished;
         A0B.Callbacks.Task_Context.Emit_Once (Transfer_Callback);

         return;
      end if;

      Transmit_Descriptor := Descriptor'Unchecked_Access;
      Transfer_Callback := Finished;

      A0B.Asynchronous_Transfers.Set_Active (Transmit_Descriptor.all);

      ESPIDF.Driver.SPI.Master.Set_tx_buffer
        (Transmit_Transaction,
         A0B.Storage.As_Address (Transmit_Descriptor.Buffer));
      ESPIDF.Driver.SPI.Master.Set_length
        (Transmit_Transaction, ESPIDF.size_t (Transmit_Descriptor.Length) * 8);
      ESPIDF.Driver.SPI.Master.Set_flags
        (Transmit_Transaction,
         ESPIDF.Driver.SPI.Master.SPI_TRANS_CS_KEEP_ACTIVE);
      ESPIDF.Driver.SPI.Master.Set_user
        (Transmit_Transaction, Transmit_Descriptor.all'Address);

      Success :=
        ESPIDF.Driver.SPI.Master.spi_device_queue_trans
          (Device_Handle, Transmit_Transaction, 0)
        = ESPIDF.ESP_OK;

      if not Success then
         A0B.Asynchronous_Transfers.Set_Failure (Transmit_Descriptor.all, 0);
         Transmit_Descriptor := null;
         A0B.Callbacks.Unset (Transfer_Callback);
      end if;
   end Transmit;

   -------------------
   -- Start_Receive --
   -------------------

   procedure Start_Receive (Success : in out Boolean) is
      use type A0B.Storage.Storage_Offset;
      use type ESPIDF.esp_err_t;
      use type ESPIDF.size_t;

   begin
      loop
         A0B.Asynchronous_Transfers.Set_Active (Receive_Descriptor.all);

         if Receive_Descriptor.Length /= 0 then
            ESPIDF.Driver.SPI.Master.Set_rx_buffer
              (Receive_Transaction,
               A0B.Storage.As_Address (Receive_Descriptor.Buffer));
            ESPIDF.Driver.SPI.Master.Set_rxlength
              (Receive_Transaction,
               ESPIDF.size_t (Receive_Descriptor.Length) * 8);
            ESPIDF.Driver.SPI.Master.Set_length (Receive_Transaction, 0);
            ESPIDF.Driver.SPI.Master.Set_flags
              (Receive_Transaction,
               ESPIDF.Driver.SPI.Master.SPI_TRANS_CS_KEEP_ACTIVE);

            Success :=
              ESPIDF.Driver.SPI.Master.spi_device_queue_trans
                (Device_Handle, Receive_Transaction, 0)
              = ESPIDF.ESP_OK;

            if not Success then
               A0B.Asynchronous_Transfers.Set_Failure
                 (Receive_Descriptor.all, 0);
            end if;

            return;
         end if;

         A0B.Asynchronous_Transfers.Set_Success (Receive_Descriptor.all, 0);

         exit when
           Receive_Descriptors = null
           or else Receive_Index = Receive_Descriptors'Last;

         Receive_Index      := @ + 1;
         Receive_Descriptor := Receive_Descriptors (Receive_Index);
      end loop;

      Finish_Receive;
   end Start_Receive;

end Nu_Pogodi.Hardware.SPI;
