long __strlen(char *s) {
	long res = 0;
	while (s[res]) {
		res++;
	}
	return res;
}

void clear(const char WHITE_ON_BLACK, short *VIDEO_MEMORY);
void kmain() {
	short *VIDEO_MEMORY = (short*)0xb8000;
	const char WHITE_ON_BLACK = 0x0f;

	clear(WHITE_ON_BLACK, VIDEO_MEMORY);
	char name[] = "Kernel loaded\nHello Jaipal from 64-bit";
	int video_location = 0;

	long len = __strlen(name);
	for (int i = 0; i < len; i++) {
		if (name[i] == '\n') {
			video_location = 80;
			continue;
		}
		VIDEO_MEMORY[video_location] = (WHITE_ON_BLACK << 8) | name[i];
		video_location++;
	}

	while(1) {
		asm("hlt"); 
	}
}

void clear(const char WHITE_ON_BLACK, short *VIDEO_MEMORY) {
	for (int i = 0; i < 0x80; i++) {
		VIDEO_MEMORY[i] = (WHITE_ON_BLACK << 8) | ' ';
	}
}
