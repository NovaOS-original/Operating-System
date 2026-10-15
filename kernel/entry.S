/* Limine enters the x86_64 kernel in long mode. Keep entry minimal. */
.section .text
.global _start
.type _start, @function
.extern kernel_main
_start:
    cli
    cld
    xorq %rbp, %rbp
    call kernel_main
1:
    hlt
    jmp 1b
.size _start, . - _start
