#define MONITOR (*(volatile unsigned char *)0x00f00000UL)

static void putc(char c)
{
    MONITOR = (unsigned char)c;
}

int main(void)
{
    const char *p = "OK LAB00 PASS\n";

    while (*p)
        putc(*p++);

    return 0;
}
