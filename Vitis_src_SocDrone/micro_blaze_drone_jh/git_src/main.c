/*
 * Drone Overview
 *
 *		-pitch
 * 		 0   1
 * +roll	 x sensor	-roll
 * 		 3   2
 * 		 +pitch
 *
 *			min duty	direction
 * Motor 0:	38			CCW
 * Motor 1:	39			CW
 * Motor 2:	33			CCW
 * Motor 3:	13			CW
 */


// standard include
#include <stdio.h>

// Xilinx include
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xiic.h"
#include "math.h"
#include "xintc.h"
#include "xil_exception.h"
#include "xuartlite.h"

// custom include
#include "myip_timer_interrupt.h"
#include "uart.h"
#include "intc.h"
#include "i2c_motion_sensor.h"
#include "pid_control.h"

#define SAMPLING_PERIOD_S 0.05	//sampling period in second


int main() {

    init_platform();
    myip_timerInterrupt_init();
    print("Start!\n");

    myip_bldcDriver_init();

    XUartLite_Initialize(&usb_uart_instance, USB_UART_ID);
    XUartLite_Initialize(&bluetooth_uart_instance, BLUETOOTH_UART_ID);

    XIic_Initialize(&iic_instance, IIC_ID);

	// Interrupt init
	XIntc_Initialize(&intc_instance, INTC_ID);
    XIntc_Connect(&intc_instance, TIMER_INTR_VEC_ID, (XInterruptHandler) timer_intr_handler, (void *) NULL);
    XIntc_Enable(&intc_instance, TIMER_INTR_VEC_ID);
    XIntc_Connect(&intc_instance, USB_UART_VEC_ID, (XInterruptHandler)XUartLite_InterruptHandler, (void *)&usb_uart_instance);
    XIntc_Enable(&intc_instance, USB_UART_VEC_ID);
    XIntc_Connect(&intc_instance, BLUETOOTH_UART_VEC_ID, (XInterruptHandler)XUartLite_InterruptHandler, (void *)&bluetooth_uart_instance);
    XIntc_Enable(&intc_instance, BLUETOOTH_UART_VEC_ID);
    XIntc_Start(&intc_instance, XIN_REAL_MODE);

    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler) XIntc_InterruptHandler, (void *) &intc_instance);
    Xil_ExceptionEnable();

    XUartLite_SetRecvHandler(&usb_uart_instance, usb_RecvHandler, &usb_uart_instance);
    XUartLite_SetSendHandler(&usb_uart_instance, usb_SendHandler, &usb_uart_instance);
    XUartLite_EnableInterrupt(&usb_uart_instance);
    XUartLite_SetRecvHandler(&bluetooth_uart_instance, bluetooth_RecvHandler, &bluetooth_uart_instance);
    XUartLite_SetSendHandler(&bluetooth_uart_instance, bluetooth_SendHandler, &bluetooth_uart_instance);
    XUartLite_EnableInterrupt(&bluetooth_uart_instance);

    uart_print(&bluetooth_uart_instance, "\n\nDrone (Rev. A) initializing, please wait...\n");

    MPU6050_Init();

    MB_Sleep(3000);	// for motor to startup

    myip_timerInterrupt_setInterval_us (timer0_interrupt_reg, SAMPLING_PERIOD_S * 1000000);
    myip_timerInterrupt_start (timer0_interrupt_reg);

    // Start receiving bluetooth byte
    XUartLite_Recv(&bluetooth_uart_instance, &rx_byte_buffer, 1);
    uart_print(&bluetooth_uart_instance, "Drone Ready. \"help\" for more command.\n\n");

    while(1);

    cleanup_platform();
    return 0;
}
