; boot.asm - Bootloader for x86_64 systems using Multiboot2

section .multiboot2_header
align 8
multiboot2_header_start:
    dd 0xe85250d6           ; Multiboot2 magic number
    dd 0                    ; Architecture (0 for i386)
    dd multiboot2_header_end - multiboot2_header_start ; Header length
    dd -(0xe85250d6 + 0 + (multiboot2_header_end - multiboot2_header_start)) ; Checksum

    ; Optional tags

    dd 0                    ; End tag type
    dd 8                    ; End tag size

multiboot2_header_end:

global start
extern kernel_main

section .text
[BITS 32]
start:
    mov esp, stack_top      ; Set stack pointer
    cli                     ; Disable interrupts

    ; print `OK` to screen
    ; mov dword [0xb8000], 0x2f4b2f4f
    ; hlt

    ; Check for 64-bit long mode support
    mov eax, 0x80000001     ; argument for extended processor info
    cpuid
    test edx, 1 << 29       ; Check if bit 29 (LM) is set
    jz no_long_mode         ; If it's not set, there is no long mode

    ; Initialize GDT
    lgdt [gdt64.pointer]

    ; Enable protected mode
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; Set up paging
    call setup_paging
    call enable_paging

    ; Far jump to flush prefetch queue and enter long mode
    jmp gdt64.code:long_mode
    ; jmp 0x08:long_mode

no_long_mode:
    ; Print error message
    mov esi, error_msg
    call print_string
    hlt

setup_paging:
    ; Set up PML4 table
    mov eax, pdpt_table
    or eax, 0b11            ; present + writable
    mov [pml4_table], eax

    ; Set up PDPT table
    mov eax, pd_table
    or eax, 0b11            ; present + writable
    mov [pdpt_table], eax

    ; Set up P2 table entries
    call map_p2_table
    ret

map_p2_table:
    ; map each P2 entry to a huge 2MiB page
    mov ecx, 0
.map_p2_table:
    ; map ecx-th P2 entry to a huge page that starts at address 2MiB*ecx
    mov eax, 0x200000       ; 2MiB
    mul ecx                 ; start address of ecx-th page
    or eax, 0b10000011      ; present + writable + huge
    mov [pd_table + ecx * 8], eax ; map ecx-th entry
    inc ecx                 ; increase counter
    cmp ecx, 512            ; if counter == 512, the whole P2 table is mapped
    jne .map_p2_table       ; else map the next entry
    ret

enable_paging:
    ; Load PML4 table address into CR3 (cpu uses this to access the P4 table)
    mov eax, pml4_table
    mov cr3, eax

    ; Enable PAE
    mov eax, cr4
    or eax, 1 << 5 ; Set PAE bit (Physical Address Extension)
    mov cr4, eax

    ; Enable long mode
    mov ecx, 0xC0000080 ; Load EFER MSR (model specific register)
    rdmsr
    or eax, 1 << 8 ; Set LME bit (Long Mode Enable)
    wrmsr

    ; Enable paging
    mov eax, cr0
    or eax, 1 << 31 ; Set PG bit (Paging)
    mov cr0, eax
    ret

section .data
error_msg db '64-bit long mode not supported!', 0

print_string:
    pusha
    mov esi, error_msg
.next_char:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .next_char
.done:
    popa
    ret

section .text
[BITS 64]
long_mode:
    ; Set up segment registers for long mode
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; print `OKAY` to screen
    ; mov rax, 0x2f592f412f4b2f4f
    ; mov qword [0xb8000], rax

    ; Call the C-based kernel
    call kernel_main
    hlt

section .rodata
gdt64:
    dq 0 ; zero entry
.code: equ $ - gdt64 ; new
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53) ; code segment
.pointer:
    dw $ - gdt64 - 1
    dq gdt64

section .bss
align 4096
pml4_table:
    resb 4096
pdpt_table:
    resb 4096
pd_table:
    resb 4096

stack_bottom:
    resb 64
stack_top: