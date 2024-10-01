#ifndef __UART_H_
#define __UART_H_

#include "xuartlite.h"

#define USB_UART_ID 			XPAR_UARTLITE_0_DEVICE_ID
#define BLUETOOTH_UART_ID 		XPAR_UARTLITE_1_DEVICE_ID

XUartLite 	usb_uart_instance;
XUartLite 	bluetooth_uart_instance;


void usb_SendHandler(void *CallBackRef, unsigned int EventData);
void usb_RecvHandler(void *CallBackRef, unsigned int EventData);
void bluetooth_SendHandler(void *CallBackRef, unsigned int EventData);
void bluetooth_RecvHandler(void *CallBackRef, unsigned int EventData);

#endif
