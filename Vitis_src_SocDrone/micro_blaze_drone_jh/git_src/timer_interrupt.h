#ifndef __TIMER_INTERRUPT_H_
#define __TIMER_INTERRUPT_H_

#include "xil_exception.h"
#include "xparameters.h"

#define SYSCLK_TO_US 100	// sysclk period (10ns) to 1us ratio

volatile unsigned int *timer0_interrupt_reg;

void myip_timerInterrupt_init();
void myip_timerInterrupt_setInterval_us (volatile unsigned int * timer_reg, int interval_us);
void myip_timerInterrupt_start (volatile unsigned int * timer_reg);
void myip_timerInterrupt_stop (volatile unsigned int * timer_reg);

#endif /* __TIMER_INTERRUPT_H__ */
