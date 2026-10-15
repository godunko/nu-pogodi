
# STM32F401 SPI Limitations and Workarounds for Half-Duplex Display Communication

My setup uses a WeAct Studio Black Pill STM32F401 board and a WeAct Studio 4.2-inch, 400×300 black-and-white e-paper display with an SSD1683 controller. The current firmware configures SPI1 with 8-bit frames and an 80 MHz peripheral clock, and uses SCK at 20 MHz for write transactions and 2.5 MHz for read transactions, including their command phase. These are the settings used in this project, rather than general speed recommendations for other displays or wiring arrangements.

The display connects via a standard 4-wire MIPI DBI Type C interface. Its four interface signals are:

- **CSX** — Chip Select
- **SCL** — Serial Clock
- **SDA** — Serial Data Input/Output
- **D/CX** — Data/Command

The display also uses two additional control signals, which are not included in the four-wire count:

- **RESX** — Reset
- **BUSY** — Busy

The `SDA` data line is used for bidirectional communication.

This mode of operation corresponds to the *bidirectional* mode in the STM32F401 SPI controller. In master bidirectional receive mode (`MSTR=1`, `BIDIMODE=1`, `BIDIOE=0`), the controller generates clock pulses continuously while reception is enabled. There is no hardware frame counter to stop reception after a specified number of bytes.

Reception can be stopped correctly, but clearing `SPE` requires the timing-sensitive sequence described in [RM0368, Section 20.3.8](https://www.st.com/resource/en/reference_manual/rm0368-stm32f401xbc-and-stm32f401xde-advanced-armbased-32bit-mcus-stmicroelectronics.pdf). Simply waiting until the final byte has been received before disabling SPI can allow another frame to start, producing unwanted clock pulses. Failing to read received data in time can also cause an overrun. This makes receiving an exact number of bytes less straightforward than in full-duplex mode.

To overcome this drawback, I use a combination of modes: **bidirectional transmit-only** (`BIDIMODE=1`, `BIDIOE=1`) for sending data and **full-duplex** (`BIDIMODE=0`, `RXONLY=0`) for receiving data. In master mode, transmission uses MOSI, while full-duplex reception uses the separate MISO pin. The display, however, uses a single bidirectional `SDA` line.

The solution is to tie the MISO and MOSI pins together through a current-limiting resistor. I used 470 Ω in the setup described above; this value should be checked for the intended clock speed, wiring, and load. Since open-drain mode with a pull-up resistor on MOSI did not achieve the required speeds in my setup, I resorted to standard push-pull mode and switched the MOSI GPIO line to input mode (high-impedance) during data reads.

```text
PA7 (MOSI) ──[470 Ω]──┬── Display SDA
PA6 (MISO) ───────────┘
```

To read data after sending a command:

1. Wait until `TXE=1`, then until `BSY=0`, so that the command has fully left the SPI peripheral.
2. Switch the MOSI GPIO pin to input mode to release `SDA` before the display starts driving it.
3. Switch SPI to full-duplex mode (`BIDIMODE=0`, `RXONLY=0`).
4. Set the **D/CX** line high to select data mode.
5. Transmit dummy bytes to generate the clock pulses and read the corresponding bytes from MISO.

Keep `CSX` low throughout the command and read phases.

Each dummy byte transmitted by the MCU generates eight clock pulses and receives one byte from the display. With MOSI configured as an input, the transmitted value does not affect `SDA`. If MOSI is instead kept in alternate-function open-drain mode, transmit `0xFF` to keep its output released throughout reception.

Some display read commands require an initial dummy byte before valid response data. Generate the clock pulses for this byte as well, but discard the received value. This command-specific dummy byte is separate from the dummy bytes transmitted by the MCU to generate clocks.
