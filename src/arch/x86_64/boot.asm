; boot.asm - x86-64 Bootloader with Long Mode and Paging

section .multiboot2_header
header_start:
    dd 0xe85250d6                ; magic number (multiboot 2)
    dd 0                         ; architecture 0 (protected mode i386)
    dd header_end - header_start ; header length
    dd -(0xe85250d6 + 0 + (header_end - header_start)) ; checksum

    ; insert optional multiboot tags here

    ; required end tag
    dd 0    ; tag type: end tag
    dd 8    ; size of this tage (8 bytes)
header_end:

section .text
bits 32
global start
extern kernel_main
 
start:
    cli                     ; Clear interrupts
    ; Check for long mode support
    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29       ; Check if LM (Long Mode) bit is set
    jz no_long_mode         ; Jump if long mode is not supported

    ; Enable protected mode
    mov eax, cr0
    or eax, 0x1             ; Set PE bit (Protection Enable)
    mov cr0, eax

    ; Load GDT
    lgdt [gdt_descriptor]

    ; Enable paging
    mov eax, cr4
    or eax, 0x20            ; Set PAE bit (Physical Address Extension)
    mov cr4, eax

    ; Load PML4 table address into CR3
    mov eax, pml4_table
    mov cr3, eax

    ; Enable long mode
    mov ecx, 0xC0000080     ; Load EFER MSR
    rdmsr
    or eax, 0x100           ; Set LME bit (Long Mode Enable)
    wrmsr
 
    ; Enable paging
    mov eax, cr0
    or eax, 0x80000000      ; Set PG bit (Paging)
    mov cr0, eax
 
    ; Far jump to 64-bit code segment
    jmp 0x08:long_mode_start

no_long_mode:
    ; Handle the case where long mode is not supported
    mov al, "2"
    hlt


section .data
align 4096
pml4_table:
    dq 0x0000000000000003   ; PML4 entry pointing to itself
 

section .bss

section .text
bits 64
long_mode_start:
    ; Reload all data segment registers with null
    mov ax, 0x10
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Set up stack
    mov rsp, stack_top
 
    ; Call kernel main function
    call kernel_main

    ; Halt the CPU
    hlt

section .data
gdt:
    dq 0x0000000000000000   ; Null descriptor
    dq 0x00AF9A000000FFFF   ; Code segment descriptor
    dq 0x00AF92000000FFFF   ; Data segment descriptor

gdt_descriptor:
    dw gdt_end - gdt - 1    ; Limit
    dd gdt                  ; Base
gdt_end:


section .bss
align 16
stack_bottom:
    resb 4096               ; 4KB stack
stack_top:
