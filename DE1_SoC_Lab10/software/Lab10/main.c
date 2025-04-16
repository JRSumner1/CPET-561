/*
 * main.c - Lab 10: Fun with Audio
 *
 *  Created on: Apr 15, 2025
 *      Author: Jon Sumner
 *  Based on audio_demo.c by jxciee
 */

#include "alt_types.h"
#include "altera_avalon_timer.h"
#include "altera_avalon_timer_regs.h"
#include "altera_up_avalon_audio.h"
#include "io.h"
#include "math.h"
#include "sys/alt_irq.h"
#include "system.h"
#include <stdbool.h>
#include <stdio.h>

// create standard embedded type definitions
typedef signed char sint8;	   // signed 8 bit values
typedef unsigned char uint8;   // unsigned 8 bit values
typedef signed short sint16;   // signed 16 bit values
typedef unsigned short uint16; // unsigned 16 bit values
typedef signed long sint32;	   // signed 32 bit values
typedef unsigned long uint32;  // unsigned 32 bit values
typedef float real32;		   // 32 bit real values

// Global variables
#define MAX_SAMPLES 0x80000 // 0x80000 max sample data (16 bits each) for SDRAM
#define DELAY_SIZE     1024

volatile bool record_mode      = false;  // true while recording is active
volatile bool playback_ready   = false;  // true when recording is complete, waiting for playback trigger
volatile bool playback_mode    = false;  // true during playback
volatile uint32 record_index   = 0;      // index for recording into SDRAM buffer
volatile uint32 playback_index = 0;      // index for playback from SDRAM buffer

uint16 delay_buffer_left[DELAY_SIZE];
uint16 delay_buffer_right[DELAY_SIZE];
uint32 delay_idx = 0;  // circular index for delay buffer

// set up pointers to peripherals
uint16 *SdramPtr         = (uint16 *)NEW_SDRAM_CONTROLLER_0_BASE;
uint32 *AudioPtr         = (uint32 *)AUDIO_0_BASE;
uint32 *TimerPtr         = (uint32 *)TIMER_0_BASE;
uint32 *PinPtr           = (uint32 *)PIN_BASE;
uint32 *AudioVideoPtr    = (uint32 *)AUDIO_AND_VIDEO_CONFIG_0_BASE;
uint16 *FilterPtr        = (uint16 *)AUDIO_FILTER_0_BASE;  // custom filter component registers
uint32 *KEYPtr           = (uint32 *)KEY_BASE;
volatile uint32 *SWPtr   = (uint32 *)SW_BASE;
uint32 *LEDRPtr          = (uint32 *)LEDR_BASE;

volatile uint32 current_mode = 0;

uint16 process_lowpass(uint16 sample);
uint16 process_highpass(uint16 sample);

uint16 process_lowpass(uint16 sample)
{
    // For low pass filtering, assume writing the sample to FilterPtr+1
    // and reading back the filtered sample from FilterPtr.
    *(FilterPtr + 1) = sample;
    return *FilterPtr;
}

//---------------------------------------------------------------------
// process_highpass: feed sample to high-pass filter and return filtered result
//---------------------------------------------------------------------
uint16 process_highpass(uint16 sample)
{
    // The mechanism for high pass filtering might involve setting a control
    // bit. Here we assume that ORing the sample with 0x8000 selects high pass.
    *(FilterPtr + 1) = sample | 0x8000;
    return *FilterPtr;
}

void key_isr(void *context)
{
    // Read current KEY state; assume KEY1 is bit 1.
    uint32 key_val = *KEYPtr;

    // If KEY1 pressed (bit 1 active) and playback is ready, start playback.
    if ((key_val & 0x2) && playback_ready)
    {
         playback_mode = true;
         record_mode = false;
         playback_index = 0;
         printf("Playback started.\n");
    }

    // Clear KEY interrupt (platform-specific; may involve writing a 1 to the bit)
    // Here we simply return.
    return;
}

