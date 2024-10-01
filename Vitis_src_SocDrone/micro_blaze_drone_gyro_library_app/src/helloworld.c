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

////////////////////////////////////////////////////////////////////

#define RAD_TO_DEG 57.295779513082320876798154814105

#define WHO_AM_I_REG 0x75
#define PWR_MGMT_1_REG 0x6B
#define SMPLRT_DIV_REG 0x19
#define ACCEL_CONFIG_REG 0x1C
#define ACCEL_XOUT_H_REG 0x3B
#define TEMP_OUT_H_REG 0x41
#define GYRO_CONFIG_REG 0x1B
#define GYRO_XOUT_H_REG 0x43



// Setup MPU6050
#define MPU6050_ADDR 0x68
const u16 i2c_timeout = 100;
const double Accel_Z_corrector = 14418.0;

u32 timer;




typedef struct
{

    int16_t Accel_X_RAW;
    int16_t Accel_Y_RAW;
    int16_t Accel_Z_RAW;
    double Ax;
    double Ay;
    double Az;

    int16_t Gyro_X_RAW;
    int16_t Gyro_Y_RAW;
    int16_t Gyro_Z_RAW;
    double Gx;
    double Gy;
    double Gz;

    float Temperature;

    double KalmanAngleX;
    double KalmanAngleY;
} MPU6050_t;


MPU6050_t MPU6050;


typedef struct
{
    double Q_angle;
    double Q_bias;
    double R_measure;
    double angle;
    double bias;
    double P[2][2];
} Kalman_t;


Kalman_t KalmanX = { .Q_angle = 0.001f, .Q_bias = 0.003f, .R_measure = 0.03f };
Kalman_t KalmanY = { .Q_angle = 0.001f, .Q_bias = 0.003f, .R_measure = 0.03f };


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

////////////////////////////////////////////////////////////////////

XIic iic_instance;

static u8 I2C_LCD_Data;

void LCD_Data_4bit (u8 data);
void LCD_EnablePin();
void LCD_WriteCommand(uint8_t commandData);
void LCD_WriteData(uint8_t charData);
void LCD_Init();
void LCD_BackLightOn();
void LCD_GotoXY(uint8_t row, uint8_t col);
void LCD_WriteString(char *string);

////////////////////////////////////////////////////////////////////

void MPU6050_Init(void);
void MPU6050_Read(u8 reg, u8 *buffer, u16 len);
void MPU6050_Write(u8 reg, u8 data);

void MPU6050_Read_Accel();
void MPU6050_Read_Gyro();
void MPU6050_Read_Temp();
void MPU6050_Read_All();

double Kalman_getAngle(Kalman_t *Kalman, double newAngle, double newRate, double dt);


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

    	printf(" data : %d \n\r" ,MPU6050);

    	MPU6050_Read_All();



        MB_Sleep(50);

    }

    cleanup_platform();
    return 0;
}


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


void MPU6050_Init(void)
{
    // 전원 관리 레지스터 설정 (디바이스 깨우기)
    MPU6050_Write(0x6B, 0x00);
}




void MPU6050_Read_Accel()
{
    u8 Rec_Data[6];

    // ACCEL_XOUT_H 레지스터부터 6바이트 읽기
    MPU6050_Read(0x3B, Rec_Data, 6);

 // I2C_ReadRegister(&iic_instance.BaseAddress, MPU6050_ADDR, ACCEL_XOUT_H_REG, Rec_Data, 6);

    MPU6050.Accel_X_RAW = (int16_t)(Rec_Data[0] << 8 | Rec_Data[1]);
    MPU6050.Accel_Y_RAW = (int16_t)(Rec_Data[2] << 8 | Rec_Data[3]);
    MPU6050.Accel_Z_RAW = (int16_t)(Rec_Data[4] << 8 | Rec_Data[5]);

    MPU6050.Ax = MPU6050.Accel_X_RAW / 16384.0;
    MPU6050.Ay = MPU6050.Accel_Y_RAW / 16384.0;
    MPU6050.Az = MPU6050.Accel_Z_RAW / Accel_Z_corrector;
}

void MPU6050_Read_Gyro()
{
    u8 Rec_Data[6];

    MPU6050_Read(0x43, Rec_Data, 6);
    // GYRO_XOUT_H 레지스터부터 6바이트 읽기
    //I2C_ReadRegister(&iic_instance.BaseAddress, MPU6050_ADDR, GYRO_XOUT_H_REG, Rec_Data, 6);

    MPU6050.Gyro_X_RAW = (int16_t)(Rec_Data[0] << 8 | Rec_Data[1]);
    MPU6050.Gyro_Y_RAW = (int16_t)(Rec_Data[2] << 8 | Rec_Data[3]);
    MPU6050.Gyro_Z_RAW = (int16_t)(Rec_Data[4] << 8 | Rec_Data[5]);

    MPU6050.Gx = MPU6050.Gyro_X_RAW / 131.0;
    MPU6050.Gy = MPU6050.Gyro_Y_RAW / 131.0;
    MPU6050.Gz = MPU6050.Gyro_Z_RAW / 131.0;
}



