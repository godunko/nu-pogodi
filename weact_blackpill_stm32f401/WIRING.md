# Electrical connections

Board: WeAct Black Pill STM32F401.
Display: WeAct Studio 4.2" B/W ePaper with an SSD1683 controller.

The tables list board pin labels (`A1`, `B12`) and microcontroller GPIO names
(`PA1`, `PB12`).

## Display

| Board pin | GPIO | Display connection |
|---|---|---|
| A1 | PA1 | BUSY |
| A2 | PA2 | RES |
| A3 | PA3 | D/C |
| A4 | PA4, SPI1 NSS | CS |
| A5 | PA5, SPI1 SCK | SCL |
| A6 | PA6, SPI1 MISO | Directly to SDA |
| A7 | PA7, SPI1 MOSI | To PA6 through a 470 Ω resistor |

SDA denotes the shared SPI data line used for both writes and reads.

### Data line

The display connects to the MISO side. A 470 Ω resistor connects PA7 to PA6:

```text
PA7 (MOSI) ──[470 Ω]──┬── Display SDA
PA6 (MISO) ───────────┘
```

During writes, PA7 sends data through the resistor. During reads, the display
drives PA6 directly; the firmware switches PA7 to input mode to release the
line.

## Keyboard

| Board pin | GPIO | Keyboard signal | In-game action |
|---|---|---|---|
| B12 | PB12 | UP | Top left |
| B13 | PB13 | DOWN | Bottom right |
| B14 | PB14 | LEFT | Bottom left |
| B15 | PB15 | RIGHT | Top right |
| B10 | PB10 | MIDDLE | Unused |
| B8 | PB8 | SET | Unused |
| B9 | PB9 | RESET | Unused |

The inputs use internal pull-ups. A pressed button produces a low level by
connecting its input to GND.

```text
PBx ──[button]── GND
```

The keyboard RESET signal uses the separate PB9 input, not the board's NRST
reset pin.

## Power

Both the board and the display module are powered from the same 5 V supply.
Connect the supply to the board's 5V pin and the display module's VCC pin.
Connect the board, display module, and keyboard to a common GND.
