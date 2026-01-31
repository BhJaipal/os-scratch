.code16
.org 0

.text
.global _start

_start:
	mov $0, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %ss

    mov $0x9000, %bp
    mov %bp, %sp

	# Load Kernel from Disk
    mov $0x1000, %ax     # Segment 0x1000
    mov %ax, %es         # ES now points to 0x1000
    xor %bx, %bx         # Offset 0
    # Destination is ES:BX -> (0x1000 * 16) + 0 = 0x10000
	mov $2, %ah              # BIOS read sector function
    mov $8, %al              # Number of sectors to read (adjust as needed)
    mov $0, %ch              # Cylinder 0
    mov $2, %cl              # Sector 2 (Sector 1 is the bootloader)
    mov $0, %dh              # Head 0
	int $0x13

    jc disk_error
	jmp disable_int

disk_error:
	mov $disk_err_msg, %dx
	call print
	call println
disable_int:

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
	movl $0x3000, %esp

    ljmp $0x8, $entry32

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
	mov $1, %ebx
	mov $running_kernel, %edx
	call print_cli
	call println_cli

    mov $KERNEL_OFFSET, %eax
	call *%eax
1:
	jmp 1b

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

.align 16
gdt_start:
	.quad 0x0000000000000000    #	Null Descriptor
gdt_code_segment:
    .word 0xffff, 0x0000
    .byte 0x00, 0x9a, 0xcf, 0x00
gdt_data_segment:
    .word 0xffff, 0x0000
    .byte 0x00, 0x92, 0xcf, 0x00
gdt_end:

/* IDT */
idt:
    .word 0
    .long 0

running_kernel: .asciz "Trying to run Kernel"
disk_err_msg:   .asciz "Can't load kernel from disk"

KERNEL_OFFSET: .long 0x20000
BOOT_DRIVE:    .byte 0

/* MBR BOOT SIGNATURE */
.fill 510-(.-_start), 1, 0
.word 0xAA55
