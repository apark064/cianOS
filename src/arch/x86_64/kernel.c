#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

void print_string(const char* str) {
    unsigned short* VideoMemory = (unsigned short*)0xB8000;
    while (*str != 0) {
        *VideoMemory++ = (*str++ | 0x0700);
    }
}

void kernel_main() {
    print_string("Hello, World!");
    while (1);  // Infinite loop to keep the kernel running
}
