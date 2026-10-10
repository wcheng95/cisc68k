LAB ?= lab00
MODE ?= trace

ifeq ($(filter $(MODE),trace vcd both none),)
$(error MODE must be one of: trace vcd both none)
endif

RUN_ARGS :=
ifeq ($(MODE),trace)
RUN_ARGS := +trace=logs/$(LAB)/$(LAB).trace
else ifeq ($(MODE),vcd)
RUN_ARGS := +vcd=logs/$(LAB)/$(LAB).vcd
else ifeq ($(MODE),both)
RUN_ARGS := +trace=logs/$(LAB)/$(LAB).trace +vcd=logs/$(LAB)/$(LAB).vcd
endif

CROSS     ?= m68k-mackerel-elf-
CC        := $(CROSS)gcc
OBJCOPY   := $(CROSS)objcopy
OBJDUMP   := $(CROSS)objdump
VERILATOR ?= verilator
PYTHON    ?= python3

BUILD_DIR := build/$(LAB)
LAB_DIR   := labs/$(LAB)
LAB_SRC   := $(firstword $(wildcard $(LAB_DIR)/$(LAB).S $(LAB_DIR)/$(LAB).c))
ELF       := $(BUILD_DIR)/$(LAB).elf
BIN       := $(BUILD_DIR)/$(LAB).bin
HEX       := $(LAB_DIR)/$(LAB).hex
MAP       := $(BUILD_DIR)/$(LAB).map
ROM_LINK  := labs/rom.hex

CFLAGS := -m68000 -Os -ffreestanding -fno-builtin -fno-pic -fno-pie \
          -ffunction-sections -fdata-sections

LDFLAGS := -nostdlib -Wl,-T,labs/common/link.ld -Wl,--build-id=none \
           -Wl,--gc-sections -Wl,-Map,$(MAP)

FX68K := \
	fx68k/fx68k.sv \
	fx68k/fx68kAlu.sv \
	fx68k/uaddrPla.sv

TB := \
	tbench/cisc68k_tb.sv \
	tbench/rom.sv \
	tbench/ram.sv \
	tbench/monitor.sv \
	tbench/irq_autovec.sv

VFLAGS := \
	--binary \
	--timing \
	--trace-vcd \
	--no-assert-case \
	-Wno-fatal \
	-Wno-BLKANDNBLK \
	-Wno-UNOPTFLAT \
	--top-module cisc68k_tb

.PHONY: all rom select-rom sim run disasm clean

all: run

rom: $(HEX)

select-rom: $(HEX)
	@ln -sfn "$(LAB)/$(LAB).hex" $(ROM_LINK)
	@echo "ROM: $(ROM_LINK) -> $(LAB)/$(LAB).hex"

$(ELF): labs/common/start.S labs/common/link.ld $(LAB_SRC)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(LDFLAGS) labs/common/start.S $(LAB_SRC) -o $@

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

$(HEX): $(BIN) tools/helper.py
	$(PYTHON) tools/helper.py $< $@

SIM_BIN := obj_dir/Vcisc68k_tb

$(SIM_BIN): $(TB) $(FX68K)
	$(VERILATOR) $(VFLAGS) $(TB) $(FX68K)

sim: select-rom $(SIM_BIN)

run: sim
	@mkdir -p logs/$(LAB)
	@rm -f logs/$(LAB)/$(LAB).trace logs/$(LAB)/$(LAB).vcd
	@cp fx68k/microrom.mem microrom.mem
	@cp fx68k/nanorom.mem nanorom.mem
	@set -o pipefail; ./obj_dir/Vcisc68k_tb $(RUN_ARGS) | tee logs/$(LAB)/$(LAB).log
	@rm -f microrom.mem nanorom.mem
	@if [ "$(MODE)" = "trace" ] || [ "$(MODE)" = "both" ]; then echo "TRACE: logs/$(LAB)/$(LAB).trace"; fi
	@if [ "$(MODE)" = "vcd" ] || [ "$(MODE)" = "both" ]; then echo "VCD: logs/$(LAB)/$(LAB).vcd"; fi

disasm: $(ELF)
	$(OBJDUMP) -d -r $(ELF)

clean:
	rm -rf build cisc68k.vcd microrom.mem nanorom.mem $(ROM_LINK)
