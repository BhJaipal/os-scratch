#include "efierr.h"
#include <efi.h>

EFI_SYSTEM_TABLE *TB = 0;
extern void kmain();
EFI_STATUS efi_main(EFI_HANDLE img, EFI_SYSTEM_TABLE *table) {
	TB = table;
	table->ConOut->ClearScreen(table->ConOut);
	table->ConOut->OutputString(table->ConOut, u"Hello world");
	kmain();
	while (1) {
		asm("hlt");
	}
	return EFI_SUCCESS;
}
long __strlen(char *s) {
	long n = 0;
	while (s[n]) {
		n++;
	}
	return n;
}
void print(char *name) {
	unsigned short buff[2] = {0};

	long n = __strlen(name);

	for (long i = 0; i < n; i++) {
		buff[0] = name[i];
		TB->ConOut->OutputString(TB->ConOut, buff);
	}
}

void clear() {
	TB->ConOut->ClearScreen(TB->ConOut);
}
