#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

void print_string(const char* str) {
    unsigned short* VideoMemory = (unsigned short*)0xB8000;
    while (*str != 0) {
        *VideoMemory++ = (*str++ | 0x0F00);
    }
}

void kernel_main() {
    print_string("Hello, World!");

    // Loop forever
    while (1) {
        asm volatile ("hlt");
    }
}