# $@ = target file
# $< = first dependency
# $^ = all dependencies

LDFLAGS =  --oformat binary -N

CFLAGS = -ffreestanding -fno-pie # -mcmodel=large -mno-red-zone -mno-mmx -mno-sse -mno-sse2

all: run

out/%.o: src/%.c
	gcc $(CFLAGS) $< -c -o $@ -O0

out/%.o: boot/%.asm
	as -o $@ $<

bin/kernel: out/kernel.o out/main.o
	ld -o $@ -Tlink.ld     $(LDFLAGS) $^

bin/bootsect: out/boot.o
	ld -o $@ -Ttext 0x7c00 $(LDFLAGS) $<

bin/bootsect64: out/boot64.o
	ld -o $@ -Ttext 0x7c00 --oformat binary -N $<

os-img.bin: bin/bootsect bin/kernel
	cat $^ > $@
	truncate -s 10240 $@

run: os-img.bin
	qemu-system-x86_64 -drive format=raw,file=$<

clean:
	rm out/*.o bin/*
