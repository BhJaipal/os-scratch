.code64
.text

.global _start
_start:
	mov $0xb8000, %rdx # VIDEO_MEMORY

	mov $0x40, %rsi
clear_start:
	cmp $0, %rsi
	je clear_end
	mov $0x0020, %ax
	mov %ax, (%rdx)
	add $2, %rdx
	sub $1, %rsi
	jmp clear_start
clear_end:
	mov $0xb8000, %rdx # VIDEO_MEMORY back to start

	mov $0x6f6c6c6548, %rdi    # "Hello"
	call print_vram

	mov $0x206d6f726620, %rdi  # " from "
	call print_vram

	mov $0x2d3436, %rdi        #  "64-"
	call print_vram

	mov $0x20746962, %rdi      # "bit "
	call print_vram

	mov $0x72656b, %rdi        # "ker"
	call print_vram

	mov $0x6c656e, %rdi        # "nel"
	call print_vram

out:
	hlt
	jmp out

print_vram:
	# string in rdi
print_vram_loop:
	mov %rdi, %rax
	cmp $0, %al
	je print_vram_end

	mov $0x2f, %ah  # add 2f color, green bg, whitw fg
	and $0x0000ffff, %rax
	mov %ax, (%rdx)

	shr $8, %rdi
	add $2, %rdx
	jmp print_vram_loop
print_vram_end:
	ret
