/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xiic.h"
#include "math.h"

#define BLDC_MOTOR_BASEADDR 	XPAR_MYIP_DRONE_BLDC_MOTO_0_S00_AXI_BASEADDR

#define IIC_ID 					XPAR_IIC_0_DEVICE_ID
#define IIC_BASEADDR			XPAR_IIC_0_BASEADDR

#define MPU6050_ADDR		    0x68

////////////////////////////////////////////////////////////////////////////////////

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

//////////////////////////////////////////////////////////////////////////////////

#define Calibration_Accel_X  2
#define Calibration_Accel_Y  1
#define Calibration_Accel_Z  166

#define Calibration_Gyro_X  0
#define Calibration_Gyro_Y  0
#define Calibration_Gyro_Z  2

float roll_gyro = 0;
float pitch_gyro = 0;
float roll_accel = 0;
float pitch_accel = 0;
float roll_filtered = 0;
float pitch_filtered = 0;

// gyro - 96% , accel - 4%
float alpha = 0.96;
float dt = 0.01;
int16_t accel_data[3], gyro_data[3];

// gyro offset correction
int16_t gyro_offset_x = 0;
int16_t gyro_offset_y = 0;
int16_t gyro_offset_z = 0;

//////////////////////////////////////////////////////////////////////////////////////////


static u8 I2C_LCD_Data;

XIic iic_instance;

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

float calculateAccelAngleX(int16_t accel_y, int16_t accel_z);
float calculateAccelAngleY(int16_t accel_x, int16_t accel_y, int16_t accel_z);
float complementaryFilter(float angle_accel, float angle_gyro, float alpha);

void calibrateGyro(int16_t *gyro_offset_x, int16_t *gyro_offset_y, int16_t *gyro_offset_z);


int main() {
    init_platform();

    print("Start!\n\r");

    XIic_Initialize(&iic_instance, IIC_ID);

    MPU6050_Init();

    LCD_Init();
    LCD_WriteString("A: ");
    LCD_GotoXY(1, 0);
    LCD_WriteString("G: ");


    volatile unsigned int* motor_power = (volatile unsigned int*) BLDC_MOTOR_BASEADDR;



    while(1) {

    	for (int i=0; i<65536; i++)
    	{
    		motor_power[0] = i;
    		usleep(10);
    	}



        /////////////////////////////////////- LCD_DATA -////////////////////////////////////////////////////

    	// read accel, gyro data
        MPU6050_ReadAccelGyro(accel_data, gyro_data);

        // top bit shift (16 bit -> 8 bit)
        u8 accel_minus[3] = {0};
        u8 gyro_minus[3] = {0};


 		accel_data[0] = accel_data[0] >> 8;
        accel_data[1] = accel_data[1] >> 8;
        accel_data[2] = accel_data[2] >> 8;

        gyro_data[0] = gyro_data[0] >> 8;
        gyro_data[1] = gyro_data[1] >> 8;
        gyro_data[2] = gyro_data[2] >> 8;


        //xil_printf("Accel X: %d, Y: %d, Z: %d\n", accel_data[0], accel_data[1], accel_data[2]);
        //xil_printf("Gyro X: %d, Y: %d, Z: %d\n", gyro_data[0], gyro_data[1], gyro_data[2]);


        // check data code (+-)
        for (int i=0; i<3; i++)
        {
            if (accel_data[i] < 0)
    		{
            	accel_minus[i] = 1;
            	accel_data[i] = -accel_data[i];
    		}
            else accel_minus[i] = 0;

            if (gyro_data[i] < 0)
    		{
            	gyro_minus[i] = 1;
            	gyro_data[i] = -gyro_data[i];
    		}
            else gyro_minus[i] = 0;
        }


        // lcd_data_output
        for (int i=0; i<3; i++)
        {
            LCD_GotoXY(0, (2 + 5*i));
            if (accel_minus[i]) LCD_WriteData('-');
            else LCD_WriteData(' ');
            LCD_WriteData(accel_data[i]/100%10 + '0');
            LCD_WriteData(accel_data[i]/10%10 + '0');
            LCD_WriteData(accel_data[i]/1%10 + '0');
        }

        for (int i=0; i<3; i++)
        {
            LCD_GotoXY(1, (2 + 5*i));
            if (gyro_minus[i]) LCD_WriteData('-');
            else LCD_WriteData(' ');
            LCD_WriteData(gyro_data[i]/100%10 + '0');
            LCD_WriteData(gyro_data[i]/10%10 + '0');
            LCD_WriteData(gyro_data[i]/1%10 + '0');
        }


        //////////////////////////////////////////-Filter_data-////////////////////////////////////////////////

        // accel,gyro -> roll,pitch angle_data_calculate
        float roll_accel = calculateAccelAngleX(accel_data[1], accel_data[2]);
        float pitch_accel = calculateAccelAngleY(accel_data[0], accel_data[1], accel_data[2]);

        roll_gyro += (gyro_data[0]- gyro_offset_x) / 131.0 * dt;
        pitch_gyro += (gyro_data[1]- gyro_offset_y) / 131.0 * dt;


        // roll,pitch -> filter application
        roll_filtered = complementaryFilter(roll_accel, roll_gyro, alpha);
        pitch_filtered = complementaryFilter(pitch_accel, pitch_gyro, alpha);


        // roll,pitch filter - uart_output
        printf("Roll: %.2f    Pitch: %.2f\n", roll_filtered, pitch_filtered);


        // If the gyro data is almost unchanged (back to the horizontal state)
        if (abs(gyro_data[0]) < 10 && abs(gyro_data[1]) < 10) {

            // Reflect more accel data (grab the horizontal state faster)
            roll_filtered = roll_accel;
            pitch_filtered = pitch_accel;

        } else {
            // default - filter application
            roll_filtered = complementaryFilter(roll_accel, roll_gyro, alpha);
            pitch_filtered = complementaryFilter(pitch_accel, pitch_gyro, alpha);
        }

        MB_Sleep(50);

    }

    cleanup_platform();
    return 0;
}



