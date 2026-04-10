# $@ = target file
# $< = first dependency
# $^ = all dependencies

BIOS_LDFLAGS =  --oformat binary -N

BIOS_CFLAGS = -ffreestanding -fno-pie # -mcmodel=large -mno-red-zone -mno-mmx -mno-sse -mno-sse2

RED          := \033[31m
BLUE         := \033[94m
CYAN         := \033[36m
GREEN        := \033[32m
YELLOW       := \033[33m
BOLD         := \033[1m
NC           := \033[0m

PRINT_STEP_DEL =   @printf "  $(RED)%-7s$(NC)  $(BOLD)%s$(NC)\n" "$(1)" "$(2)"
PRINT_STEP =       @printf "  $(BLUE)%-7s$(NC)  $(BOLD)%s$(NC)\n" "$(1)" "$(2)"
PRINT_STEP_MSDOS = @printf "  $(YELLOW)%-7s$(NC)$(BOLD)%s$(NC)\n" "$(1)" "$(2)"

all: run

out/%.o: src/%.c
	$(call PRINT_STEP, "CC", $(<:.c=.o))
	@gcc $(BIOS_CFLAGS) $< -c -o $@ -O0

out/%.o: bootloader/%.asm
	$(call PRINT_STEP, "AS", $(<:.asm=.o))
	@as -o $@ $<

bin/kernel: out/kernel.o out/main.o out/bios.o
	$(call PRINT_STEP, "LD", $@)
	@ld -o $@ -Tlink.ld     $(BIOS_LDFLAGS) $^

bin/bootsect: out/boot.o
	$(call PRINT_STEP, "LD", $@)
	@ld -o $@ -Ttext 0x7c00 $(BIOS_LDFLAGS) $<

os-img.bin: bin/bootsect bin/kernel
	$(call PRINT_STEP_MSDOS, "TRUNCATE", $@)
	@cat $^ > $@
	@truncate -s 10240 $@

run: os-img.bin
	@printf "  $(GREEN) QEMU $(NC)  $(BOLD)  $<$(NC)\n"
	@qemu-system-x86_64 -drive format=raw,file=$<

.ONESHELL:
clean: os-img.bin $(wildcard out/*.o bin/*)
	@for i in $^; do
		$(call PRINT_STEP_DEL, "RM", $$i);\
			rm $$i;\
			done
