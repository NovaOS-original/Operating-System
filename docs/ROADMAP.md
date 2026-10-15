# NOVA OS roadmap

## M1 — Bootable foundation (current)
- [x] Define initial x86_64/Limine architecture
- [x] Add freestanding kernel entry and framebuffer request
- [x] Add build/run/debug recipes and CI compile job
- [ ] Validate build with a pinned Limine release and cross-toolchain
- [ ] Boot ISO in QEMU and capture expected output

## M2 — CPU foundations
- [ ] GDT and IDT
- [ ] Exception handlers and readable panic diagnostics
- [ ] Serial driver and timer interrupt

## M3 — Memory management
- [ ] Parse bootloader memory map
- [ ] Physical page allocator with unit tests
- [ ] Virtual-memory map/unmap and permission checks
- [ ] Kernel heap with overflow/alignment tests

## M4 — Devices and storage
- [ ] Keyboard input
- [ ] Block-device abstraction
- [ ] VFS and initial filesystem

## M5 — Execution model
- [ ] Scheduler and threads
- [ ] Process isolation and syscall ABI
- [ ] Init process and interactive shell

## M6 — Networking and security
- [ ] Network device interface and packet buffers
- [ ] Basic network stack
- [ ] Permissions, user/kernel boundaries, negative tests

## M7 — Graphics and desktop
- [ ] Framebuffer drawing API
- [ ] Input abstraction
- [ ] Compositor and desktop shell

A checkbox is completed only when implementation and verification evidence exist. The architecture repository holds subsystem contracts and design decisions.
