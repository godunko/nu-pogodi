
all: build_weact_blackpill_stm32f401

build_weact_blackpill_stm32f401: build_a0b_tools
	alr -C weact_blackpill_stm32f401 build
	ls -l bin

build_a0b_tools:
	alr -C ../a0b-tools build

openocd_weact_blackpill_stm32f401:
	openocd -f weact_blackpill_stm32f401/openocd.cfg

gdb_weact_blackpill_stm32f401:
	eval `alr -C weact_blackpill_stm32f401 printenv` && arm-eabi-gdb --command=weact_blackpill_stm32f401/gdbinit bin/nu_pogodi_weact_blackpill_stm32f401.elf
