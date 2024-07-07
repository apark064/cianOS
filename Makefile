arch ?= x86_64
kernel := build/kernel-$(arch).bin
iso := build/os-$(arch).iso
CC = gcc
LD = ld
CFLAGS = -m64 -ffreestanding -O2 -Wall -Wextra -nostdlib

linker_script := src/arch/$(arch)/linker.ld
grub_cfg := src/arch/$(arch)/grub.cfg

assembly_source_files := $(wildcard src/arch/$(arch)/*.asm)
assembly_object_files := $(patsubst src/arch/$(arch)/%.asm, \
	build/arch/$(arch)/%.o, $(assembly_source_files))

c_source_files := $(wildcard src/arch/$(arch)/*.c)
c_object_files := $(patsubst src/arch/$(arch)/%.c, \
        build/arch/$(arch)/%.o, $(c_source_files))

all_object_files := $(assembly_object_files) $(c_object_files)

.PHONY: all clean run iso lazy

lazy: clean all run

all: $(kernel)

clean:
	@rm -rf build

run: $(iso)
	qemu-system-x86_64 -cdrom $(iso)

iso: $(iso)

$(iso): $(kernel) $(grub_cfg)

	@mkdir -p build/isofiles/boot/grub
	@cp $(kernel) build/isofiles/boot/kernel.bin
	@cp $(grub_cfg) build/isofiles/boot/grub
	@grub2-mkrescue --verbose -o $(iso) build/isofiles 2> /dev/null
	@rm -rf build/isofiles

$(kernel): $(all_object_files) $(linker_script)
	@ld -n -T $(linker_script) -o $(kernel) $(all_object_files)

# Compile assembly source files
build/arch/$(arch)/%.o: src/arch/$(arch)/%.asm
	@mkdir -p $(shell dirname $@)
	@nasm -felf64 $< -o $@

# Compile C source files
build/arch/$(arch)/%.o: src/arch/$(arch)/%.c
	@mkdir -p $(shell dirname $@)
	@$(CC) $(CFLAGS) -c $< -o $@