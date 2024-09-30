#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xiic.h"
#include "math.h"
#include "xintc.h"
#include "xil_exception.h"
#include "xuartlite.h"

#include "timer_interrupt.h"


/************************ UART (+ Interrupt) ***************************/

#define UART_ID 		XPAR_UARTLITE_0_DEVICE_ID
#define UART_VEC_ID 	XPAR_INTC_0_UARTLITE_0_VEC_ID

#define INCT_ID XPAR_MICROBLAZE_0_AXI_INTC_DEVICE_ID

XUartLite 	uart_intance;

#define SAMPLING_PERIOD_S 0.05	//sampling period in second

/************************ Interrupt Related ***************************/
#define INTC_ID XPAR_INTC_SINGLE_DEVICE_ID
#define TIMER_INTR_VEC_ID XPAR_INTC_0_MYIP_TIMER_INTERRUPT_0_VEC_ID
#define TIMER_INTR_BASEADDR XPAR_MYIP_TIMER_INTERRUPT_0_S00_AXI_BASEADDR

XIntc intc_instance;
volatile unsigned int* timer_intr_reg;

/************************ IIC/MPU/MOTOR - ADDR ***************************/

#define IIC_ID 					XPAR_IIC_0_DEVICE_ID
#define IIC_BASEADDR			XPAR_IIC_0_BASEADDR

XIic iic_instance;


#define MPU6050_ADDR		    0x68

#define BLDC_MOTOR_BASEADDR 	XPAR_MYIP_DRONE_BLDC_MOTO_0_S00_AXI_BASEADDR
volatile s16* motor_power_reg;

/***************************** LCD define *********************************/

#define LCD_RS			0
#define LCD_RW			1
#define LCD_E			2
#define LCD_BACKLIGHT	3

#define LCD_DEV_ADDR	(0x27<<1)	// address 0x27 beginning from bit 1, bit 0 is R/W_bar

#define COMMAND_DISPLAY_CLEAR	0x01
#define COMMAND_DISPLAY_ON		0x0C
#define COMMAND_DISPLAY_OFF		0x08
#define COMMAND_ENTRY_MODE		0x06
#define COMMAND_4BIT_MODE		0x28


/***************************** MPU 6050 *********************************/

/*
#define Calibration_Accel_X  2
#define Calibration_Accel_Y  1
#define Calibration_Accel_Z  166

#define Calibration_Gyro_X  0
#define Calibration_Gyro_Y  0
#define Calibration_Gyro_Z  2
*/

float roll_gyro = 0;
float pitch_gyro = 0;

float roll_accel = 0;
float pitch_accel = 0;

float roll_filtered = 0;
float pitch_filtered = 0;

// gyro - 98% , accel - 2%
float alpha = 0.98;
float dt = 0.01;

int16_t accel_sum[3] = {0,};
int16_t gyro_sum[3]  = {0,};

int16_t accel_offset[3] = {0,};
int16_t gyro_offset[3]	= {0,};

int16_t accel_data[3], gyro_data[3];

// gyro offset correction
int16_t gyro_offset_x = 0;
int16_t gyro_offset_y = 0;
int16_t gyro_offset_z = 0;


float gyro_rate;
float threshold = 0.1;

/***************************** pi control *********************************/

float Kp_roll = 1.5;
float Ki_roll = 0.01;

float Kp_pitch = 1.5;
float Ki_pitch = 0.01;

float target_roll = 0.0;
float target_pitch = 0.0;

float roll_integral = 0.0;
float pitch_integral = 0.0;


/***************************** function prototype *********************************/

void LCD_Data_4bit (u8 data);
void LCD_EnablePin();
void LCD_WriteCommand(uint8_t commandData);
void LCD_WriteData(uint8_t charData);
void LCD_Init();
void LCD_BackLightOn();
void LCD_GotoXY(uint8_t row, uint8_t col);
void LCD_WriteString(char *string);

void MPU6050_Write(u8 reg, u8 data);
void MPU6050_Read(u8 reg, u8 *buffer, u16 len);
void MPU6050_ReadAccelGyro(int16_t *accel_data, int16_t *gyro_data);
void MPU6050_Init(void);


