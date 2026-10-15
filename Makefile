CROSS ?=
CC := $(CROSS)gcc
LD := $(CROSS)ld
CFLAGS := -std=gnu11 -O2 -Wall -Wextra -Werror -ffreestanding -fno-stack-protector -fno-pic -fno-pie -m64 -mno-red-zone -mcmodel=kernel -mgeneral-regs-only -Iinclude
LDFLAGS := -nostdlib -z max-page-size=0x1000 -T linker.ld
BUILD := build
KERNEL := $(BUILD)/kernel.elf
ISO := $(BUILD)/novaos.iso
LIMINE_VERSION := 12.9.3
LIMINE_ROOT := vendor/limine
LIMINE_ARCHIVE := $(BUILD)/limine-binary.tar.gz

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

limine: | $(BUILD)
	@if [ ! -f $(LIMINE_ROOT)/limine-bios.sys ] && [ ! -f $(LIMINE_ROOT)/limine/limine-bios.sys ]; then \
		rm -rf $(LIMINE_ROOT) $(BUILD)/limine-unpack; \
		mkdir -p $(LIMINE_ROOT) $(BUILD)/limine-unpack; \
		curl -fL --retry 3 --retry-delay 1 https://github.com/Limine-Bootloader/Limine/releases/download/v$(LIMINE_VERSION)/limine-binary.tar.gz -o $(LIMINE_ARCHIVE) || exit $$?; \
		tar -xzf $(LIMINE_ARCHIVE) -C $(BUILD)/limine-unpack || exit $$?; \
		cp -a $(BUILD)/limine-unpack/. $(LIMINE_ROOT)/; \
	fi
	@LIMINE_BIN="$$(dirname "$$(find $(LIMINE_ROOT) -name limine-bios.sys -type f -print -quit)")"; \
	test -n "$$LIMINE_BIN" || (echo "Limine BIOS binary missing after extracting official v$(LIMINE_VERSION) release."; exit 1); \
	test -f "$$LIMINE_BIN/limine-uefi-cd.bin" || (echo "Limine UEFI CD image missing."; exit 1); \
	test -f "$$LIMINE_BIN/BOOTX64.EFI" || (echo "Limine BOOTX64.EFI missing."; exit 1); \
	if [ ! -x "$$LIMINE_BIN/limine" ]; then \
		if [ -f "$$LIMINE_BIN/Makefile" ]; then $(MAKE) -C "$$LIMINE_BIN" || exit $$?; fi; \
	fi; \
	test -x "$$LIMINE_BIN/limine" || (echo "Limine installer tool missing or not executable."; exit 1)

iso: kernel limine
	@command -v xorriso >/dev/null || (echo "Missing xorriso."; exit 1)
	rm -rf $(BUILD)/iso
	mkdir -p $(BUILD)/iso/boot/limine $(BUILD)/iso/EFI/BOOT
	@LIMINE_BIN="$$(dirname "$$(find $(LIMINE_ROOT) -name limine-bios.sys -type f -print -quit)")"; \
	cp $(KERNEL) $(BUILD)/iso/boot/kernel.elf && \
	cp limine.conf $(BUILD)/iso/limine.conf && \
	cp "$$LIMINE_BIN/limine-bios.sys" "$$LIMINE_BIN/limine-bios-cd.bin" "$$LIMINE_BIN/limine-uefi-cd.bin" $(BUILD)/iso/boot/limine/ && \
	cp "$$LIMINE_BIN/BOOTX64.EFI" $(BUILD)/iso/EFI/BOOT/ && \
	xorriso -as mkisofs -R -r -J -b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot boot/limine/limine-uefi-cd.bin -efi-boot-part --efi-boot-image --protective-msdos-label $(BUILD)/iso -o $(ISO) && \
	"$$LIMINE_BIN/limine" bios-install $(ISO)

run: iso
	qemu-system-x86_64 -M q35 -m 256M -cdrom $(ISO) -boot d -no-reboot -no-shutdown -serial stdio

debug: iso
	qemu-system-x86_64 -M q35 -m 256M -cdrom $(ISO) -boot d -S -s -no-reboot -no-shutdown -serial stdio

clean:
	rm -rf $(BUILD)
