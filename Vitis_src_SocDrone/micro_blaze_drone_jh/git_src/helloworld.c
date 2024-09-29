#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xiic.h"
#include "math.h"


/************************ IIC/MPU/MOTOR - ADDR ***************************/

#define IIC_ID 					XPAR_IIC_0_DEVICE_ID
#define IIC_BASEADDR			XPAR_IIC_0_BASEADDR

static u8 I2C_LCD_Data;
XIic iic_instance;


#define MPU6050_ADDR		    0x68

#define BLDC_MOTOR_BASEADDR 	XPAR_MYIP_DRONE_BLDC_MOTO_0_S00_AXI_BASEADDR


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

/***************************** pi control *********************************/

float Kp_roll = 1.5;
float Ki_roll = 0.01;

float Kp_pitch = 1.5;
float Ki_pitch = 0.01;

float target_roll = 0.0;
float target_pitch = 0.0;

float roll_integral = 0.0;
float pitch_integral = 0.0;


/***************************** function declaration *********************************/

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

void calculat_Offset(int16_t accel_data[3], int16_t gyro_data[3], int samples);
float complementaryFilter(float angle_accel, float angle_gyro, float alpha);
float PI_Control(float target_angle, float current_angle, float* integral, float Kp, float Ki, float dt);





int main() {

    init_platform();
    print("Start!\n\r");
    XIic_Initialize(&iic_instance, IIC_ID);
    MPU6050_Init();

    LCD_Init();
    LCD_WriteString("A: ");
    LCD_GotoXY(1, 0);
    LCD_WriteString("G: ");

    calculate_Offset(accel_data, gyro_data, 500);	//when the device start, it averages 500

    volatile unsigned int* motor_power = (volatile unsigned int*) BLDC_MOTOR_BASEADDR;


    while(1) {

    	/********** JH code  ***********/

       // read accel, gyro data
       MPU6050_ReadAccelGyro(accel_data, gyro_data);


       // offset
       accel_data[0] -= accel_offset[0];
       accel_data[1] -= accel_offset[1];
       accel_data[2] -= accel_offset[2];

       gyro_data[0]	-= gyro_offset[0];
       gyro_data[1]	-= gyro_offset[1];
       gyro_data[2]	-= gyro_offset[2];




       // accel - Roll,Pitch
       roll_accel = calculateAccelRoll(accel_data[0], accel_data[1], accel_data[2]);
       pitch_accel = calculateAccelPitch(accel_data[0], accel_data[1], accel_data[2]);

       // gyro - Roll,Pitch
       roll_gyro += (gyro_data[0]) / 131.0 * dt;
       pitch_gyro += (gyro_data[1]) / 131.0 * dt;


       // Complementary Filter
       roll_filtered = complementaryFilter(roll_accel, roll_gyro, alpha);
       pitch_filtered = complementaryFilter(pitch_accel, pitch_gyro, alpha);



       printf("Accel X: %d  Y: %d  Z: %d\n\r"  , accel_data[0]>>7, accel_data[1]>>7, accel_data[2]>>7);
       printf("Gyro  X: %d  Y: %d  Z: %d\n"  , gyro_data[0]>>7,  gyro_data[1]>>7,  gyro_data[2]>>7);

       MB_Sleep(100);


/*
	       ////////////////- lcd data output -/////////////////

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
*/

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
float complementaryFilter(float angle_accel, float angle_gyro, float alpha)
{
    return alpha * (angle_gyro) + (1.0 - alpha) * angle_accel;
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



/***************************** LCD function ********************************/

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
