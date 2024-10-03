#include "pid_control.h"

/*
float Kp_roll = 1.5;
float Ki_roll = 0.01;
float Kd_roll = 0.01;

float Kp_pitch = 1.5;
float Ki_pitch = 0.01;
float Kd_pitch = 0.01;
*/

float target_roll = 0.0;
float target_pitch = 0.0;

float roll_integral = 0.0;
float pitch_integral = 0.0;

float PID_Control(float target_angle, float current_angle, float* integral, float Kp, float Ki, float Kd, float dt)
{
	static float prev_angle;

    float error = target_angle - current_angle;
    float angle_diff = current_angle - prev_angle;
    prev_angle = current_angle;

    *integral += error * dt;

    float output = (Kp * error) + (Ki * (*integral)) - (Kd * angle_diff / dt);

    return output;
}
