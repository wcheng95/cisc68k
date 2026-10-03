#include <stdint.h>

#define MONITOR (*(volatile uint8_t *)0x00f00000UL)

int main(void)
{
    MONITOR = 'H';
    MONITOR = 'i';
    MONITOR = '\n';

    return 0;
}
