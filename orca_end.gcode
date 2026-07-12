TIMELAPSE_RENDER_1
END_PRINT


{if activate_air_filtration[0]}
AIR_FILTER S={complete_print_exhaust_fan_speed[0]/100.0} MIN=45
{endif}


{if filament_type[0]=="ABS" or filament_type[0]=="PC" or filament_type[0]=="PC-CF" or filament_type[0]=="PA-CF" or filament_type[0]=="ASA" or filament_type[0]=="PC-ASA"}

; START_GRADUAL_COOLING START={bed_temperature[0]} TARGET=55 STEP=5 INTERVAL=180 RETRY_MAX=2

; Precise (based on temperature look-up table) cooldown
CONTROLLED_BED_COOLDOWN

{else}
POWER_OFF_PRINTER MAX_TEMP=60 ; wait for hotend to cooldown to 50 before powering off
{endif}