//---------------------------------------------------------------------
// main: entry point for Lab 10 program.
//---------------------------------------------------------------------
int main(void)
{
    // Variables for audio samples (32-bit used in FIFO operations, though only 16 bits carry audio)
    unsigned int l_buf = 0, r_buf = 0;
    unsigned int out_left = 0, out_right = 0;
    int fifospace = 0;

    printf("ESD-I Lab 10 Program Running.\n");

    // Register KEY interrupt (if your system supports KEY IRQ interrupts)
    alt_ic_isr_register(KEY_IRQ_INTERRUPT_CONTROLLER_ID, KEY_IRQ, key_isr, 0, 0);

    // Optionally, you could also register switch interrupts. For simplicity, we poll SW.
    // Turn off all LEDs initially.
    *LEDRPtr = 0x00;

    // Open audio device using the Altera University audio core.
    alt_up_audio_dev *audio_dev;
    audio_dev = alt_up_audio_open_dev("/dev/audio_0");
    if (audio_dev == NULL)
    {
        printf("Error: could not open audio device\n");
        return 1;
    }
    else
    {
        printf("Opened audio device.\n");
    }

    // Initialize delay buffers for Mode 5 to zeros.
    for (int i = 0; i < DELAY_SIZE; i++)
    {
        delay_buffer_left[i] = 0;
        delay_buffer_right[i] = 0;
    }

    // Main processing loop:
    while (1)
    {
        // Read the current mode from the slide switches (using lower 3 bits: SW2-SW0).
        // Mode mapping:
        //   0 -> Mode 1: Direct Echo
        //   1 -> Mode 2: Low Pass Filter
        //   2 -> Mode 3: High Pass Filter
        //   3 -> Mode 4: Record/Playback
        //   4 -> Mode 5: Delay/Echo effect
        current_mode = *SWPtr & 0x07;

        // Get available FIFO space for right channel (assumes audio samples for both channels are available).
        fifospace = alt_up_audio_read_fifo_avail(audio_dev, ALT_UP_AUDIO_RIGHT);
        if (fifospace > 0)
        {
            // Read samples from both channels.
            alt_up_audio_read_fifo(audio_dev, &r_buf, 1, ALT_UP_AUDIO_RIGHT);
            alt_up_audio_read_fifo(audio_dev, &l_buf, 1, ALT_UP_AUDIO_LEFT);

            // Process according to current mode.
            switch (current_mode)
            {
                // Mode 1: Direct Echo
                case 0:
                    out_left  = l_buf;
                    out_right = r_buf;
                    break;

                // Mode 2: Low Pass Filter
                case 1:
                    out_left  = process_lowpass(l_buf);
                    out_right = process_lowpass(r_buf);
                    break;

                // Mode 3: High Pass Filter
                case 2:
                    out_left  = process_highpass(l_buf);
                    out_right = process_highpass(r_buf);
                    break;

                // Mode 4: Record and Playback
                case 3:
                    if (!playback_mode)
                    {
                        // Begin recording if not already recording.
                        if (!record_mode)
                        {
                            record_mode = true;
                            playback_ready = false;
                            record_index = 0;
                            *LEDRPtr = 0x0F;  // Turn on red LEDs while recording.
                            printf("Recording started.\n");
                        }
                        // In recording mode: store stereo samples in SDRAM.
                        if (record_mode)
                        {
                            // Store left and right samples. (Increase index by 2 per stereo frame)
                            if (record_index < (MAX_SAMPLES - 2))
                            {
                                SdramPtr[record_index++] = (uint16)l_buf;
                                SdramPtr[record_index++] = (uint16)r_buf;
                                // Do not output live sound during recording:
                                out_left  = 0;
                                out_right = 0;
                            }
                            else
                            {
                                // Recording complete: turn off LED and enable playback trigger.
                                record_mode = false;
                                playback_ready = true;
                                *LEDRPtr = 0x00;
                                printf("Recording complete. Press KEY1 to playback.\n");
                                out_left  = 0;
                                out_right = 0;
                            }
                        }
                    }
                    else  // Playback mode active.
                    {
                        if (playback_index < record_index)
                        {
                            // Playback stored samples (assumes stereo stored as two consecutive words).
                            out_left  = SdramPtr[playback_index++];
                            out_right = SdramPtr[playback_index++];
                        }
                        else
                        {
                            // Playback finished; reset indices and state.
                            playback_mode = false;
                            record_mode = false;
                            playback_ready = false;
                            record_index = 0;
                            playback_index = 0;
                            out_left  = 0;
                            out_right = 0;
                            printf("Playback finished.\n");
                        }
                    }
                    break;

                // Mode 5: Student Concept (Delayed/Echo effect)
                case 4:
                    {
                        // Get delayed samples from the delay buffer.
                        uint16 delayed_left  = delay_buffer_left[delay_idx];
                        uint16 delayed_right = delay_buffer_right[delay_idx];
                        // Mix current sample with delayed sample (using a 0.5 attenuation factor).
                        out_left  = l_buf + (delayed_left >> 1);
                        out_right = r_buf + (delayed_right >> 1);

                        // Store the current sample into the delay buffer.
                        delay_buffer_left[delay_idx]  = (uint16)l_buf;
                        delay_buffer_right[delay_idx] = (uint16)r_buf;
                        // Update circular buffer index.
                        delay_idx = (delay_idx + 1) % DELAY_SIZE;
                    }
                    break;

                // Default: Fallback to echo.
                default:
                    out_left  = l_buf;
                    out_right = r_buf;
                    break;
            }

            // Write the processed samples out to the audio CODEC FIFOs.
            alt_up_audio_write_fifo(audio_dev, &out_right, 1, ALT_UP_AUDIO_RIGHT);
            alt_up_audio_write_fifo(audio_dev, &out_left, 1, ALT_UP_AUDIO_LEFT);
        }
    }  // end while(1)

    return 0;
}
