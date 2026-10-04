--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.STM32F401.SVD.RCC;
with A0B.STM32F401.SVD.SPI;
with A0B.Types.Arrays;

with Nu_Pogodi.Hardware.Pin_Control;

package body Nu_Pogodi.Hardware.SPI is

   -----------------------
   -- Acquire_MIPI_Read --
   -----------------------

   procedure Acquire_MIPI_Read is
   begin
      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR1 :=
        (@ with delta
           BIDIMODE => True,    --  1: 1-line bidirectional data mode selected
           CRCEN    => False,   --  0: CRC calculation disabled
           CRCNEXT  => False,
           DFF      => False,
           --  0: 8-bit data frame format is selected for
           --  transmission/reception
           LSBFIRST => False,   --  0: MSB transmitted first
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
           CRCEN    => False,   --  0: CRC calculation disabled
           CRCNEXT  => False,
           DFF      => False,
           --  0: 8-bit data frame format is selected for
           --  transmission/reception
           LSBFIRST => False,   --  0: MSB transmitted first
           SPE      => False,   --  0: Peripheral disabled
           BR       => 2#001#,  --  001: fPCLK/4
           CPOL     => False,   --  0: CK to 0 when idle
           CPHA     => False);
           --  0: The first clock transition is the first data capture edge
      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR2 :=
        (@ with delta
           FRF => False);  --  0: SPI Motorola mode
   end Acquire_MIPI_Write;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      A0B.STM32F401.SVD.RCC.RCC_Periph.APB2ENR.SPI1EN := True;

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
   end Initialize;

   -------------
   -- Receive --
   -------------

   procedure Receive (Data : out A0B.Types.Unsigned_8) is
   begin
      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR1 :=
        (@ with delta
           BIDIOE => False);  --  0: Output disabled (receive-only mode)

      while not A0B.STM32F401.SVD.SPI.SPI1_Periph.SR.RXNE loop
         null;
      end loop;

      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR1 :=
        (@ with delta SPE => False);  --  0: Peripheral disabled

      Data := A0B.Types.Unsigned_8 (A0B.STM32F401.SVD.SPI.SPI1_Periph.DR.DR);
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
      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR1 :=
        (@ with delta
           BIDIOE => True);  --  1: Output enabled (transmit-only mode)

      A0B.STM32F401.SVD.SPI.SPI1_Periph.CR1 :=
        (@ with delta SPE => True);  --  1: Peripheral enabled

      A0B.STM32F401.SVD.SPI.SPI1_Periph.DR :=
        (DR             => A0B.Types.Unsigned_16 (Command),
         Reserved_16_31 => 0);

      while not A0B.STM32F401.SVD.SPI.SPI1_Periph.SR.TXE loop
         null;
      end loop;

      while A0B.STM32F401.SVD.SPI.SPI1_Periph.SR.BSY loop
         null;
      end loop;
   end Transmit;

   --------------
   -- Transmit --
   --------------

   procedure Transmit (Buffer : A0B.Buffers.Abstract_Buffer'Class) is
      Data : constant A0B.Types.Arrays.Unsigned_8_Array
        (1 .. A0B.Types.Unsigned_32 (Buffer.Length))
        with Import, Address => Buffer.Address;

   begin
      for Item of Data loop
         A0B.STM32F401.SVD.SPI.SPI1_Periph.DR :=
           (DR             => A0B.Types.Unsigned_16 (Item),
            Reserved_16_31 => 0);

         while not A0B.STM32F401.SVD.SPI.SPI1_Periph.SR.TXE loop
            null;
         end loop;
      end loop;

      while A0B.STM32F401.SVD.SPI.SPI1_Periph.SR.BSY loop
         null;
      end loop;
   end Transmit;

end Nu_Pogodi.Hardware.SPI;
