extern void clear();
extern int print(char *name);

void kmain() {
	clear();
	char name[] = "Kernel loaded\r\nHello Jaipal from 64-bit\r\nNew line 3";

	print(name);
	while(1) {
		asm("hlt"); 
	}
}
