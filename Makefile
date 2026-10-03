LAB ?= lab00

CROSS     ?= m68k-mackerel-elf-
CC        := $(CROSS)gcc
OBJCOPY   := $(CROSS)objcopy
VERILATOR ?= verilator
PYTHON    ?= python3

BUILD_DIR := build/$(LAB)
LAB_DIR   := labs/$(LAB)
ELF       := $(BUILD_DIR)/$(LAB).elf
BIN       := $(BUILD_DIR)/$(LAB).bin
HEX       := $(LAB_DIR)/$(LAB).hex
MAP       := $(BUILD_DIR)/$(LAB).map

CFLAGS := -m68000 -Os -ffreestanding -fno-builtin -fno-pic -fno-pie           -ffunction-sections -fdata-sections
LDFLAGS := -nostdlib -Wl,-T,labs/common/link.ld -Wl,--build-id=none            -Wl,--gc-sections -Wl,-Map,$(MAP)

FX68K := 	fx68k/fx68k.sv 	fx68k/fx68kAlu.sv 	fx68k/uaddrPla.sv

TB := 	tbench/cisc68k_tb.sv 	tbench/rom.sv 	tbench/ram.sv 	tbench/monitor.sv

VFLAGS := 	--binary 	--timing 	--trace-vcd 	--no-assert-case 	-Wno-fatal 	-Wno-BLKANDNBLK 	-Wno-UNOPTFLAT 	--top-module cisc68k_tb

.PHONY: all rom sim run clean

all: run

rom: $(HEX)

$(ELF): labs/common/start.S labs/common/link.ld $(LAB_DIR)/$(LAB).c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(LDFLAGS) labs/common/start.S $(LAB_DIR)/$(LAB).c -o $@

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

$(HEX): $(BIN) tools/helper.py
	$(PYTHON) tools/helper.py $< $@

sim: $(HEX)
	$(VERILATOR) $(VFLAGS) $(TB) $(FX68K)

run: sim
	@mkdir -p logs/$(LAB)
	./obj_dir/Vcisc68k_tb | tee logs/$(LAB)/$(LAB).log
	@mv -f cisc68k.vcd logs/$(LAB)/$(LAB).vcd
	@echo "VCD: logs/$(LAB)/$(LAB).vcd"

clean:
	rm -rf build obj_dir cisc68k.vcd
