# Build status

The repository now pins the Limine binary branch to `v12.9.3-binary` and has a Makefile target that downloads the bootloader when needed. The CI workflow attempts to build a hybrid BIOS/UEFI ISO and smoke-test BIOS boot in QEMU by looking for the kernel's final serial diagnostic.

A successful commit does not itself prove that CI or boot succeeds. Check the GitHub Actions run for this commit and inspect the uploaded serial log and ISO artifact. If Limine changes its binary package layout or the protocol integration needs adjustment, update the build based on the actual failing log.
