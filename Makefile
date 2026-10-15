CROSS ?= x86_64-elf-
CC := $(CROSS)gcc
LD := $(CROSS)ld
CFLAGS := -std=gnu11 -O2 -Wall -Wextra -Werror -ffreestanding -fno-stack-protector -fno-pic -fno-pie -m64 -mno-red-zone -mcmodel=kernel -mgeneral-regs-only -Iinclude
LDFLAGS := -nostdlib -z max-page-size=0x1000 -T linker.ld
BUILD := build
KERNEL := $(BUILD)/kernel.elf
ISO := $(BUILD)/novaos.iso

.PHONY: all kernel iso run debug clean check-toolchain
all: iso

check-toolchain:
	@command -v $(CC) >/dev/null || (echo "Missing $(CC). Install an x86_64-elf GCC cross-compiler."; exit 1)
	@command -v $(LD) >/dev/null || (echo "Missing $(LD). Install matching binutils."; exit 1)

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/entry.o: kernel/entry.S | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/kernel.o: kernel/kernel.c include/limine.h | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

kernel: check-toolchain $(KERNEL)

$(KERNEL): $(BUILD)/entry.o $(BUILD)/kernel.o linker.ld
	$(LD) $(LDFLAGS) -o $@ $(BUILD)/entry.o $(BUILD)/kernel.o

iso: $(KERNEL)
	@test -d vendor/limine || (echo "Missing vendor/limine. See README.md."; exit 1)
	@command -v xorriso >/dev/null || (echo "Missing xorriso."; exit 1)
	mkdir -p $(BUILD)/iso/boot/limine
	cp $(KERNEL) $(BUILD)/iso/boot/kernel.elf
	cp limine.conf $(BUILD)/iso/boot/limine/limine.conf
	cp vendor/limine/limine-bios.sys vendor/limine/limine-bios-cd.bin vendor/limine/limine-uefi-cd.bin $(BUILD)/iso/boot/limine/
	cp vendor/limine/BOOTX64.EFI $(BUILD)/iso/boot/limine/BOOTX64.EFI
	cp vendor/limine/limine-bios.sys $(BUILD)/iso/limine-bios.sys
	xorriso -as mkisofs -b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot boot/limine/limine-uefi-cd.bin -efi-boot-part --efi-boot-image --protective-msdos-label $(BUILD)/iso -o $(ISO)
	@if [ -x vendor/limine/limine ]; then vendor/limine/limine bios-install $(ISO); fi

run: iso
	qemu-system-x86_64 -M q35 -m 256M -cdrom $(ISO) -boot d -no-reboot -no-shutdown -serial stdio

debug: iso
	qemu-system-x86_64 -M q35 -m 256M -cdrom $(ISO) -boot d -S -s -no-reboot -no-shutdown -serial stdio

clean:
	rm -rf $(BUILD)
