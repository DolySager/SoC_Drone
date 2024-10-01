#ifndef __PID_CONTROL_H_
#define __PID_CONTROL_H_




float PI_Control(float target_angle, float current_angle, float* integral, float Kp, float Ki, float dt);

#endif
