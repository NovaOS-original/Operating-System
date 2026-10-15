# Milestone 01 — Kernel diagnostics and boot smoke test

## Implemented
- Freestanding x86-64 entry point and ELF linker script.
- Limine framebuffer request and simple NOVA OS banner.
- COM1 serial diagnostics and safe halt loop.
- Makefile recipes for kernel, pinned Limine download, hybrid ISO creation, QEMU run/debug.
- GitHub Actions workflow to build the ISO and attempt a QEMU serial smoke test.

## Acceptance criteria
- CI compiles and links the kernel.
- ISO creation succeeds using the pinned Limine binary branch.
- QEMU serial output contains `NOVA OS: initialization complete; halted safely`.

## Status
The workflow has been committed, but its result must be inspected in GitHub Actions before calling the milestone boot-verified. No physical hardware test has been performed.
