#include "uart.h"
#include "xuartlite_l.h"

#define PARSE_BUFFER_SIZE 20
static u8 parse_buffer[PARSE_BUFFER_SIZE];

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
	rx_buffer[rx_buffer_index++] = rx_byte_buffer;		// use "rx_buffer_index" first then increment it
	if ((rx_buffer[rx_buffer_index-1] == '\r' ||  rx_buffer[rx_buffer_index-1] == '\n') &&  (rx_buffer[rx_buffer_index-2] == '\r' ||  rx_buffer[rx_buffer_index-2] == '\n') )
	{
		process_command(rx_buffer);
		rx_buffer_index = 0;
	}
	if (rx_buffer_index >= PARSE_BUFFER_SIZE-1) rx_buffer_index = 0;	// buffer overflow prevention

}

// NOTE: *str_ptr++ is same as *(str_ptr++), not (*str_ptr)++
void uart_print(XUartLite *uart_instance, const char *str_ptr)
{
	while (*str_ptr != 0)
	{
		XUartLite_SendByte(uart_instance->RegBaseAddress, *str_ptr++);
	}
}

void process_command (const u8 *str_ptr)
{
	u8 *str_handle;		// to keep track of parsing character

	str_handle = parse_command(str_ptr, parse_buffer);	// parse first command
	str_handle++;							// increment str_handle pointer to skip space character

	if (is_str_equal(parse_buffer, "auto"))
	{
		// Turn on PID mode
		uart_print(&bluetooth_uart_instance, "command auto received");
	}
	else if (is_str_equal(parse_buffer, "manual"))
	{
		// Set motor power manually
		/* motor_power = */ parse_integer(str_ptr);
	}
	else if (is_str_equal(parse_buffer, "set"))
	{
		str_handle = parse_command(str_ptr, parse_buffer);
		str_handle++;
		if (is_str_equal(parse_buffer, "roll"))
		{
			str_handle = parse_command(str_ptr, parse_buffer);
			str_handle++;
			if (is_str_equal(parse_buffer, "ki"))
			{
				// change roll ki value
			}
			else if (is_str_equal(parse_buffer, "kp"))
			{
				// change roll kp value
			}
			else
			{
				// Send error message
			}
		}
		else if (is_str_equal(parse_buffer, "pitch"))
		{
			str_handle = parse_command(str_ptr, parse_buffer);
			str_handle++;
			if (is_str_equal(parse_buffer, "ki"))
			{
				// change pitch ki value
			}
			else if (is_str_equal(parse_buffer, "kp"))
			{
				// change pitch kp value
			}
			else
			{
				// Send error message
			}
		}
		else
		{
			// Send error message
		}
	}
	else if (is_str_equal(parse_buffer, "show"))
	{
		str_handle = parse_command(str_ptr, parse_buffer);
		str_handle++;
		if (is_str_equal(parse_buffer, "pid"))
		{
			// Send all pid constant values
		}
		else
		{
			// Send error message
		}
	}
	else if (is_str_equal(parse_buffer, "help"))
	{
		// Send help message
	}
	else
	{
		// Send error message
	}
}

// NOTE: *str_ptr++ is same as *(str_ptr++), not (*str_ptr)++
u8 * parse_command(u8 *input_buffer, u8 *output_buffer)
{
	// reset buffer
	for (int i=0; i<PARSE_BUFFER_SIZE; i++) output_buffer[i] = 0;
	
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
			result = result + (*str_ptr++ - '0') / ten_powers;
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
