#ifndef __TIMER_INTERRUPT_H__
#define __TIMER_INTERRUPT_H__

#include "xil_exception.h"
#include "xparameters.h"

#define SYSCLK_TO_US 100	// sysclk period (10ns) to 1us ratio

volatile unsigned int *timer_interrupt_reg;

void myip_timerInterrupt_init();
void myip_timerInterrupt_setInterval_us (u32 interval_us);
void myip_timerInterrupt_start ();
void myip_timerInterrupt_stop ();

#endif /* __TIMER_INTERRUPT_H__ */
