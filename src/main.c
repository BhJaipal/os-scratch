
void clear(const char WHITE_ON_BLACK, short *VIDEO_MEMORY);
void kmain() {
	short *VIDEO_MEMORY = (short*)0xb8000;
	const char WHITE_ON_BLACK= 0x0f;

	clear(WHITE_ON_BLACK, VIDEO_MEMORY);
	char name[] = "Kernel loaded                      Hello Jaipal";
	for (int i = 0; i < 12; i++) {
		VIDEO_MEMORY[i] = (WHITE_ON_BLACK << 8) | name[i];
		asm("add $1, %ebx\n");
	}
}

void clear(const char WHITE_ON_BLACK, short *VIDEO_MEMORY) {
	for (int i = 0; i < 0x80; i++) {
		VIDEO_MEMORY[i] = (WHITE_ON_BLACK << 8) | ' ';
		asm("add $1, %ebx\n");
	}
}
