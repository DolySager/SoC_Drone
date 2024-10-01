#include "uart.h"
#include "xuartlite_l.h"

static u8 command_buffer[10], number_buffer[10];

void usb_SendHandler(void *CallBackRef, unsigned int EventData)
{

}

void usb_RecvHandler(void *CallBackRef, unsigned int EventData)
{

}

void bluetooth_SendHandler(void *CallBackRef, unsigned int EventData)
{

}

void bluetooth_RecvHandler(void *CallBackRef, unsigned int EventData)
{
	// Process character
	XUartLite_Recv(&bluetooth_uart_instance, &rx_byte_buffer, 1);
	rx_buffer[buffer_index++] = rx_byte_buffer;		// use "buffer_index" first then increment it
	if ((rx_buffer[buffer_index-1] == '\r' ||  rx_buffer[buffer_index-1] == '\n') &&  (rx_buffer[buffer_index-2] == '\r' ||  rx_buffer[buffer_index-2] == '\n') )
	{
		process_command(rx_buffer);
		buffer_index = 0;
	}
	if (buffer_index >= 19) buffer_index = 0;	// buffer overflow prevention

}

void uart_print(XUartLite *uart_instance, const u8 *str_ptr)
{
	while (*str_ptr != 0)
	{
		XUartLite_SendByte(uart_instance->RegBaseAddress, *str_ptr);
		str_ptr++;
	}
}

void process_command (const u8 *str_ptr)
{
	parse_command(str_ptr);
	if (is_str_equal(command_buffer, "on"))
	{

	}
	else if (is_str_equal(command_buffer, "off"))
	{

	}
}

void parse_command(const u8 *str_ptr)
{
	// reset buffer
	for (int i=0; i< sizeof(command_buffer); i++) command_buffer[i] = 0;
	for (int i=0; i< sizeof(number_buffer); i++) number_buffer[i] = 0;

	// parse command part
	while( (*str_ptr >= 'A' && *str_ptr <= 'Z') || (*str_ptr >= 'a' && *str_ptr <= 'z') )
	{
		u8 command_index = 0;
		command_buffer[command_index] = *str_ptr;
		str_ptr++;
	}

	// parse number part
	while ((*str_ptr >= '0' && *str_ptr <= '9') || *str_ptr == '.')
	{
		u8 number_index = 0;
		number_buffer[number_index] = *str_ptr;
		str_ptr++;
	}

}

// compare two string equality
// Does not check for string index overflow
void is_str_equal (const u8 *str1_ptr, const u8 *str2_ptr)
{
	u8 result = 1;
	u8 index = 0;
	while (str1_ptr[index] && str2_ptr[index])
	{
		if (str1_ptr[index] != str2_ptr[index])
		{
			result = 0;
			break;
		}
		index++;
	}

	return result;
}
