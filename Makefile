CROSS ?=
CC := $(CROSS)gcc
LD := $(CROSS)ld
CFLAGS := -std=gnu11 -O2 -Wall -Wextra -Werror -ffreestanding -fno-stack-protector -fno-pic -fno-pie -m64 -mno-red-zone -mcmodel=kernel -mgeneral-regs-only -Iinclude
LDFLAGS := -nostdlib -z max-page-size=0x1000 -T linker.ld
BUILD := build
KERNEL := $(BUILD)/kernel.elf
ISO := $(BUILD)/novaos.iso
LIMINE_VERSION := v12.9.3
LIMINE_ROOT := vendor/limine
LIMINE_BIN := $(LIMINE_ROOT)/bin

.PHONY: all kernel iso run debug clean limine check-toolchain
all: iso

check-toolchain:
	@command -v $(CC) >/dev/null || (echo "Missing compiler $(CC)"; exit 1)
	@command -v $(LD) >/dev/null || (echo "Missing linker $(LD)"; exit 1)

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/entry.o: kernel/entry.S | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/kernel.o: kernel/kernel.c include/limine.h | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

kernel: check-toolchain $(KERNEL)

$(KERNEL): $(BUILD)/entry.o $(BUILD)/kernel.o linker.ld
	$(LD) $(LDFLAGS) -o $@ $(BUILD)/entry.o $(BUILD)/kernel.o

limine:
	@if [ ! -f $(LIMINE_BIN)/limine-bios.sys ]; then \
		mkdir -p $(LIMINE_ROOT); \
		git clone --depth=1 --branch=$(LIMINE_VERSION)-binary https://github.com/limine-bootloader/limine.git $(LIMINE_ROOT); \
	fi
	@test -f $(LIMINE_BIN)/limine-bios.sys || (echo "Limine binary files missing; check the pinned branch and package layout."; exit 1)

iso: kernel limine
	@command -v xorriso >/dev/null || (echo "Missing xorriso."; exit 1)
	rm -rf $(BUILD)/iso
	mkdir -p $(BUILD)/iso/boot/limine $(BUILD)/iso/EFI/BOOT
	cp $(KERNEL) $(BUILD)/iso/boot/kernel.elf
	cp limine.conf $(BUILD)/iso/limine.conf
	cp $(LIMINE_BIN)/limine-bios.sys $(BUILD)/iso/boot/limine/
	cp $(LIMINE_BIN)/limine-bios-cd.bin $(BUILD)/iso/boot/limine/
	cp $(LIMINE_BIN)/limine-uefi-cd.bin $(BUILD)/iso/boot/limine/
	cp $(LIMINE_BIN)/BOOTX64.EFI $(BUILD)/iso/EFI/BOOT/
	xorriso -as mkisofs -R -r -J -b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot boot/limine/limine-uefi-cd.bin -efi-boot-part --efi-boot-image --protective-msdos-label $(BUILD)/iso -o $(ISO)
	$(LIMINE_BIN)/limine bios-install $(ISO)

run: iso
	qemu-system-x86_64 -M q35 -m 256M -cdrom $(ISO) -boot d -no-reboot -no-shutdown -serial stdio

debug: iso
	qemu-system-x86_64 -M q35 -m 256M -cdrom $(ISO) -boot d -S -s -no-reboot -no-shutdown -serial stdio

clean:
	rm -rf $(BUILD)
