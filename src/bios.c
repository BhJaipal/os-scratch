long __strlen(char *s) {
	long res = 0;
	while (s[res]) {
		res++;
	}
	return res;
}
#define VIDEO_MEMORY ((short*)0xb8000)
#define WHITE_ON_BLACK 0x0f
int print(char *name) {
	int video_location = 0;
	long len = __strlen(name);
	for (int i = 0; i < len; i++) {
		if (name[i] == '\r') continue;
		if (name[i] == '\n') {
			video_location = ((video_location / 80) + 1) * 80;
			continue;
		}
		VIDEO_MEMORY[video_location] = (WHITE_ON_BLACK << 8) | name[i];
		video_location++;
	}
	return video_location;
}

void clear() {
	for (int i = 0; i < 0x80; i++) {
		VIDEO_MEMORY[i] = (WHITE_ON_BLACK << 8) | ' ';
	}
}
