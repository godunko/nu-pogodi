--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

--  Reads use full-duplex SPI with MISO and MOSI connected to SDA.
--  The read path requires MOSI to be released before the display drives SDA.

pragma Ada_2022;

with System.Storage_Elements;

with A0B.ARMv7M.NVIC_Utilities;

with A0B.STM32F401.SVD.DMA;
with A0B.STM32F401.SVD.RCC;
with A0B.STM32F401.SVD.SPI;

with Nu_Pogodi.Hardware.Pin_Control;

package body Nu_Pogodi.Hardware.SPI is

   procedure DMA2_Stream3_Handler
     with Export, Convention => C, External_Name => "DMA2_Stream3_Handler";

   Dummy_Byte : aliased constant A0B.Types.Unsigned_8 := 16#FF#;
   --  Repeated TX DMA source in receive mode.

   Transmit_Callback : A0B.Callbacks.Callback;

   -----------------------
   -- Acquire_MIPI_Read --
   -----------------------

   procedure Acquire_MIPI_Read is
   begin
      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR1 :=
        (@ with delta
           BIDIMODE => True,    --  1: 1-line bidirectional data mode selected
           BIDIOE   => True,    --  1: Output enabled (transmit-only mode)
           CRCEN    => False,   --  0: CRC calculation disabled
           CRCNEXT  => False,
           DFF      => False,
           --  0: 8-bit data frame format is selected for
           --  transmission/reception
           LSBFIRST => True,    --  1: LSB transmitted first
           SPE      => False,   --  0: Peripheral disabled
           BR       => 2#100#,  --  100: fPCLK/32
           CPOL     => False,   --  0: CK to 0 when idle
           CPHA     => False);
           --  0: The first clock transition is the first data capture edge
      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR2 :=
        (@ with delta
           FRF => False);  --  0: SPI Motorola mode
   end Acquire_MIPI_Read;

   ------------------------
   -- Acquire_MIPI_Write --
   ------------------------

   procedure Acquire_MIPI_Write is
   begin
      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR1 :=
        (@ with delta
           BIDIMODE => True,    --  1: 1-line bidirectional data mode selected
           BIDIOE   => True,    --  1: Output enabled (transmit-only mode)
           CRCEN    => False,   --  0: CRC calculation disabled
           CRCNEXT  => False,
           DFF      => False,
           --  0: 8-bit data frame format is selected for
           --  transmission/reception
           LSBFIRST => True,    --  1: LSB transmitted first
           SPE      => False,   --  0: Peripheral disabled
           BR       => 2#001#,  --  001: fPCLK/4
           CPOL     => False,   --  0: CK to 0 when idle
           CPHA     => False);
           --  0: The first clock transition is the first data capture edge
      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR2 :=
        (@ with delta
           FRF => False);  --  0: SPI Motorola mode
   end Acquire_MIPI_Write;

   --------------------------
   -- DMA2_Stream3_Handler --
   --------------------------

   procedure DMA2_Stream3_Handler is
   begin
      if A0B.STM32F401.SVD.DMA.DMA2_Periph.LISR.TCIF3 then
         A0B.STM32F401.SVD.DMA.DMA2_Periph.LIFCR :=
           (CTCIF3 => True, others => <>);

         A0B.STM32F401.SVD.SPI.SPI1_Periph.CR2.TXDMAEN := False;
         --  Turn off use of DMA for SPI transmission

         --  Sequence below is necessary to complete data transfer from the
         --  shift register.

         while not A0B.STM32F401.SVD.SPI.SPI1_Periph.SR.TXE loop
            null;
         end loop;

         while A0B.STM32F401.SVD.SPI.SPI1_Periph.SR.BSY loop
            null;
         end loop;

         Nu_Pogodi.Hardware.Pin_Control.Configure_SPI1_MOSI_Input;
         --  Transfer completed, "disconnect" MOSI from SDA line.

         --  Now transfer is completed, emit callback.

         A0B.Callbacks.Emit_Once (Transmit_Callback);
      end if;
   end DMA2_Stream3_Handler;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      A0B.STM32F401.SVD.RCC.RCC_Periph.AHB1ENR.DMA2EN := True;
      A0B.STM32F401.SVD.RCC.RCC_Periph.APB2ENR.SPI1EN := True;

      --  Basic configuration of DMA for transmit

      A0B.STM32F401.SVD.DMA.DMA2_Periph.S3CR :=
        (@ with delta
           EN     => False,    --  0: Stream disabled
           DMEIE  => False,    --  0: DME interrupt disabled
           TEIE   => False,    --  0: TE interrupt disabled
           HTIE   => False,    --  0: HT interrupt disabled
           TCIE   => False,    --  0: TC interrupt disabled
           PFCTRL => False,    --  0: The DMA is the flow controller
           DIR    => 2#01#,    --  01: Memory-to-peripheral
           CIRC   => False,    --  0: Circular mode disabled
           PINC   => False,    --  0: Peripheral address pointer is fixed
           MINC   => True,
           --  1: Memory address pointer is incremented after each data
           --  transfer (increment is done according to MSIZE)
           PSIZE  => 2#00#,    --  00: Byte (8-bit)
           MSIZE  => 2#00#,    --  00: Byte (8-bit)
           PL     => 2#10#,    --  10: High
           DBM    => False,
           --  0: No buffer switching at the end of transfer
           PBURST => 2#00#,    --  00: single transfer
           MBURST => 2#00#,    --  00: single transfer
           CHSEL  => 2#011#);  --  011: channel 3 selected
      A0B.STM32F401.SVD.DMA.DMA2_Periph.S3PAR :=
        A0B.Types.Unsigned_32
          (System.Storage_Elements.To_Integer
             (A0B.STM32F401.SVD.SPI.SPI1_Periph.DR'Address));

      --  Basic configuration of DMA for receive

      A0B.STM32F401.SVD.DMA.DMA2_Periph.S0CR :=
        (@ with delta
           EN     => False,    --  0: Stream disabled
           DMEIE  => False,    --  0: DME interrupt disabled
           TEIE   => False,    --  0: TE interrupt disabled
           HTIE   => False,    --  0: HT interrupt disabled
           TCIE   => False,    --  0: TC interrupt disabled
           PFCTRL => False,    --  0: The DMA is the flow controller
           DIR    => 2#00#,    --  00: Peripheral-to-memory
           CIRC   => False,    --  0: Circular mode disabled
           PINC   => False,    --  0: Peripheral address pointer is fixed
           MINC   => True,
           --  1: Memory address pointer is incremented after each data
           --  transfer (increment is done according to MSIZE)
           PSIZE  => 2#00#,    --  00: Byte (8-bit)
           MSIZE  => 2#00#,    --  00: Byte (8-bit)
           PL     => 2#10#,    --  10: High
           DBM    => False,
           --  0: No buffer switching at the end of transfer
           PBURST => 2#00#,    --  00: single transfer
           MBURST => 2#00#,    --  00: single transfer
           CHSEL  => 2#011#);  --  011: channel 3 selected
      A0B.STM32F401.SVD.DMA.DMA2_Periph.S0PAR :=
        A0B.Types.Unsigned_32
          (System.Storage_Elements.To_Integer
             (A0B.STM32F401.SVD.SPI.SPI1_Periph.DR'Address));

      --  Minimal configuration of SPI:
      --   * disable SPI
      --   * disable Software Slave Management
      --   * take control over NSS
      --   * disable interrupts
      --   * disable DMA

      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR1 :=
        (@ with delta
           SSM      => False,
           SSI      => False,
           SPE      => False,
           MSTR     => True);
      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR2 :=
        (@ with delta
           SSOE    => True,
           TXEIE   => False,
           RXNEIE  => False,
           ERRIE   => False,
           TXDMAEN => False,
           RXDMAEN => False);

      Nu_Pogodi.Hardware.Pin_Control.Configure_SPI1_Pins;

      --  Configure NVIC

      A0B.ARMv7M.NVIC_Utilities.Clear_Pending (A0B.STM32F401.DMA2_Stream3);
      A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt (A0B.STM32F401.DMA2_Stream3);
   end Initialize;

   -------------
   -- Receive --
   -------------

   procedure Receive
     (Data              : out A0B.Types.Arrays.Unsigned_8_Array;
      Ignore_First_Byte : Boolean := False)
   is
      Discard : A0B.Types.Unsigned_16 with Unreferenced;

   begin
      if Data'Length = 0 then
         return;
      end if;

      --  The command was sent in bidirectional transmit-only mode, so there
      --  is no command echo to discard. Switch to full duplex with SPI still
      --  enabled to keep CS low; MOSI is already disconnected from SDA.

      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR1 :=
        (@ with delta
           BIDIMODE => False,  --  0: 2-line unidirectional data mode selected
           RXONLY   => False,  --  0: Full duplex (Transmit and receive)
           SPE      => True);  --  1: Peripheral enabled

      if Ignore_First_Byte then
         while not A0B.STM32F401.SVD.SPI.SPI1_Periph.SR.TXE loop
            null;
         end loop;

         A0B.STM32F401.SVD.SPI.SPI1_Periph.DR :=
           (DR => 16#FF#, Reserved_16_31 => 0);

         while not A0B.STM32F401.SVD.SPI.SPI1_Periph.SR.RXNE loop
            null;
         end loop;

         Discard := A0B.STM32F401.SVD.SPI.SPI1_Periph.DR.DR;
      end if;

      if Data'Length >= 5 then
         A0B.STM32F401.SVD.SPI.SPI1_Periph.CR2 :=
           (@ with delta
              RXDMAEN => True,   --  1: Rx buffer DMA enabled
              TXDMAEN => True);  --  1: Tx buffer DMA enabled

         --  Configure RX DMA to receive data.

         A0B.STM32F401.SVD.DMA.DMA2_Periph.LIFCR :=
           (CFEIF0  => True,
            CDMEIF0 => True,
            CTEIF0  => True,
            CHTIF0  => True,
            CTCIF0  => True,
            others  => <>);
         A0B.STM32F401.SVD.DMA.DMA2_Periph.S0M0AR :=
           A0B.Types.Unsigned_32
             (System.Storage_Elements.To_Integer
                (Data (Data'First)'Address));
         A0B.STM32F401.SVD.DMA.DMA2_Periph.S0NDTR :=
           (NDT            => A0B.Types.Unsigned_16 (Data'Length),
            Reserved_16_31 => 0);
         A0B.STM32F401.SVD.DMA.DMA2_Periph.S0CR.EN := True;

         --  Configure TX DMA to transfer dummy byte.

         A0B.STM32F401.SVD.DMA.DMA2_Periph.LIFCR :=
           (CFEIF3  => True,
            CDMEIF3 => True,
            CTEIF3  => True,
            CHTIF3  => True,
            CTCIF3  => True,
            others  => <>);
         A0B.STM32F401.SVD.DMA.DMA2_Periph.S3M0AR :=
           A0B.Types.Unsigned_32
             (System.Storage_Elements.To_Integer (Dummy_Byte'Address));
         A0B.STM32F401.SVD.DMA.DMA2_Periph.S3NDTR :=
           (NDT            => A0B.Types.Unsigned_16 (Data'Length),
            Reserved_16_31 => 0);
         A0B.STM32F401.SVD.DMA.DMA2_Periph.S3CR :=
           (@ with delta
              MINC => False,   --  0: Memory address pointer is fixed
              TCIE => False,   --  0: TC interrupt disabled
              EN   => True);   --  1: Stream enabled

         while not A0B.STM32F401.SVD.DMA.DMA2_Periph.LISR.TCIF0 loop
            null;
         end loop;

         A0B.STM32F401.SVD.SPI.SPI1_Periph.CR2.TXDMAEN := False;
         A0B.STM32F401.SVD.SPI.SPI1_Periph.CR2.RXDMAEN := False;

      else
         for Byte of Data loop
            while not A0B.STM32F401.SVD.SPI.SPI1_Periph.SR.TXE loop
               null;
            end loop;

            A0B.STM32F401.SVD.SPI.SPI1_Periph.DR :=
              (DR => 16#FF#, Reserved_16_31 => 0);

            while not A0B.STM32F401.SVD.SPI.SPI1_Periph.SR.RXNE loop
               null;
            end loop;

            Byte :=
              A0B.Types.Unsigned_8 (A0B.STM32F401.SVD.SPI.SPI1_Periph.DR.DR);
         end loop;
      end if;

      while not A0B.STM32F401.SVD.SPI.SPI1_Periph.SR.TXE loop
         null;
      end loop;

      while A0B.STM32F401.SVD.SPI.SPI1_Periph.SR.BSY loop
         null;
      end loop;
   end Receive;

   -------------
   -- Receive --
   -------------

   procedure Receive
     (Buffer            : in out A0B.Buffers.Abstract_Buffer'Class;
      Ignore_First_Byte : Boolean := False)
   is
      Length : constant A0B.Buffers.Storage_Count := Buffer.Expected_Length;
      Data   : A0B.Types.Arrays.Unsigned_8_Array
        (1 .. A0B.Types.Unsigned_32 (Length))
          with Import, Address => Buffer.Address;

   begin
      Receive (Data, Ignore_First_Byte);
      Buffer.Set_Actual_Length (Length);
   end Receive;

   -------------
   -- Release --
   -------------

   procedure Release is
   begin
      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR1.SPE := False;
      --  XXX This might be incorrect, TRE/BSY might be needed to check first.
   end Release;

   --------------
   -- Transmit --
   --------------

   procedure Transmit (Command : A0B.Types.Unsigned_8) is
   begin
      Nu_Pogodi.Hardware.Pin_Control.Configure_SPI1_MOSI_Output;

      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR1 :=
        (@ with delta
           BIDIMODE => True,   --  1: 1-line bidirectional data mode selected
           BIDIOE   => True,   --  1: Output enabled (transmit-only mode)
           SPE      => True);  --  1: Peripheral enabled

      A0B.STM32F401.SVD.SPI.SPI1_Periph.DR :=
        (DR             => A0B.Types.Unsigned_16 (Command),
         Reserved_16_31 => 0);

      while not A0B.STM32F401.SVD.SPI.SPI1_Periph.SR.TXE loop
         null;
      end loop;

      while A0B.STM32F401.SVD.SPI.SPI1_Periph.SR.BSY loop
         null;
      end loop;

      --  Release SDA after every transmission. Keep SPI enabled so that NSS
      --  remains asserted for the following data transfer.

      Nu_Pogodi.Hardware.Pin_Control.Configure_SPI1_MOSI_Input;
   end Transmit;

   --------------
   -- Transmit --
   --------------

   procedure Transmit
     (Buffer   : A0B.Buffers.Abstract_Buffer'Class;
      Callback : A0B.Callbacks.Callback;
      Success  : in out Boolean)
   is
      use type A0B.Buffers.Storage_Count;

   begin
      if not Success then
         return;
      end if;

      if Buffer.Length > 65_535 then
         --  Buffer is too large to be transferred by single DMA transfer.

         Success := False;

         return;
      end if;

      Transmit_Callback := Callback;

      Nu_Pogodi.Hardware.Pin_Control.Configure_SPI1_MOSI_Output;

      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR1 :=
        (@ with delta
           BIDIMODE => True,   --  1: 1-line bidirectional data mode selected
           BIDIOE   => True,   --  1: Output enabled (transmit-only mode)
           SPE      => True);  --  1: Peripheral enabled
      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR2.TXDMAEN := True;

      A0B.STM32F401.SVD.DMA.DMA2_Periph.S3M0AR :=
        A0B.Types.Unsigned_32
          (System.Storage_Elements.To_Integer (Buffer.Address));
      A0B.STM32F401.SVD.DMA.DMA2_Periph.S3NDTR :=
        (NDT            => A0B.Types.Unsigned_16 (Buffer.Length),
         Reserved_16_31 => 0);
      A0B.STM32F401.SVD.DMA.DMA2_Periph.LIFCR :=
        (CFEIF3  => True,
         CDMEIF3 => True,
         CTEIF3  => True,
         CHTIF3  => True,
         CTCIF3  => True,
         others  => <>);
      A0B.STM32F401.SVD.DMA.DMA2_Periph.S3CR :=
        (@ with delta
           MINC => True,
           --  1: Memory address pointer is incremented after each data
           --  transfer (increment is done according to MSIZE)
           TCIE => True,   --  1: TC interrupt enabled
           EN   => True);  --  1: Stream enabled
   end Transmit;

end Nu_Pogodi.Hardware.SPI;
