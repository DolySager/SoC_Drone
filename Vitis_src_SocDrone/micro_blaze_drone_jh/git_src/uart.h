#ifndef __UART_H_
#define __UART_H_

#include "xuartlite.h"

#define USB_UART_ID 			XPAR_UARTLITE_0_DEVICE_ID
#define BLUETOOTH_UART_ID 		XPAR_UARTLITE_1_DEVICE_ID

#define RX_BUFFER_SIZE 20

XUartLite 	usb_uart_instance;
XUartLite 	bluetooth_uart_instance;

u8 rx_byte_buffer;
u8 rx_buffer[RX_BUFFER_SIZE];
u8 rx_buffer_index;
u8 is_uart_receiving;

u8 is_motor_off;

extern float Kp_roll, Ki_roll, Kd_roll;
extern float Kp_pitch, Ki_pitch, Kd_pitch;

void usb_SendHandler(void *CallBackRef, unsigned int EventData);
void usb_RecvHandler(void *CallBackRef, unsigned int EventData);
void bluetooth_SendHandler(void *CallBackRef, unsigned int EventData);
void bluetooth_RecvHandler(void *CallBackRef, unsigned int EventData);
void uart_print(XUartLite *uart_inst_ptr, const char *str_ptr);

void process_command (const u8 *str_ptr);
u8 * parse_command(u8 *input_buffer, u8 *output_buffer);
u32 parse_integer(const u8 *str_ptr);
float parse_float(const u8 *str_ptr);
u8 is_str_equal (const u8 *str1_ptr, const char *str2_ptr);

#endif
