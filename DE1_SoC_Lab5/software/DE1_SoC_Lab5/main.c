/*
 * main.c
 *
 *  Created on: Mar 18, 2025
 *      Author: Jon Sumner
 */
#include "system.h"
#include <stdio.h>

typedef unsigned int alt_u32;

static inline alt_u32 HW_REG_READ(alt_u32 addr)
{
    return *((volatile alt_u32 *) (addr));
}

static inline void HW_REG_WRITE(alt_u32 addr, alt_u32 data)
{
    *((volatile alt_u32 *) (addr)) = data;
}

#define PIO_DATA_OFFSET 0
#define PIO_EDGE_CAP_OFFSET 4
#define PIO_IRQ_MASK_OFFSET 8

static inline alt_u32 PIO_READ_EDGE(alt_u32 base)
{
    return HW_REG_READ(base + PIO_EDGE_CAP_OFFSET);
}
static inline void PIO_CLEAR_EDGE(alt_u32 base, alt_u32 val)
{
    HW_REG_WRITE(base + PIO_EDGE_CAP_OFFSET, val);
}
static inline void PIO_SET_IRQ_MASK(alt_u32 base, alt_u32 mask)
{
    HW_REG_WRITE(base + PIO_IRQ_MASK_OFFSET, mask);
}

#define SERVO_OFFSET_MIN_ANGLE   0
#define SERVO_OFFSET_MAX_ANGLE   4
#define SERVO_OFFSET_STATUS      8

// If you were using alt_ic_isr_register for interrupts, you’d need to replace that
// with whatever direct interrupt registration your system uses (or skip interrupts).

volatile int minAngle = 45;
volatile int maxAngle = 135;
volatile int anglesUpdated = 1;

static int  convertAngleToCounts(int angle);
static void update7SegmentDisplays(int minAng, int maxAng);

int main(void)
{
    PIO_SET_IRQ_MASK(PUSHBUTTONS_BASE, 0xF);
    PIO_CLEAR_EDGE(PUSHBUTTONS_BASE, 0xF);

    HW_REG_WRITE(SERVO_CONTROLLER_0_BASE + SERVO_OFFSET_MIN_ANGLE,
                 convertAngleToCounts(minAngle));
    HW_REG_WRITE(SERVO_CONTROLLER_0_BASE + SERVO_OFFSET_MAX_ANGLE,
                 convertAngleToCounts(maxAngle));

    while (1)
    {
        if (anglesUpdated)
        {
            anglesUpdated = 0;
            update7SegmentDisplays(minAngle, maxAngle);
        }
    }
    return 0;
}

void myPushbuttonHandler(void)
{
    alt_u32 edges = PIO_READ_EDGE(PUSHBUTTONS_BASE);
    PIO_CLEAR_EDGE(PUSHBUTTONS_BASE, edges);

    alt_u32 swVal = HW_REG_READ(SWITCHES_BASE + PIO_DATA_OFFSET) & 0xFF;

    if (edges & 0x8) {
        minAngle = (int)swVal;
        anglesUpdated = 1;
    }
    if (edges & 0x4) {
        maxAngle = (int)swVal;
        anglesUpdated = 1;
    }
}

void myServoISR(void)
{
    HW_REG_WRITE(SERVO_CONTROLLER_0_BASE + SERVO_OFFSET_MIN_ANGLE,
                 convertAngleToCounts(minAngle));
    HW_REG_WRITE(SERVO_CONTROLLER_0_BASE + SERVO_OFFSET_MAX_ANGLE,
                 convertAngleToCounts(maxAngle));

    // HW_REG_WRITE(SERVO_CONTROLLER_0_BASE + SERVO_OFFSET_STATUS, 0);
}

static int convertAngleToCounts(int angle)
{
    const int baseCount = 50000;  // ~1 ms at 50 MHz
    const int maxCount  = 100000; // ~2 ms
    const int slope     = (maxCount - baseCount) / 180;
    return baseCount + angle * slope;
}

static void update7SegmentDisplays(int minAng, int maxAng)
{
    static const unsigned char seg7[10] = {
      0x40, // 0
      0x79, // 1
      0x24, // 2
      0x30, // 3
      0x19, // 4
      0x12, // 5
      0x02, // 6
      0x78, // 7
      0x00, // 8
      0x18  // 9
    };
    const unsigned char blank = 0x7F;

    int tens = (minAng / 10) % 10;
    int ones = (minAng % 10);

    unsigned char segTens = (minAng < 10) ? blank : seg7[tens];
    unsigned char segOnes = seg7[ones];

    HW_REG_WRITE(HEX5_BASE + PIO_DATA_OFFSET, segTens);
    HW_REG_WRITE(HEX4_BASE + PIO_DATA_OFFSET, segOnes);

    int hundreds = (maxAng / 100) % 10;
    tens        = (maxAng / 10)  % 10;
    ones        = (maxAng % 10);

    unsigned char segHundreds, segT, segO;
    if (maxAng < 10) {
        segHundreds = blank;
        segT        = blank;
        segO        = seg7[ones];
    } else if (maxAng < 100) {
        segHundreds = blank;
        segT        = seg7[tens];
        segO        = seg7[ones];
    } else {
        segHundreds = seg7[hundreds];
        segT        = seg7[tens];
        segO        = seg7[ones];
    }

    HW_REG_WRITE(HEX2_BASE + PIO_DATA_OFFSET, segHundreds);
    HW_REG_WRITE(HEX1_BASE + PIO_DATA_OFFSET, segT);
    HW_REG_WRITE(HEX0_BASE + PIO_DATA_OFFSET, segO);
}
