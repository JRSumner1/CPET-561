// Holly Dickens 
// 01-31-2021
// Code sets up pointers to switches and leds base address 
// Forever reads switches then places values on LEDs 

#include "system.h" // includes information about system configuration 

int main(void)
{
   // point to base addresses for SWs and LEDs
   unsigned char *switchesBase_ptr = (unsigned char *) SWITCHES_BASE;
   unsigned char *ledsBase_ptr     = (unsigned char *) LEDS_BASE;
   unsigned char switch_val; //temp storage

   while(1) {
      switch_val    = *switchesBase_ptr; // get switch value 
      *ledsBase_ptr = switch_val;        // put sw value on leds
   }
}
