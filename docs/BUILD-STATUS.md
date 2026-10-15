# Build status

The source tree is a starter implementation and has not been booted in QEMU. Before treating M1 as complete, install a pinned Limine release and x86_64-elf cross-toolchain, run `make kernel`, produce the ISO, boot it in QEMU, and record the result. The ISO recipe may need adjustment to match the exact Limine release package.
