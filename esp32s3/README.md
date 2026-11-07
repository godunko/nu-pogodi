# Nu Pogodi: ESP32-S3 Ada application

Minimal ESP-IDF application with an Ada entry point in `source/main.adb`.
ESP-IDF builds the firmware; Alire generates and builds the Ada runtime and
partially linked `.objs/app_main.o` used by the final ESP-IDF link.

## Requirements

- ESP-IDF 6.1 with ESP32-S3 tools and its Python environment.
- Alire on `PATH`, GNAT 16, GPRbuild, a host C compiler, Make, and Git.
- Network access for the initial dependency setup.

## Local dependencies

The initial setup has already cloned these repositories into `crates/` and
built both tools. Local clones and generated artifacts are ignored by Git.
To recreate the dependencies in a fresh checkout:

```sh
mkdir -p crates
git clone https://github.com/godunko/a0b-tools.git crates/a0b-tools
git clone https://github.com/godunko/xtensa-dynconfig.git crates/xtensa-dynconfig
git clone https://github.com/godunko/espidf_gnat_runtime.git crates/espidf_gnat_runtime
git clone -b gnat-fsf-16 https://github.com/alire-project/bb-runtimes.git crates/bb-runtimes
alr -n -C crates/a0b-tools build
alr -n -C crates/xtensa-dynconfig build
```

GNAT 16 and `bb-runtimes` branch `gnat-fsf-16` match the current upstream
ESP32-S3 template. `XTENSA_GNU_CONFIG` in `alire.toml` selects the ESP32-S3
configuration plugin built by `xtensa-dynconfig`.

## Build

Activate the installed ESP-IDF environment in each new shell. On this machine:

```sh
. "$HOME/.espressif/v6.1/esp-idf/export.sh"
idf.py build
```

`sdkconfig.defaults` selects ESP32-S3 and newlib, which the Ada runtime needs.
When reusing an existing configuration for another chip, run
`idf.py set-target esp32s3` before building.

Build the application through ESP-IDF: the component CMake file invokes Alire
with the SDK's C preprocessor definitions and include directories.

## Flash and monitor

With the board connected, choose its serial port:

```sh
idf.py -p /dev/ttyACM0 flash monitor
```

Expected application output:

```text
Hello, Ada world! Nu Pogodi on ESP32-S3.
```

In VS Code, the ESP-IDF extension can build, flash, and monitor the project.
The Ada & SPARK extension provides Ada editing support.

## Sources

- Scaffolding skill: <https://github.com/godunko/ada_espidf_skills>
- Reference template: <https://github.com/godunko/esp32s3_template>
- Runtime: <https://github.com/godunko/espidf_gnat_runtime>
