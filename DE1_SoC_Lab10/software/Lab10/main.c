/*
* main.c - Lab 10
*
*  Modified on: Apr 15, 2025
*      Author: Jon Sumner
*/

#include "alt_types.h"
#include "altera_up_avalon_audio.h"
#include "sys/alt_irq.h"
#include "system.h"
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

// Create standard embedded type definitions
typedef signed char  sint8;    // signed 8-bit
typedef unsigned char uint8;   // unsigned 8-bit
typedef signed short sint16;   // signed 16-bit
typedef unsigned short uint16; // unsigned 16-bit
typedef signed long  sint32;   // signed 32-bit
typedef unsigned long uint32;  // unsigned 32-bit
typedef float        real32;   // 32-bit real

// ---------------------------------------------------------------------
// Global constants, variables, and offsets
// ---------------------------------------------------------------------
#define MAX_SAMPLES   0x10000  // Max sample data (16 bits each) for SDRAM
#define DELAY_SIZE    1024
#define PIO_DATA_OFFSET       0
#define PIO_IRQ_MASK_OFFSET   8
#define PIO_EDGE_CAP_OFFSET   12

// Record/playback control
volatile bool   record_mode      = false;
volatile bool   playback_ready   = false;
volatile bool   playback_mode    = false;
volatile uint32 record_index     = 0;
volatile uint32 playback_index   = 0;

// Buffers for delay/echo in Mode 5
uint16 delay_buffer_left[DELAY_SIZE];
uint16 delay_buffer_right[DELAY_SIZE];
uint32 delay_idx = 0;  // Circular index for delay buffer

// ---------------------------------------------------------------------
// Memory-mapped peripheral pointers
// ---------------------------------------------------------------------
uint16 *SdramPtr         = (uint16 *)NEW_SDRAM_CONTROLLER_0_BASE;
uint32 *AudioPtr         = (uint32 *)AUDIO_0_BASE;
uint16 *FilterPtr        = (uint16 *)AUDIO_FILTER_0_BASE;
uint32 *KEYPtr           = (uint32 *)KEY_BASE;
volatile uint32 *SWPtr   = (uint32 *)SW_BASE;
uint32 *LEDRPtr          = (uint32 *)LEDR_BASE;

volatile uint32 current_mode = 0;

// ---------------------------------------------------------------------
// Forward declarations for filter routines and inline functions
// ---------------------------------------------------------------------
uint16 process_lowpass(uint16 sample);
uint16 process_highpass(uint16 sample);

static inline uint32_t pio_read(uint32_t base, uint32_t offset)
{
    return *((volatile uint32_t *)(base + offset));
}
static inline void pio_write(uint32_t base, uint32_t offset, uint32_t value)
{
    *((volatile uint32_t *)(base + offset)) = value;
}

// ---------------------------------------------------------------------
// Low-pass filter: Write sample to FilterPtr+1, read processed sample
// ---------------------------------------------------------------------
uint16 process_lowpass(uint16 sample)
{
    *(FilterPtr + 1) = sample;   // Send sample to custom LPF
    return *FilterPtr;           // Return filtered sample
}

// ---------------------------------------------------------------------
// High-pass filter: Assume OR’ing the sample with 0x8000 selects HPF
// ---------------------------------------------------------------------
uint16 process_highpass(uint16 sample)
{
    *(FilterPtr + 1) = sample | 0x8000;
    return *FilterPtr;                  
}

// ---------------------------------------------------------------------
// Interrupt Service Routine for KEY presses
//   KEY1 = bit1 in the KEY PIO
//   Feature: Pressing KEY1 ends recording immediately (if in progress)
//            and starts playback at once if samples are recorded
// ---------------------------------------------------------------------
void key_isr(void *context)
{
    // Read which key triggered the interrupt
    uint32_t key_val = pio_read(KEY_BASE, PIO_EDGE_CAP_OFFSET);
    // Clear the edge-capture by writing it back
    pio_write(KEY_BASE, PIO_EDGE_CAP_OFFSET, key_val);

    // Check if KEY1 (bit 1) was pressed
    if (key_val & 0x2)
    {
        // If we are currently recording, forcibly end the recording
        if (record_mode)
        {
            record_mode    = false;
            playback_ready = true;
            printf("Recording forcibly ended by KEY1.\n");
        }

        // If we have a valid recording (playback_ready == true),
        // start playback right away
        if (playback_ready)
        {
            playback_mode  = true;
            playback_index = 0;
            printf("Playback started.\n");
        }
    }
}

