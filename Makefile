# $@ = target file
# $< = first dependency
# $^ = all dependencies

BIOS_LDFLAGS =  --oformat binary -N

BIOS_CFLAGS = -ffreestanding -fno-pie # -mcmodel=large -mno-red-zone -mno-mmx -mno-sse -mno-sse2

all: run

out/%.o: src/%.c
	gcc $(BIOS_CFLAGS) $< -c -o $@ -O0

out/%.o: boot/%.asm
	as -o $@ $<

bin/kernel: out/kernel.o out/main.o out/bios.o
	ld -o $@ -Tlink.ld     $(BIOS_LDFLAGS) $^

bin/bootsect: out/boot.o
	ld -o $@ -Ttext 0x7c00 $(BIOS_LDFLAGS) $<

os-img.bin: bin/bootsect bin/kernel
	cat $^ > $@
	truncate -s 10240 $@

run: os-img.bin
	qemu-system-x86_64 -drive format=raw,file=$<

clean:
	rm out/*.o bin/*

CFLAGS  = -ffreestanding -fno-stack-protector -fno-stack-check -fshort-wchar -mno-red-zone -mabi=ms -Wall -Wno-pointer-to-int-cast
LDFLAGS = -nostdlib \
    		-Wl,-subsystem,10 \
    		-Wl,-entry,efi_main \
			-Wl,--pic-executable \
    		-Wl,--file-alignment,512 \
    		-Wl,--section-alignment,4096

ARCH = x86_64-w64-mingw32
CC = $(ARCH)-gcc-win32

define SRC_to_OBJ
out/$(basename $(1)).o.win32
endef

SRC := src/efi.c src/main.c
OBJ := $(foreach src, $(SRC), $(call SRC_to_OBJ,$(src)))


out/%.o.win32: %.c
	$(CC) -I/usr/include/efi/ -Iinclude $(CFLAGS) -Wall -c $< -o $@

main.efi: $(OBJ)
	$(CC) $(LDFLAGS) -o $@ $^


uefi.img: main.efi
	# 1. Create a 64MB empty file
	dd if=/dev/zero of=$@ bs=1M count=64
	
	# 2. Create GPT partition table and a single EFI partition
	parted $@ -s mklabel gpt
	parted $@ -s mkpart EFI fat32 1MiB 100%
	parted $@ -s set 1 esp on
	
	mformat -i $@@@1M -F
	mmd     -i $@@@1M ::/EFI
	mmd     -i $@@@1M ::/EFI/BOOT
	mcopy   -i $@@@1M $< ::/EFI/BOOT/BOOTX64.EFI
	
run-efi: uefi.img
	qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -drive file=$<,format=raw -net none