void MPU6050_Read_Temp()
{
    uint8_t Rec_Data[2];
    int16_t temp;

    MPU6050_Read(0x41, Rec_Data, 2);
    // TEMP_OUT_H_REG 레지스터부터 2바이트 읽기
    //I2C_ReadRegister(&iic_instance.BaseAddress, MPU6050_ADDR, TEMP_OUT_H_REG, Rec_Data, 2);

    // 16비트 온도 데이터 결합
    temp = (int16_t)(Rec_Data[0] << 8 | Rec_Data[1]);

    // 온도를 계산하고 MPU6050에 저장 (화씨 변환 없이 섭씨로 계산)
    MPU6050.Temperature = (float)((int16_t)temp / 340.0 + 36.53);
}



void MPU6050_Read_All()
{
    u8 Rec_Data[14];
    int16_t temp;

    MPU6050_Read(0x3B, Rec_Data, 14);
    // ACCEL_XOUT_H 레지스터부터 14바이트 읽기
    //I2C_ReadRegister(&iic_instance.BaseAddress, MPU6050_ADDR, ACCEL_XOUT_H_REG, Rec_Data, 14);

    MPU6050.Accel_X_RAW = (int16_t)(Rec_Data[0] << 8 | Rec_Data[1]);
    MPU6050.Accel_Y_RAW = (int16_t)(Rec_Data[2] << 8 | Rec_Data[3]);
    MPU6050.Accel_Z_RAW = (int16_t)(Rec_Data[4] << 8 | Rec_Data[5]);
    temp = (int16_t)(Rec_Data[6] << 8 | Rec_Data[7]);
    MPU6050.Gyro_X_RAW = (int16_t)(Rec_Data[8] << 8 | Rec_Data[9]);
    MPU6050.Gyro_Y_RAW = (int16_t)(Rec_Data[10] << 8 | Rec_Data[11]);
    MPU6050.Gyro_Z_RAW = (int16_t)(Rec_Data[12] << 8 | Rec_Data[13]);

    MPU6050.Ax = MPU6050.Accel_X_RAW / 16384.0;
    MPU6050.Ay = MPU6050.Accel_Y_RAW / 16384.0;
    MPU6050.Az = MPU6050.Accel_Z_RAW / Accel_Z_corrector;
    MPU6050.Temperature = (float)((int16_t)temp / 340.0 + 36.53);
    MPU6050.Gx = MPU6050.Gyro_X_RAW / 131.0;
    MPU6050.Gy = MPU6050.Gyro_Y_RAW / 131.0;
    MPU6050.Gz = MPU6050.Gyro_Z_RAW / 131.0;

/*    // 타이머 관련 수정 (XTime 사용)
    XTime current_time;
    XTime_GetTime(&current_time);
    double dt = (double)(current_time - timer) / (COUNTS_PER_SECOND);  // dt 계산
    timer = current_time;*/
    // Kalman angle solve

        double dt = (double)(HAL_GetTick() - timer) / 1000;
        timer = HAL_GetTick();



        double roll;
        double roll_sqrt = sqrt(MPU6050.Accel_X_RAW * MPU6050.Accel_X_RAW + MPU6050.Accel_Z_RAW * MPU6050.Accel_Z_RAW);
        if (roll_sqrt != 0.0)
        {
            roll = atan(MPU6050.Accel_Y_RAW / roll_sqrt) * RAD_TO_DEG;
        }
        else
        {
            roll = 0.0;
        }
        double pitch = atan2(-MPU6050.Accel_X_RAW, MPU6050.Accel_Z_RAW) * RAD_TO_DEG;
        if ((pitch < -90 && MPU6050.KalmanAngleY > 90) || (pitch > 90 && MPU6050.KalmanAngleY < -90))
        {
            KalmanY.angle = pitch;
            MPU6050.KalmanAngleY = pitch;
        }
        else
        {
        	MPU6050.KalmanAngleY = Kalman_getAngle(&KalmanY, pitch, MPU6050.Gy, dt);
        }
        if (fabs(MPU6050.KalmanAngleY) > 90)
        	MPU6050.Gx = -MPU6050.Gx;
        MPU6050.KalmanAngleX = Kalman_getAngle(&KalmanX, roll, MPU6050.Gx, dt);
    }




double Kalman_getAngle(Kalman_t *Kalman, double newAngle, double newRate, double dt)
{
    double rate = newRate - Kalman->bias;
    Kalman->angle += dt * rate;

    Kalman->P[0][0] += dt * (dt * Kalman->P[1][1] - Kalman->P[0][1] - Kalman->P[1][0] + Kalman->Q_angle);
    Kalman->P[0][1] -= dt * Kalman->P[1][1];
    Kalman->P[1][0] -= dt * Kalman->P[1][1];
    Kalman->P[1][1] += Kalman->Q_bias * dt;

    double S = Kalman->P[0][0] + Kalman->R_measure;
    double K[2];
    K[0] = Kalman->P[0][0] / S;
    K[1] = Kalman->P[1][0] / S;

    double y = newAngle - Kalman->angle;
    Kalman->angle += K[0] * y;
    Kalman->bias += K[1] * y;

    double P00_temp = Kalman->P[0][0];
    double P01_temp = Kalman->P[0][1];

    Kalman->P[0][0] -= K[0] * P00_temp;
    Kalman->P[0][1] -= K[0] * P01_temp;
    Kalman->P[1][0] -= K[1] * P00_temp;
    Kalman->P[1][1] -= K[1] * P01_temp;

    return Kalman->angle;
};


///////////////////////////////////////////////


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