/*****************************Roll****************************************/
float calculateAccelAngleX(int16_t accel_y, int16_t accel_z)
{
    return atan2f(accel_y, accel_z) * 180 / M_PI;
}


/*****************************Pitch***************************************/
float calculateAccelAngleY(int16_t accel_x, int16_t accel_y, int16_t accel_z)
{
    return atan2f(-accel_x, sqrtf(accel_y * accel_y + accel_z * accel_z)) * 180 / M_PI;
}


/******************************Filter*************************************/
float complementaryFilter(float angle_accel, float angle_gyro, float alpha)
{
    return alpha * (angle_gyro) + (1.0 - alpha) * angle_accel;
}


/****************************************************************************************/
void calibrateGyro(int16_t *gyro_offset_x, int16_t *gyro_offset_y, int16_t *gyro_offset_z)
{
    int num_samples = 500;  // 샘플링할 횟수
    int32_t sum_x = 0, sum_y = 0, sum_z = 0;

    for (int i = 0; i < num_samples; i++) {
        MPU6050_ReadGyro(gyro_data);  // 자이로 데이터 읽기
        sum_x += gyro_data[0];
        sum_y += gyro_data[1];
        sum_z += gyro_data[2];
        delay(10);  // 센서 샘플링 시간 간격
    }

    *gyro_offset_x = sum_x / num_samples;
    *gyro_offset_y = sum_y / num_samples;
    *gyro_offset_z = sum_z / num_samples;
}



///////////////////////////////////////////////////////


// MPU-6050 레지스터 쓰기
void MPU6050_Write(u8 reg, u8 data) {
    u8 buffer[2] = {reg, data};
    XIic_Send(iic_instance.BaseAddress, MPU6050_ADDR, buffer, 2, XIIC_STOP);
}


// MPU-6050 레지스터 읽기
void MPU6050_Read(u8 reg, u8 *buffer, u16 len) {
	XIic_Send(iic_instance.BaseAddress, MPU6050_ADDR, &reg, 1, XIIC_STOP);
    XIic_Recv(iic_instance.BaseAddress, MPU6050_ADDR, buffer, 14, XIIC_STOP);
}