float calculateAccelRoll(int16_t accel_x, int16_t accel_y, int16_t accel_z);
float calculateAccelPitch(int16_t accel_x, int16_t accel_y, int16_t accel_z);

void calculate_Offset(int16_t accel_data[3], int16_t gyro_data[3], int samples);
float complementaryFilter(float angle_accel, float angle_gyro, float alpha, float gyro_rate, float threshold);

float PI_Control(float target_angle, float current_angle, float* integral, float Kp, float Ki, float dt);


void SendHandler(void *CallBackRef, unsigned int EventData);
void RecvHandler(void *CallBackRef, unsigned int EventData);


void timer_intr_handler(void *CallBackRef);



int main() {

    init_platform();
    myip_timerInterrupt_init();
    print("Start!\n\r");

    motor_power_reg = (volatile s16*) BLDC_MOTOR_BASEADDR;

    XUartLite_Initialize(&uart_intance, UART_ID);
    XIic_Initialize(&iic_instance, IIC_ID);

    MPU6050_Init();

//    LCD_Init();
//    LCD_WriteString("A: ");
//    LCD_GotoXY(1, 0);
//    LCD_WriteString("G: ");

  // calculate_Offset(accel_data, gyro_data, 500);	//when the device start, it averages 500


	// Interrupt init
	XIntc_Initialize(&intc_instance, INTC_ID);
    XIntc_Connect(&intc_instance, TIMER_INTR_VEC_ID, (XInterruptHandler) timer_intr_handler, (void *) NULL);
    XIntc_Enable(&intc_instance, TIMER_INTR_VEC_ID);
    XIntc_Start(&intc_instance, XIN_REAL_MODE);

    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler) XIntc_InterruptHandler, (void *) &intc_instance);
    Xil_ExceptionEnable();

    XIntc_Connect(&intc_instance, UART_VEC_ID, (XInterruptHandler)XUartLite_InterruptHandler, (void *)&uart_intance);
    XIntc_Enable(&intc_instance, UART_VEC_ID);

    XUartLite_SetRecvHandler(&uart_intance, RecvHandler, &uart_intance);
    XUartLite_SetSendHandler(&uart_intance, SendHandler, &uart_intance);
    XUartLite_EnableInterrupt(&uart_intance);

    // motor middle value
    motor_power_reg[0] = 0;
    motor_power_reg[1] = 0;
    motor_power_reg[2] = 0;
    motor_power_reg[3] = 0;

    myip_timerInterrupt_setInterval_us (SAMPLING_PERIOD_S * 1000000);
    myip_timerInterrupt_start ();

    while(1)
    {

    }

    cleanup_platform();
    return 0;
}



//////////////////////////////corrections/////////////////////////////


/***************************** pi control*********************************/
float PI_Control(float target_angle, float current_angle, float* integral, float Kp, float Ki, float dt)
{
    float error = target_angle - current_angle;

    *integral += error * dt;

    float output = (Kp * error) + (Ki * (*integral));

    return output;
}


/*****************************Filter************************************/


float complementaryFilter(float angle_accel, float angle_gyro, float alpha, float gyro_rate, float threshold)
{
    // if drone stop
    if (fabs(gyro_rate) < threshold)
    {
        return angle_accel;
    }
    else	// if drone working
    {
    	return alpha * (angle_gyro) + (1.0 - alpha) * angle_accel;
    }
}

////////////////////////////////////////////////////////////////////////




/***************************Roll degree*********************************/
float calculateAccelRoll(int16_t accel_x, int16_t accel_y, int16_t accel_z)
{
    return atan2f(accel_y, sqrtf(accel_x * accel_x + accel_z * accel_z)) * (180 / M_PI);
}

/*****************************Pitch degree******************************/
float calculateAccelPitch(int16_t accel_x, int16_t accel_y, int16_t accel_z)
{
    return atan2f(accel_x, sqrtf(accel_y * accel_y + accel_z * accel_z)) * -(180 / M_PI);
}


/*****************************Offset(Average)********************************/

