--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Storage;

with ESPIDF.Driver.SPI.Master;

package body Nu_Pogodi.Hardware.SPI is

   --  --  procedure Transmit
   --  --    (Descriptors : aliased in out
   --  --       A0B.Asynchronous_Transfers.Transfer_Descriptor_Array;
   --  --     Finished    : A0B.Callbacks.Callback;
   --  --     Success     : in out Boolean);
   --  --  --  The array contract is the same as for Receive below.

   Device_Handle        : ESPIDF.Driver.SPI.Master.spi_device_handle_t;
   Transmit_Transaction : aliased ESPIDF.Driver.SPI.Master.spi_transaction_t;
   Transmit_Descriptor  : A0B.Asynchronous_Transfers.Transfer_Descriptor_Access;
   Transmit_Callback    : aliased A0B.Callbacks.Callback;

   procedure Transaction_Complete
     (Trans : in out ESPIDF.Driver.SPI.Master.spi_transaction_t)
   with Convention => C;

   -----------------------
   -- Acquire_MIPI_Read --
   -----------------------

   procedure Acquire_MIPI_Read is
   begin
      ESPIDF.Driver.SPI.Master.spi_device_acquire_bus (Device_Handle);
   end Acquire_MIPI_Read;

   ------------------------
   -- Acquire_MIPI_Write --
   ------------------------

   procedure Acquire_MIPI_Write is
   begin
      ESPIDF.Driver.SPI.Master.spi_device_acquire_bus (Device_Handle);
   end Acquire_MIPI_Write;

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

      ESPIDF.Driver.SPI.Master.spi_bus_initialize
        (host_id    => ESPIDF.Driver.SPI.SPI2_HOST,
         bus_config => Bus_Config,
         dma_chan   => ESPIDF.Driver.SPI.SPI_DMA_CH_AUTO);

      ESPIDF.Driver.SPI.Master.Set_clock_speed_hz
        (Device_Config, 20_000_000);
      ESPIDF.Driver.SPI.Master.Set_spics_io_num (Device_Config, 10);
      ESPIDF.Driver.SPI.Master.Set_queue_size (Device_Config, 2);
      ESPIDF.Driver.SPI.Master.Set_flags
        (Device_Config,
         ESPIDF.Driver.SPI.Master.SPI_DEVICE_HALFDUPLEX
         or ESPIDF.Driver.SPI.Master.SPI_DEVICE_3WIRE);
      ESPIDF.Driver.SPI.Master.Set_post_cb
        (Device_Config, Transaction_Complete'Access);

      ESPIDF.Driver.SPI.Master.spi_bus_add_device
        (host_id    => ESPIDF.Driver.SPI.SPI2_HOST,
         dev_config => Device_Config,
         handle     => Device_Handle);
   end Initialize;

   -------------
   -- Receive --
   -------------

   procedure Receive
     (Descriptor :
        aliased in out A0B.Asynchronous_Transfers.Transfer_Descriptor;
      Callback   : A0B.Callbacks.Callback;
      Success    : in out Boolean) is
   begin
      raise Program_Error;
   end Receive;

   -------------
   -- Receive --
   -------------

   procedure Receive
     (Descriptors :
        aliased in out A0B.Asynchronous_Transfers.Transfer_Descriptor_Array;
      Callback    : A0B.Callbacks.Callback;
      Success     : in out Boolean) is
   begin
      raise Program_Error;
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
      use type ESPIDF.size_t;

   begin
      if not Success then
         return;
      end if;

      Transmit_Descriptor := Descriptor'Unchecked_Access;
      Transmit_Callback := Finished;

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

      ESPIDF.Driver.SPI.Master.spi_device_queue_trans
        (Device_Handle, Transmit_Transaction, 0);
   end Transmit;

   --------------------------
   -- Transaction_Complete --
   --------------------------

   procedure Transaction_Complete
     (Trans : in out ESPIDF.Driver.SPI.Master.spi_transaction_t)
   is
      use type A0B.Asynchronous_Transfers.Transfer_Descriptor_Access;
      use type ESPIDF.uint32_t;

      Descritor : aliased A0B.Asynchronous_Transfers.Transfer_Descriptor
      with Import, Address => ESPIDF.Driver.SPI.Master.Get_user (Trans);
      Flags     : constant ESPIDF.uint32_t :=
        ESPIDF.Driver.SPI.Master.Get_flags (Trans);

   begin
      if Descritor'Unchecked_Access = Transmit_Descriptor then
         if (Flags and ESPIDF.Driver.SPI.Master.SPI_TRANS_DMA_TX_FAIL) /= 0
         then
            A0B.Asynchronous_Transfers.Set_Failure
              (Transmit_Descriptor.all, 0);

         else
            A0B.Asynchronous_Transfers.Set_Success
              (Transmit_Descriptor.all, Transmit_Descriptor.Length);
         end if;

         Transmit_Descriptor := null;
         A0B.Callbacks.Emit_Once (Transmit_Callback);

      else
         raise Program_Error;
      end if;
   end Transaction_Complete;

end Nu_Pogodi.Hardware.SPI;
