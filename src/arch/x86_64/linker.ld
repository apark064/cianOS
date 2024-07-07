ENTRY(start)

SECTIONS {
    . = 1M;

    .multiboot2_header : {
        KEEP(*(.multiboot2_header))
    } 

    .text : {
        *(.text)
    }

    .data : {
        *(.data)
    }

    .rodata : {
        *(.rodata)
    }

    .bss : {
	*(COMMON)
        *(.bss)
    }
}