int main(void)
{
    printf("Lab 10 Audio Program Running...\n");

    // Clear any pending edge captures and enable interrupt on KEY1 if needed
    pio_write(KEY_BASE, PIO_EDGE_CAP_OFFSET, 0);
    // For KEY1 interrupt, you might need 0x2. If your hardware is set for KEY0, use 0x1, etc.
    pio_write(KEY_BASE, PIO_IRQ_MASK_OFFSET, 0x2);

    // Register the key_isr
    alt_ic_isr_register(KEY_IRQ_INTERRUPT_CONTROLLER_ID, KEY_IRQ, key_isr, 0, 0);

    alt_up_audio_dev *audio_dev = alt_up_audio_open_dev("/dev/audio_0");
    if (audio_dev == NULL)
    {
        printf("Error: could not open audio device\n");
        return 1;
    }
    else
    {
        printf("Opened audio device.\n");
    }

    // Initialize the delay/echo buffers for Mode 5
    for (int i = 0; i < DELAY_SIZE; i++)
    {
        delay_buffer_left[i]  = 0;
        delay_buffer_right[i] = 0;
    }

    // Main processing loop
    while (1)
    {
        // Read mode from SW2–SW0
        //  Mode 0 -> Microphone -> Speaker
        //  Mode 1 -> Low Pass Filter
        //  Mode 2 -> High Pass Filter
        //  Mode 3 -> Record/Playback
        //  Mode 4 -> Echo/Delay
        current_mode = *SWPtr & 0x07;

        // Check how many words in the input FIFO
        int fifospace = alt_up_audio_read_fifo_avail(audio_dev, ALT_UP_AUDIO_RIGHT);
        if (fifospace > 0)
        {
            unsigned int l_buf = 0, r_buf = 0;
            unsigned int out_left = 0, out_right = 0;

            // Read one sample from each channel
            alt_up_audio_read_fifo(audio_dev, &r_buf, 1, ALT_UP_AUDIO_RIGHT);
            alt_up_audio_read_fifo(audio_dev, &l_buf, 1, ALT_UP_AUDIO_LEFT);

            // Process samples based on current_mode
            switch (current_mode)
            {
                // (Mode 1) Low Pass Filter
                case 1:
                    *LEDRPtr = 0x01;  // For visual debugging
                    out_left  = process_lowpass((uint16)l_buf);
                    out_right = process_lowpass((uint16)r_buf);
                    break;

                // (Mode 2) High Pass Filter
                case 2:
                    *LEDRPtr = 0x02;
                    out_left  = process_highpass((uint16)l_buf);
                    out_right = process_highpass((uint16)r_buf);
                    break;

                // (Mode 3) Record/Playback
                case 3:
                {
                    *LEDRPtr = 0x04;

                    if (!playback_mode)
                    {
                        // If not currently playback_mode, we must be in recording
                        if (!record_mode)
                        {
                            record_mode      = true;
                            playback_ready   = false;
                            record_index     = 0;
                            printf("Recording started.\n");
                        }

                        // Continue recording if space remains
                        if (record_mode && (record_index < (MAX_SAMPLES - 2)))
                        {
                            // For demonstration, uncomment to see progress:
                            // printf("Still recording...\n");
                            SdramPtr[record_index++] = (uint16)l_buf;
                            SdramPtr[record_index++] = (uint16)r_buf;
                            // Mute output during recording
                            out_left  = 0;
                            out_right = 0;
                        }
                        else if (record_mode)
                        {
                            // Done recording because we've hit the buffer limit
                            record_mode      = false;
                            playback_ready   = true;
                            printf("Recording complete. Press KEY1 to playback.\n");
                            out_left  = 0;
                            out_right = 0;
                        }
                    }
                    else
                    {
                        // Currently in playback_mode
                        if (playback_index < record_index)
                        {
                            out_left  = SdramPtr[playback_index++];
                            out_right = SdramPtr[playback_index++];
                        }
                        else
                        {
                            // Done playing
                            playback_mode  = false;
                            playback_ready = false;
                            record_index   = 0;
                            playback_index = 0;
                            out_left       = 0;
                            out_right      = 0;
                            printf("Playback finished.\n");
                        }
                    }
                }
                break;

                // (Mode 4) Delay/Echo
                case 4:
                {
                    *LEDRPtr = 0x08;
                    // Retrieve old sample from delay buffer
                    uint16 delayed_left  = delay_buffer_left[delay_idx];
                    uint16 delayed_right = delay_buffer_right[delay_idx];

                    // Simple echo: current + (delayed >> 1)
                    out_left  = ((uint16)l_buf) + (delayed_left >> 1);
                    out_right = ((uint16)r_buf) + (delayed_right >> 1);

                    // Store new sample in delay buffer
                    delay_buffer_left[delay_idx]  = (uint16)l_buf;
                    delay_buffer_right[delay_idx] = (uint16)r_buf;

                    // Bump delay index (circular)
                    delay_idx = (delay_idx + 1) % DELAY_SIZE;
                }
                break;

                // (Mode 0) Microphone -> Speaker direct
                default:
                    *LEDRPtr = 0x00;
                    out_left  = l_buf;
                    out_right = r_buf;
                    break;
            }

            // Write processed samples to CODEC (FIFO)
            alt_up_audio_write_fifo(audio_dev, &out_right, 1, ALT_UP_AUDIO_RIGHT);
            alt_up_audio_write_fifo(audio_dev, &out_left, 1, ALT_UP_AUDIO_LEFT);
        }
    }

    return 0;
}
