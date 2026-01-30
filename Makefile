# $@ = target file
# $< = first dependency
# $^ = all dependencies

all: run

out/%.o: src/%.c
	gcc -ffreestanding -m32 -fno-pie $< -c -o $@

out/%.o: boot/%.asm
	as --32 -o $@ $<

bin/kernel: out/kernel.o out/main.o
	ld -N -o $@ -Tlink.ld --oformat binary -m elf_i386 $^

bin/bootsect: out/boot.o
	ld -N -o $@ -Ttext 0x7C00 --oformat binary -m elf_i386 $<

os-img.bin: bin/bootsect bin/kernel
	cat $^ > $@
	truncate -s 10240 $@

run: os-img.bin
	qemu-system-x86_64 -drive format=raw,file=$<

clean:
	rm out/*.o bin/*
