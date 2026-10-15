# Milestone 01 — Kernel diagnostics

## Added
- Added COM1 serial initialization and bounded serial output.
- Added boot progress messages for kernel entry, framebuffer status, and safe halt.
- Added framebuffer banner diagnostics.
- CI compiles the freestanding C kernel and assembly entry point, links the ELF, and verifies its architecture.

## Verification completed
The kernel C source compiled with GCC using `-Wall -Wextra -Werror`. The assembly entry compiled, and GNU `ld` produced a statically linked ELF64 x86-64 kernel.

## Not yet verified
- Limine ISO creation
- BIOS or UEFI boot
- QEMU runtime framebuffer output and serial output

The next milestone is to pin a compatible Limine release, create the ISO reproducibly, and test booting in QEMU before adding memory management.
