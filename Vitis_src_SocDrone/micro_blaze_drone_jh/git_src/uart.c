#include "uart.h"
#include "xuartlite_l.h"

u8 rx_buffer_index = 0;
u8 is_uart_receiving = 0;

#define PARSE_BUFFER_SIZE 20
static u8 parse_buffer[PARSE_BUFFER_SIZE];

void usb_SendHandler(void *CallBackRef, unsigned int EventData)
{

}

void usb_RecvHandler(void *CallBackRef, unsigned int EventData)
{

}

void bluetooth_SendHandler(void *CallBackRef, unsigned int ByteCount)
{
	while (XUartLite_IsSending(&bluetooth_uart_instance));
}

void bluetooth_RecvHandler(void *CallBackRef, unsigned int ByteCount)
{
	// Process character
	rx_buffer[rx_buffer_index++] = rx_byte_buffer;		// use "rx_buffer_index" first then increment it
	if ((rx_buffer[rx_buffer_index-1] == '\r' ||  rx_buffer[rx_buffer_index-1] == '\n') &&  (rx_buffer[rx_buffer_index-2] == '\r' ||  rx_buffer[rx_buffer_index-2] == '\n') )
	{
		process_command(rx_buffer);
		rx_buffer_index = 0;
	}
	if (rx_buffer_index >= RX_BUFFER_SIZE-1) rx_buffer_index = 0;	// buffer overflow prevention

	XUartLite_Recv(&bluetooth_uart_instance, &rx_byte_buffer, 1);
}

// NOTE: *str_ptr++ is same as *(str_ptr++), not (*str_ptr)++
void uart_print(XUartLite *uart_inst_ptr, const char *str_ptr)
{
	while (*str_ptr != 0)
	{
		XUartLite_SendByte(uart_inst_ptr->RegBaseAddress, *str_ptr++);
	}
}

void process_command (const u8 *str_ptr)
{
	str_ptr = parse_command(str_ptr, parse_buffer);	// parse first command
	str_ptr++;							// increment str_handle pointer to skip space character

	if (is_str_equal(parse_buffer, "off"))
	{
		// Turn on PID mode
		is_motor_off = 1;
		uart_print(&bluetooth_uart_instance, "Motor off\n\r");
	}
	else if (is_str_equal(parse_buffer, "on"))
	{
		// Set motor power manually
		is_motor_off = 0;
	}
	else if (is_str_equal(parse_buffer, "set"))
	{
		str_ptr = parse_command(str_ptr, parse_buffer);
		str_ptr++;
		float input_float = parse_float(str_ptr);
		if (is_str_equal(parse_buffer, "kp"))
		{
			Kp_roll = input_float;
			Kp_pitch = input_float;
			uart_print(&bluetooth_uart_instance, "OK: Kp changed\n\r");
		}
		else if (is_str_equal(parse_buffer, "ki"))
		{
			Ki_roll = input_float;
			Ki_pitch = input_float;
			uart_print(&bluetooth_uart_instance, "OK: Ki changed\n\r");
		}
		else if (is_str_equal(parse_buffer, "kd"))
		{
			Kd_roll = input_float;
			Kd_pitch = input_float;
			uart_print(&bluetooth_uart_instance, "OK: Kd changed\n\r");
		}
		else
		{
			uart_print(&bluetooth_uart_instance, "Error\n\r");
		}
	}
	else if (is_str_equal(parse_buffer, "show"))
	{
		str_ptr = parse_command(str_ptr, parse_buffer);
		str_ptr++;
		if (is_str_equal(parse_buffer, "pid"))
		{
			// Send all pid constant values
		}
		else
		{
			uart_print(&bluetooth_uart_instance, "Error\n\r");
		}
	}
	else if (is_str_equal(parse_buffer, "help"))
	{
		uart_print(&bluetooth_uart_instance, "Help to be implemented...\n\r");
	}
	else
	{
		uart_print(&bluetooth_uart_instance, "Error\n\r");
	}
}

// NOTE: *str_ptr++ is same as *(str_ptr++), not (*str_ptr)++
u8 * parse_command(u8 *input_buffer, u8 *output_buffer)
{
	// reset buffer
	for (int i=0; i<PARSE_BUFFER_SIZE; ++i) output_buffer[i] = 0;
	
	while( (*input_buffer >= 'A' && *input_buffer <= 'Z') || (*input_buffer >= 'a' && *input_buffer <= 'z') )
	{
		*output_buffer++ = *input_buffer++;
	}

	return input_buffer;
}

// only process positive integer
// NOTE: *str_ptr++ is same as *(str_ptr++), not (*str_ptr)++
u32 parse_integer(const u8 *str_ptr)
{
	u32 result = 0;
	while (*str_ptr >= '0' && *str_ptr <= '9')
	{
		result = result * 10 + (*str_ptr++ - '0');
	}

	return result;
}

// NOTE: *str_ptr++ is same as *(str_ptr++), not (*str_ptr)++
float parse_float(const u8 *str_ptr)
{
	float result = 0;
	while (*str_ptr >= '0' && *str_ptr <= '9')
	{
		result = result * 10 + (*str_ptr++ - '0');
	}
	if (*str_ptr++ == '.')
	{
		u16 decimal_num_index = 1;
		while (*str_ptr >= '0' && *str_ptr <= '9')
		{
			u32 ten_powers = 1;
			for (int i=0; i<decimal_num_index; ++i) ten_powers *= 10;
			result = result + (float) (*str_ptr++ - '0') / (float) ten_powers;
			++decimal_num_index;
		}
	}
	return result;
}

// compare two string equality
// Does not check for string index overflow
u8 is_str_equal (const u8 *str1_ptr, const char *str2_ptr)
{
	u8 result = 1;
	u8 index = 0;

	do
	{
		if (str1_ptr[index] != str2_ptr[index])
		{
			result = 0;
			break;
		}
		index++;
	}
	while (str1_ptr[index] && str2_ptr[index]);

	return result;
}
