.code32
.text
.global _start

_start:
	mov $stack_top, %esp

	call kmain        # Call the C function

.section .bss
.align 16
stack_bottom:
    .skip 0x4000 # 16KiB stack
stack_top:
