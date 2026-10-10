#define MONITOR (*(volatile unsigned char *)0x00f00000UL)
#define RESULT  (*(volatile unsigned char *)0x0100f2UL)

__attribute__((noinline))
int add3(int a, int b)
{
    int sum = a + b;
    sum += 3;
    return sum;
}

int main(void)
{
    volatile int a = 5;
    volatile int b = 7;
    int result = add3(a, b);

    RESULT = (result == 15) ? 0x11 : 0xee;

    MONITOR = '1';
    MONITOR = '1';
    MONITOR = '\n';

    return 0;
}