void calculate_Offset(int16_t accel_data[3], int16_t gyro_data[3], int samples)
{
    for (int i = 0; i < samples; i++)
    {
    	MPU6050_ReadAccelGyro(accel_data, gyro_data);

    	accel_sum[0] += accel_data[0];
    	accel_sum[1] += accel_data[1];
    	accel_sum[2] += accel_data[2];

    	gyro_sum[0] += gyro_data[0];
    	gyro_sum[1] += gyro_data[1];
    	gyro_sum[2] += gyro_data[2];

        printf("%d\n", i);
        MB_Sleep(10);
    }

    /*Average*/
    accel_offset[0] = accel_sum[0] / samples;
    accel_offset[1] = accel_sum[1] / samples;
    accel_offset[2] = accel_sum[2] / samples;

    gyro_offset[0] = gyro_sum[0] / samples;
    gyro_offset[1] = gyro_sum[1] / samples;
    gyro_offset[2] = gyro_sum[2] / samples;
}


/***************************** MPU 6050 function ********************************/


void MPU6050_Write(u8 reg, u8 data) {
    u8 buffer[2] = {reg, data};
    XIic_Send(iic_instance.BaseAddress, MPU6050_ADDR, buffer, 2, XIIC_STOP);
}


void MPU6050_Read(u8 reg, u8 *buffer, u16 len) {
	XIic_Send(iic_instance.BaseAddress, MPU6050_ADDR, &reg, 1, XIIC_STOP);
    XIic_Recv(iic_instance.BaseAddress, MPU6050_ADDR, buffer, 14, XIIC_STOP);
}



void MPU6050_ReadAccelGyro(int16_t *accel_data, int16_t *gyro_data) {
    u8 buffer[14];

    MPU6050_Read(0x3B, buffer, 14);

    accel_data[0] = (buffer[0] << 8) | buffer[1];
    accel_data[1] = (buffer[2] << 8) | buffer[3];
    accel_data[2] = (buffer[4] << 8) | buffer[5];

    gyro_data[0] = (buffer[8] << 8) | buffer[9];
    gyro_data[1] = (buffer[10] << 8) | buffer[11];
    gyro_data[2] = (buffer[12] << 8) | buffer[13];
}

void MPU6050_Init(void) {
    MPU6050_Write(0x6B, 0x00);
}


void SendHandler(void *CallBackRef, unsigned int EventData){

	return;
}
void RecvHandler(void *CallBackRef, unsigned int EventData){
	u8 rxData;
	XUartLite_Recv(&uart_intance, &rxData, 1);
	xil_printf("recv %c\n\r", rxData);
	return;
}


void timer_intr_handler(void *CallBackRef)
{
	static float integral_roll, integral_pitch;

	/********* JH code  **********/

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

   //printf("Accel X: %d  Y: %d  Z: %d\n\r"  , accel_data[0]>>7, accel_data[1]>>7, accel_data[2]>>7);
   //printf("Gyro  X: %d  Y: %d  Z: %d\n"  , gyro_data[0]>>7,  gyro_data[1]>>7,  gyro_data[2]>>7);

   float error_roll, error_pitch;
   error_roll = PI_Control(0, roll_filtered, &integral_roll, 0.5, 0.1, SAMPLING_PERIOD_S);
   error_pitch = PI_Control(0, pitch_filtered, &integral_pitch, 0.5, 0.1, SAMPLING_PERIOD_S);

   //printf("roll: %5.5f pitch: %5.5f\r\n", error_roll, error_pitch);


   /*
	* 		 0   1
	* sensor x
	* 		 2   3
	*/

   motor_power_reg[0] = (s16) ((float) motor_power_reg[0] + error_roll + error_pitch);
   motor_power_reg[1] = (s16) ((float) motor_power_reg[1] - error_roll + error_pitch);
   motor_power_reg[2] = (s16) ((float) motor_power_reg[2] + error_roll - error_pitch);
   motor_power_reg[3] = (s16) ((float) motor_power_reg[3] - error_roll - error_pitch);

   for (u8 i=0; i<4; i++)
   {
	   if (motor_power_reg[i] > 255) motor_power_reg[i] = 255;
	   else if (motor_power_reg[i] < 0) motor_power_reg[i] = 0;

   }

   printf("%03.3f %03.3f / %03.3f %03.3f / %3d %3d %3d %3d\n\r", roll_filtered, pitch_filtered, error_roll, error_pitch, motor_power_reg[0], motor_power_reg[1], motor_power_reg[2], motor_power_reg[3]);
}
