#include "timer_interrupt.h"

/*
 * Link timer interrupt module control register
 */
void myip_timerInterrupt_init()
{
	timer_interrupt_reg = (volatile unsigned int *) XPAR_MYIP_TIMER_INTERRUPT_0_S00_AXI_BASEADDR;
}

/*
 * Set interrupt interval
 * @param interval_us: desired interrupt interval in us
 */
void myip_timerInterrupt_setInterval_us (u32 interval_us)
{
	timer_interrupt_reg[1] = interval_us * SYSCLK_TO_US;
}

/*
 * Turn on timer interrupt module
 */
void myip_timerInterrupt_start ()
{
	timer_interrupt_reg[0] = 1;
}

/*
 * Turn off timer interrupt module
 */
void myip_timerInterrupt_stop ()
{
	timer_interrupt_reg[0] = 0;
}
