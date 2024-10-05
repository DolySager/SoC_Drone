#include "myip_bldc_driver.h"

void myip_bldcDriver_init()
{
    motor_power_reg = (volatile s32*) BLDC_MOTOR_BASEADDR;
}

void myip_bldcDriver_setPower(s32 *motor_power_value_arr)
{
    for (u32 i=0; i<NUM_BLDC_MOTOR; ++i)
    {
        motor_power_reg[i] = motor_power_value_arr[i];
    }
}