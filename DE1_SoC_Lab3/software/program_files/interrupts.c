#include <stdint.h>
#include "system.h"
#include "sys/alt_irq.h"

#define PIO_DATA_OFFSET       0
#define PIO_IRQ_MASK_OFFSET   8
#define PIO_EDGE_CAP_OFFSET   12

static inline uint32_t pio_read(uint32_t base, uint32_t offset) {
    return *((volatile uint32_t *)(base + offset));
}

static inline void pio_write(uint32_t base, uint32_t offset, uint32_t value) {
    *((volatile uint32_t *)(base + offset)) = value;
}

static const uint8_t seven_seg_table[10] = {
    0x40, /* 0 */
    0x79, /* 1 */
    0x24, /* 2 */
    0x30, /* 3 */
    0x19, /* 4 */
    0x12, /* 5 */
    0x02, /* 6 */
    0x78, /* 7 */
    0x00, /* 8 */
    0x18  /* 9 */
};

volatile int g_count = 0;

static void pushbutton_ISR(void *context)
{
    pio_write(PUSHBUTTONS_BASE, PIO_EDGE_CAP_OFFSET, 0);

    uint32_t sw_val = pio_read(SWITCHES_BASE, PIO_DATA_OFFSET);
    int sw0 = (sw_val & 0x01) ? 1 : 0;

    if (sw0) {
        if (g_count < 9) {
            g_count++;
        }
    } else {
        if (g_count > 0) {
            g_count--;
        }
    }

    *((volatile uint8_t *)HEX0_BASE) = seven_seg_table[g_count];
}

int main(void)
{
    g_count = 0;
    *((volatile uint8_t *)HEX0_BASE) = seven_seg_table[g_count];

    pio_write(PUSHBUTTONS_BASE, PIO_EDGE_CAP_OFFSET, 0);

    pio_write(PUSHBUTTONS_BASE, PIO_IRQ_MASK_OFFSET, 0x2);

    alt_ic_isr_register(
        PUSHBUTTONS_IRQ_INTERRUPT_CONTROLLER_ID,
        PUSHBUTTONS_IRQ,
        pushbutton_ISR,
        NULL,
        NULL
    );

    return 0;
}
