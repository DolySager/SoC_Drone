#ifndef __MOTION_SENSOR_H_
#define __MOTION_SENSOR_H_

#include "xil_types.h"
#include "math.h"
#include "xiic.h"
#include "xiic_l.h"

#define MPU6050_ADDR		    0x68

extern XIic iic_instance;

float roll_gyro, pitch_gyro;
float roll_accel, pitch_accel;
float roll_filtered, pitch_filtered;

// gyro - 98% , accel - 2%
float alpha;

s16 accel_sum[3], gyro_sum[3];
s16 accel_offset[3], gyro_offset[3];
s16 accel_data[3], gyro_data[3];

// gyro offset correction
s16 gyro_offset_x, gyro_offset_y, gyro_offset_z;

float gyro_rate, threshold;


/*
#define Calibration_Accel_X  2
#define Calibration_Accel_Y  1
#define Calibration_Accel_Z  166

#define Calibration_Gyro_X  0
#define Calibration_Gyro_Y  0
#define Calibration_Gyro_Z  2
*/



/***************************** MPU 6050 function ********************************/
void MPU6050_Write(u8 reg, u8 data);
void MPU6050_Read(u8 reg, u8 *buffer, u16 len);
void MPU6050_ReadAccelGyro(s16 *accel_data, s16 *gyro_data);
void MPU6050_Init(void);

float calculateAccelRoll(s16 accel_x, s16 accel_y, s16 accel_z);		// Roll degree
float calculateAccelPitch(s16 accel_x, s16 accel_y, s16 accel_z);		// Pitch degree
void calculate_Offset(s16 accel_data[3], s16 gyro_data[3], int samples);	// Offset(Average)
float complementaryFilter(float angle_accel, float angle_gyro, float alpha, float gyro_rate, float threshold);	// Filter


#endif
