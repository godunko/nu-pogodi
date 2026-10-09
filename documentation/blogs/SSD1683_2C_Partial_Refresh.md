# Faster ePaper Refreshes for the *Nu, Pogodi!* Game

E-paper displays are notoriously slow for game animation. By modifying the controller’s update sequence, however, I managed to get the refresh speed high enough to run a recreation of the classic handheld game *Nu, Pogodi!*.

Existing drivers and libraries fell short of the required performance, prompting a closer look at the display’s inner workings. Some approaches to speeding up e-paper refreshes modify waveform lookup tables (LUTs) or booster soft-start parameters. I kept the manufacturer-provided LUTs and stock parameters for the booster, achieving the speed gains entirely by optimizing the controller’s update sequence.

> **Note:** This article focuses exclusively on monochrome (black-and-white) e-paper panels. All tests were performed on a 4.2-inch panel driven by an SSD1683 controller. Results may differ with other panels or controllers.

---

## Display Refresh Modes

For this SSD1683-based panel, two refresh modes are relevant:

- **Full refresh:** Takes a few seconds and involves several full-screen flashes. It clears accumulated ghosting and restores image quality.
- **Partial refresh:** Much faster. In the mode used here, the controller requires both the new image and the image currently displayed on the panel. Repeated partial refreshes can cause ghosting and other visible artifacts, making an occasional full refresh necessary.

*Here, “partial refresh” refers to the panel’s update waveform sequence; it does not necessarily mean that only a subset of the framebuffer is transferred over SPI.*

A typical command sequence for both update modes involves the following steps:

1. `0x24`: Write the new frame to **BW RAM**.
2. `0x26`: Write zeros to **RED RAM** for a full refresh, or write the current frame content for a partial refresh.
3. `0x22`: Set the display update control mode (`0xF7` for full refresh, `0xFF` for partial refresh).
4. `0x20`: Activate the display update sequence.

The sequence may include additional setup commands, and data transfer can be handled in various ways (polling, interrupts, or DMA). Because of this, it helps to distinguish between **data preparation/transfer time** and **refresh execution time**—the interval from sending the activation command (`0x20`) until the `BUSY` signal is released.

Refresh execution takes much longer than data preparation and transfer, so this article focuses on reducing that interval. Brief notes on data transfer and auxiliary commands will be provided where necessary.

On this panel, the activation-to-BUSY-release interval averages **2877.0 ms** for a standard full refresh. The implementation starts with a full refresh to establish a clean initial image, then uses partial refreshes during active gameplay.

With the standard update sequence, partial refresh execution takes **438.6 ms** on average (~2.3 Hz). The optimizations described in this article reduce that interval down to **262.0 ms** (~3.8 Hz) before accounting for frame preparation and data transfer over SPI.

---

## Display Update Control 2 (`0x22`) Command

The key to reducing display refresh time lies in the **Display Update Control 2 (`0x22`)** command—specifically, its parameter byte and how it is used.

Command `0x22` configures the update sequence; command `0x20` executes it. Setting `0x22` alone does not trigger a refresh.