// MPU-6050 가속도 및 자이로 데이터 읽기
void MPU6050_ReadAccelGyro(int16_t *accel_data, int16_t *gyro_data) {
    u8 buffer[14];

    // 0x3B부터 14바이트 읽기 (가속도 + 자이로 데이터)
    MPU6050_Read(0x3B, buffer, 14);

    // 가속도 데이터 (X, Y, Z)
    accel_data[0] = (buffer[0] << 8) | buffer[1];   // X축 가속도
    accel_data[1] = (buffer[2] << 8) | buffer[3];   // Y축 가속도
    accel_data[2] = (buffer[4] << 8) | buffer[5];   // Z축 가속도

    // 자이로 데이터 (X, Y, Z)
    gyro_data[0] = (buffer[8] << 8) | buffer[9];    // X축 자이로
    gyro_data[1] = (buffer[10] << 8) | buffer[11];  // Y축 자이로
    gyro_data[2] = (buffer[12] << 8) | buffer[13];  // Z축 자이로
}



// MPU-6050 초기화 함수
void MPU6050_Init(void) {
    // 전원 관리 레지스터 설정 (디바이스 깨우기)
    MPU6050_Write(0x6B, 0x00);
}



/////////////////////////////////////////////////


void LCD_Data_4bit (u8 data)
{
	I2C_LCD_Data = (I2C_LCD_Data & 0x0f) | (data & 0xf0);		// put upper four bits
	LCD_EnablePin();
	I2C_LCD_Data = (I2C_LCD_Data & 0x0f) | ((data & 0x0f)<<4);	// put lower four bits
	LCD_EnablePin();

}

void LCD_EnablePin()
{
	I2C_LCD_Data &= ~(1<<LCD_E);
	XIic_Send(iic_instance.BaseAddress, 0x27, &I2C_LCD_Data, 1, XIIC_STOP);
	I2C_LCD_Data |= (1<<LCD_E);
	XIic_Send(iic_instance.BaseAddress, 0x27, &I2C_LCD_Data, 1, XIIC_STOP);
	I2C_LCD_Data &= ~(1<<LCD_E);
	XIic_Send(iic_instance.BaseAddress, 0x27, &I2C_LCD_Data, 1, XIIC_STOP);
	MB_Sleep(2);
}

void LCD_WriteCommand(uint8_t commandData)
{
	I2C_LCD_Data &= ~(1<<LCD_RS);					// enter instruction code mode
	I2C_LCD_Data &= ~(1<<LCD_RW);					// enter write mode
	LCD_Data_4bit(commandData);						// output data
}
void LCD_WriteData(uint8_t charData)
{
	I2C_LCD_Data |= (1<<LCD_RS);						// enter data mode
	I2C_LCD_Data &= ~(1<<LCD_RW);						// enter write mode
	LCD_Data_4bit(charData);						// output data
}
void LCD_Init()
{
	// see HD44780 datasheet page 45 for following init commands
	MB_Sleep(20);
	LCD_WriteCommand(0x03);
	MB_Sleep(5);
	LCD_WriteCommand(0x03);
	MB_Sleep(1);
	LCD_WriteCommand(0x03);

	LCD_WriteCommand(0x02);
	LCD_WriteCommand(COMMAND_4BIT_MODE);
	LCD_WriteCommand(COMMAND_DISPLAY_OFF);
	LCD_WriteCommand(COMMAND_DISPLAY_CLEAR);
	LCD_WriteCommand(COMMAND_ENTRY_MODE);
	LCD_WriteCommand(COMMAND_DISPLAY_ON);
	LCD_BackLightOn();
}
void LCD_BackLightOn()
{
	I2C_LCD_Data |= (1<<LCD_BACKLIGHT);

}

void LCD_GotoXY(uint8_t row, uint8_t col)
{
	col %= 16;										// column width is within 16
	row %= 2;										// row length is within 2
	uint8_t address = (0x40 * row) + col;			// see HD44780 datasheet page 12
	uint8_t command = 0x80 + address;
	LCD_WriteCommand(command);
}

void LCD_WriteString(char *string)
{
	for (uint8_t i = 0; string[i]; i++)
	{
		LCD_WriteData(string[i]);
	}
}

