# This file's sole purpose is to go to 64-bit mode, copy anything from here
.code16
.org 0

.text
.global _start

_start:
	# Segment setup
	xor %ax, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %ss

	# Stack setup
	mov $0x7c00, %bp
	mov %bp, %sp

	cli
	lgdt gdtp
	lidt idt

	mov %cr0, %eax    # This works in 16-bit mode!
	or $0x1, %eax     # Modify the 32-bit register
	mov %eax, %cr0    # Write it back

	movw $(gdt_data_segment - gdt_start), %ax
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %es
	movw %ax, %fs
	movw %ax, %gs
	movw %ax, %ss

	ljmp $(gdt_code_segment - gdt_start), $entry32

print:
	lodsb
print_loop:
	inb (%dx), %al
	cmp $0, %al
	je print_end
	mov $0x0e, %ah
	mov $0x07, %bl
	int $0x10
	add $1, %dx
	jmp print_loop
print_end:
	ret

println:
	mov $0x0e, %ah
	mov $0xa, %al
	int $0x10
	mov $0x20, %al
	int $0x10
	ret

.code32
entry32:
    # Proper 32-bit segment initialization
    movw $(gdt_data_segment - gdt_start), %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %ss

    # 1. Setup Paging Structures
    mov $0x1000, %edi
    mov %edi, %cr3
    xor %eax, %eax
    mov $4096, %ecx
    rep stosl

    mov %cr3, %edi
    movl $0x2003, (%edi)         # PML4 -> PDPT
    movl $0x3003, 0x1000(%edi)    # PDPT -> PD
    movl $0x00000083, 0x2000(%edi)# PD -> 2MB Huge Page (Identity map 0-2MB)

    # 2. Enable PAE (FIXED)
    mov %cr4, %eax
    or $(1 << 5), %eax
    mov %eax, %cr4               # Write back to register

    # 3. Enable Long Mode via EFER
    mov $0xC0000080, %ecx
    rdmsr
    or $(1 << 8), %eax           # LME Bit
    wrmsr

    # 4. Enable Paging
    mov %cr0, %eax
    or $(1 << 31), %eax          # PG Bit
    mov %eax, %cr0

    # 5. Jump to 64-bit
    lgdt gdt64_ptr
    ljmp $0x08, $entry64

.code64
entry64:
    # Use a bright color like Green (0x2) or Red (0x4)
    movq $0x2f342f36, %rax       # '6' and '4' on Green/Grey
    movq %rax, 0xb8000
    hlt

print_cli:
	mov $0xb8000, %ecx # VIDEO_MEMORY
print_loop_cli:
	# edx = str
	mov $0, %eax
	movb (%edx), %al   # str[i]
	mov $0x0f, %ah    # white fg, black bg
	cmp $0, %al
	je print_end_cli
	mov %ax, (%ecx)
	add $2, %ebx
	add $2, %ecx
	add $1, %edx
	jmp print_loop_cli
print_end_cli:
	ret

println_cli:
	mov $0xb8000, %ecx # VIDEO_MEMORY

	mov $0x0f0a, %eax  # 0f\n
	add %ebx, %ecx
	mov %eax, (%ecx)
	mov $1, %ebx
	ret


/* GDT */
.align 16
gdtp:
	.word gdt_end - gdt_start - 1
	/* .long (0x07C0 << 4) + gdt */
	.long gdt_start

gdt_start:
	.quad 0x0000000000000000    #	Null Descriptor
gdt_code_segment:
	#    Segment limit  Base address
	.word 0xffff,       0x0000
	.byte 0x00        # Base
	# 1st  flags: (present) 1    (privilege)   0                    0         (descriptor type)1 -> 1001b
	# Type flags: (code)    1    (conforming)  0        (readable)  1         (accessed)       0 -> 1010b
	# 10011010
	.byte 0x9a
	# 2nd  flags: (granularity) 1    (32-bit default) 1    (64-bit segment) 0    (available)   0 -> 1100b
	.byte 0xcf
	.byte 0x00        # Base

gdt_data_segment:
	#    Segment limit  Base address
	.word 0xffff,       0x0000
	.byte 0x00        # Base
	# 1st  flags: (present) 1    (privilege)   0                    0         (descriptor type)1 -> 1001b
	# Type flags: (code)    0    (conforming)  0        (readable)  1         (accessed)       0 -> 1010b
	# 10010010
	.byte 0x92
	# 2nd  flags: (granularity) 1    (32-bit default) 1    (64-bit segment) 0    (available)   0 -> 1100b
	.byte 0xcf
	.byte 0x00        # Base

gdt_end:

# Where docs for 64-bit GDT? IDK, just copy it
# 64-bit GDT
.align 16
gdt64:
    .quad 0                      # Null
    .quad 0x00209a0000000000     # Code: L-bit set, D-bit clear
    .quad 0x0000920000000000     # Data
gdt64_ptr:
    .word . - gdt64 - 1
    .quad gdt64                  # 64-bit base

/* IDT */
idt:
	.word 0
	.long 0

running_kernel: .asciz "Trying to run Kernel"

.fill 510-(.-_start), 1, 0
.word 0xAA55
