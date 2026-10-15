# NOVA OS — Operating System

NOVA OS is a custom x86_64 operating-system project. This repository establishes the early freestanding kernel entry path and boot diagnostics.

## Current milestone
- x86_64 ELF kernel and Limine boot protocol
- Framebuffer banner and COM1 serial diagnostics
- Safe halt loop
- Makefile, linker script, and CI compile/link checks

## Build prerequisites
Install `make`, an `x86_64-elf-gcc` cross compiler and matching binutils, QEMU, and `xorriso`. Place Limine BIOS/UEFI files and its utility under `vendor/limine/` as documented in `docs/ROADMAP.md`.

Run `make kernel` to compile and link the kernel. Run `make` to attempt ISO creation and `make run` to launch QEMU. The ISO and QEMU boot are not yet verified; do not treat this as a bootable release.

## Roadmap
See `docs/ROADMAP.md` and `docs/MILESTONE-01.md`. The scheduler, memory manager, filesystem, network stack, user mode, and desktop are future milestones. Test in an emulator before considering physical hardware.