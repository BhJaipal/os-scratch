# $@ = target file
# $< = first dependency
# $^ = all dependencies

LDFLAGS =  --oformat binary -N

CFLAGS = -ffreestanding -fno-pie # -mcmodel=large -mno-red-zone -mno-mmx -mno-sse -mno-sse2

all: run

out/%.o: %.asm
	as -o $@ $<

bin/kernel: out/kernel.o
	ld -o $@ -T../link.ld  $(LDFLAGS) $^

bin/bootsect: out/kernel-bootloader.o
	ld -o $@ -Ttext 0x7c00 $(LDFLAGS) $<

bin/bootsect-no-kern: out/no-kernel-bootloader.o
	ld -o $@ -Ttext 0x7c00 --oformat binary -N $<

os-img.bin: bin/bootsect bin/kernel
	cat $^ > $@
	truncate -s 10240 $@

run: os-img.bin
	qemu-system-x86_64 -drive format=raw,file=$<

run-no-kern: bin/bootsect-no-kern
	qemu-system-x86_64 -drive format=raw,file=$<

clean:
	rm out/*.o bin/*
