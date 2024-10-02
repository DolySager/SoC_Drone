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
#include "timer_interrupt.h"
#include "uart.h"
#include "intc.h"
#include "motion_sensor.h"
#include "pid_control.h"


#define SAMPLING_PERIOD_S 0.05	//sampling period in second

/************************ Interrupt Related ***************************/

#define TIMER_INTR_VEC_ID XPAR_INTC_0_MYIP_TIMER_INTERRUPT_0_VEC_ID
#define TIMER_INTR_BASEADDR XPAR_MYIP_TIMER_INTERRUPT_0_S00_AXI_BASEADDR

XIntc intc_instance;
volatile unsigned int* timer_intr_reg;

/************************ IIC/MPU/MOTOR - ADDR ***************************/

#define IIC_ID 					XPAR_IIC_0_DEVICE_ID
#define IIC_BASEADDR			XPAR_IIC_0_BASEADDR

XIic iic_instance;

#define BLDC_MOTOR_BASEADDR 	XPAR_MYIP_DRONE_BLDC_MOTO_0_S00_AXI_BASEADDR
volatile s32* motor_power_reg;

extern s16 accel_data[3], gyro_data[3];
extern s16 accel_offset[3], gyro_offset[3];

void timer_intr_handler(void *CallBackRef);


int main() {

    init_platform();
    myip_timerInterrupt_init();
    print("Start!\n\r");

    motor_power_reg = (volatile s32*) BLDC_MOTOR_BASEADDR;

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

    uart_print(&bluetooth_uart_instance, "Drone initializing, please wait...\n\r");

    // motor middle value
    motor_power_reg[0] = 0;
    motor_power_reg[1] = 0;
    motor_power_reg[2] = 0;
    motor_power_reg[3] = 0;

    MPU6050_Init();
// 	calculate_Offset(accel_data, gyro_data, 500);	//when the device start, it averages 500

    MB_Sleep(3000);	// for motor to startup

    myip_timerInterrupt_setInterval_us (timer0_interrupt_reg, SAMPLING_PERIOD_S * 1000000);
    myip_timerInterrupt_start (timer0_interrupt_reg);

    // Start receiving bluetooth byte
    XUartLite_Recv(&bluetooth_uart_instance, &rx_byte_buffer, 1);
    uart_print(&bluetooth_uart_instance, "Drone Ready, input command...\n\r");

    while(1)
    {

    }

    cleanup_platform();
    return 0;
}


void timer_intr_handler(void *CallBackRef)
{
	static float integral_roll, integral_pitch;

	/******** JH code  *********/

   // read accel, gyro data
   MPU6050_ReadAccelGyro(accel_data, gyro_data);


   // offset
//	   accel_data[0] -= accel_offset[0];
//	   accel_data[1] -= accel_offset[1];
//	   accel_data[2] -= accel_offset[2];
//
//	   gyro_data[0]	-= gyro_offset[0];
//	   gyro_data[1]	-= gyro_offset[1];
//	   gyro_data[2]	-= gyro_offset[2];


   // accel - Roll,Pitch
   roll_accel = calculateAccelRoll(accel_data[0], accel_data[1], accel_data[2]);
   pitch_accel = calculateAccelPitch(accel_data[0], accel_data[1], accel_data[2]);

   // gyro - Roll,Pitch
//	   roll_gyro += (gyro_data[0]) / 131.0 * dt;
//	   pitch_gyro += (gyro_data[1]) / 131.0 * dt;


   // Complementary Filter
//	   roll_filtered = complementaryFilter(roll_accel, roll_gyro, alpha);
//	   pitch_filtered = complementaryFilter(pitch_accel, pitch_gyro, alpha);
   roll_filtered = roll_accel;
   pitch_filtered = pitch_accel;

   float error_roll, error_pitch;
   error_roll = PID_Control(0, roll_filtered, &integral_roll, Kp_roll, Ki_roll, Kd_roll, SAMPLING_PERIOD_S);
   error_pitch = PID_Control(0, pitch_filtered, &integral_pitch, Kp_pitch, Ki_pitch, Kd_pitch, SAMPLING_PERIOD_S);



   /*		-pitch
	* 		 0   1
	* +roll	 	 x motion_sensor	-roll
	* 		 3   2
	* 		 +pitch
	*/

   motor_power_reg[0] = (s16) ((float) motor_power_reg[0] - error_roll + error_pitch);
   motor_power_reg[1] = (s16) ((float) motor_power_reg[1] + error_roll + error_pitch);
   motor_power_reg[2] = (s16) ((float) motor_power_reg[2] + error_roll - error_pitch);
   motor_power_reg[3] = (s16) ((float) motor_power_reg[3] - error_roll - error_pitch);

   for (u8 i=0; i<4; i++)
   {
	   if (motor_power_reg[i] > 255) motor_power_reg[i] = 255;
	   else if (motor_power_reg[i] < 0) motor_power_reg[i] = 0;

   }

   printf("%03.3f %03.3f / %03.3f %03.3f / %3d %3d %3d %3d\n\r", roll_filtered, pitch_filtered, error_roll, error_pitch, motor_power_reg[0], motor_power_reg[1], motor_power_reg[2], motor_power_reg[3]);
}