This parameter effectively acts as a bitmask that specifies which stages of the refresh sequence the controller should execute. The [SSD1683 datasheet (Rev. 1.0, page 29)](https://files.seeedstudio.com/wiki/Other_Display/42-epaper/IC%20Driver%20SSD1683%20Datasheet.PDF#page=29) describes several parameter values and their corresponding operating sequences, but does not present an explicit bit-by-bit breakdown. Comparing these values yields the following mapping:

| Bit | Mask | Meaning |
| :--- | :--- | :--- |
| **D7** | `0x80` | Enable clock |
| **D6** | `0x40` | Enable analog power |
| **D5** | `0x20` | Load temperature value |
| **D4** | `0x10` | Load LUT from OTP |
| **D3** | `0x08` | Update mode: `0` = full refresh, `1` = differential (partial) [^1] |
| **D2** | `0x04` | Execute display waveform |
| **D1** | `0x02` | Disable analog power after update |
| **D0** | `0x01` | Disable clock after update |

[^1]: The datasheet describes D3 as selecting three-color or black/white mode. On monochrome panels, however, this bit effectively selects full or partial refresh, respectively.

As you can see, both `0xF7` and `0xFF` enable every sequence stage: clock and analog power startup, temperature loading, LUT loading, display driving, and shutdown. They differ only in `D3`, which selects the waveform mode:

- `0xF7` = `1111 0111` (all stages enabled, D3 = 0: full refresh)
- `0xFF` = `1111 1111` (all stages enabled, D3 = 1: partial refresh)

---

## Loading Temperature and LUTs Only Once

During active gameplay, frame updates run in the same refresh mode and under roughly constant ambient temperature.

The first optimization is simple: read the temperature sensor and load the corresponding LUT for partial refresh mode **once** when preparing for gameplay, then reuse the settings retained by the controller for subsequent frames while the temperature remains stable.

To read the temperature sensor and load the corresponding LUT from OTP, we send **Display Update Control 2 (`0x22`)** with parameter `0xFB` (`1111 1011`), followed by **Master Activation (`0x20`)**. This sequence enables the clock and analog circuitry, loads the temperature value and LUT, and then disables the analog circuitry and clock without updating the panel.

For subsequent frame updates, we send `0x22` with parameter `0xCF` (`1100 1111`), followed by `0x20`. This sequence enables the clock and analog circuitry, executes the display waveform, and disables both afterward, while skipping temperature and LUT loading.

Note that bit `D3` remains set to `1` in both parameters, selecting partial refresh mode for both LUT loading and display updates.

Skipping temperature and LUT loading on each frame reduces the average refresh execution time from **438.7 ms** to **433.8 ms**—a saving of **4.9 ms** (~1.12%). The one-time preparation takes **176.6 ms**.

---

## Keeping Analog Power and Clock Active

During active gameplay, frame updates are issued almost continuously. The previous optimization still enables the analog circuitry and clock before every refresh and disables them afterward. Keeping both active between frames lets us remove the shutdown stages from the update sequence.

For the one-time preparation, we send `0x22` with parameter `0xF8` (`1111 1000`), followed by `0x20`. Compared with `0xFB`, this clears `D1` and `D0`: the controller enables the clock and analog circuitry, loads the temperature value and LUT for partial refresh mode, and leaves the clock and analog circuitry active. `D2` remains clear, so this preparation pass does not update the panel. The loaded LUT is retained for subsequent refreshes.

For each subsequent partial refresh, we send `0x22` with parameter `0xCC` (`1100 1100`), followed by `0x20`.

This distinction matters: `0xCC` does not execute *only* the display waveform. It still requests the enable stages, even though the clock and analog circuitry were left active by the preceding sequence. At this point, we have removed the shutdown stages while retaining the enable stages; the next optimization will address those remaining stages.

In a separate comparison, the average activation-to-BUSY-release interval fell from **438.6 ms** with the standard `0xFF` sequence to **353.1 ms** with `0xF8` preparation and `0xCC` updates. That is a reduction of **85.5 ms** (~19.5%). The one-time `0xF8` preparation took **96.0 ms** on average.

The controller remains in this active power state between frames. At the end of the game, we send `0x22` with parameter `0x03`, followed by `0x20`, to disable the analog circuitry and clock safely.

---

## Skipping Redundant Clock and Power Activation

Once analog power and the internal clock are left running between updates, do we still need to request the clock and analog enable stages for every subsequent frame? Testing showed that re-enabling these stages was completely unnecessary.

For initialization, we send `0x22` with parameter `0xF8` (`1111 1000`), followed by `0x20`. This enables the clock and analog circuitry, loads the temperature value and LUT for partial refresh mode, and leaves the clock and analog circuitry active without updating the panel.

For each regular partial refresh, we send `0x22` with parameter `0x0C` (`0000 1100`), followed by `0x20`. Only `D3` and `D2` are set: the controller selects partial refresh mode and executes the display waveform, skipping temperature and LUT loading as well as the clock and analog enable and disable stages. The clock and analog circuitry remain active between frames.

The average activation-to-BUSY-release interval drops to **262.0 ms** (a total saving of **176.6 ms** or **40.3%** compared to standard partial refresh), corresponding to a theoretical refresh rate of approximately **3.8 Hz**. The one-time preparation takes **96.0 ms**.

---

## Conclusion

On the tested panel, separating preparation from regular refreshes reduced the average activation-to-BUSY-release interval from **438.6 ms** to **262.0 ms** — a reduction of **40.3%**, using the manufacturer-provided LUTs and stock booster parameters.

Loading the temperature and LUT once provided only a small improvement. The larger gains came from keeping the clock and analog circuitry active between frames and skipping their repeated enable and disable stages. The key was to configure the update sequence to perform only the work needed for each refresh.

This approach fits continuous gameplay in the same refresh mode and at roughly stable temperature. It still requires occasional full refreshes to clear accumulated ghosting, and the clock and analog circuitry should be disabled when gameplay ends. For this recreation of *Nu, Pogodi!*, the shorter refresh interval makes e-paper a more practical display for animation.
