;ESTIMATOR_ADD_TIME 480 Heating Up and Priming
SET_PRINT_STATS_INFO TOTAL_LAYER={total_layer_count}

SET_HEATER_TEMPERATURE HEATER=extruder TARGET=140
SET_HEATER_TEMPERATURE HEATER=heater_bed TARGET={bed_temperature_initial_layer_single}

TEMPERATURE_WAIT SENSOR=heater_bed MINIMUM={bed_temperature_initial_layer_single-6}
TEMPERATURE_WAIT SENSOR=extruder MINIMUM=140

SET_GCODE_OFFSET Z=0 MOVE=1

; First Home the X-Y axes
G28 X Y
M400 ; Wait for moves to finish
STABLE_Z_HOME  ; instead of G28 Z

; Move around to release frame stress before QGL
JERK_OFF
;G1 Z100 F1200
;G1 X1 Y362 F18000
;G1 X349 F18000
;G1 Y1
;G1 X1
;G1 Y362
;G1 F12000
;G1 X177 Y177 Z40

; QUAD GANTRY LEVEL
M117 QGL
BEEPC COUNT=3
G4 P1000
DEPLOY_PROBE
QUAD_GANTRY_LEVEL_BASE
STOW_PROBE
G4 P250
M117 Home Z after QGL
STABLE_Z_HOME
M400

EUCLID_PROBE_BEGIN_BATCH

CALIBRATE_Z ; BED_POSITION={(adaptive_bed_mesh_min[0]+adaptive_bed_mesh_max[0])/2},{(adaptive_bed_mesh_min[1]+adaptive_bed_mesh_max[1])/2}
SET_HEATER_TEMPERATURE HEATER=heater_bed TARGET={bed_temperature_initial_layer_single}
TEMPERATURE_WAIT SENSOR=heater_bed MINIMUM={ bed_temperature_initial_layer_single - 1.0 } MAXIMUM={ bed_temperature_initial_layer_single + 3 }
M400 ; Finish moves

; Further increase extruder temperature while we are doing bed mesh.
{if filament_type[0] == "ABS" or filament_type[0] == "PLA" }
SET_HEATER_TEMPERATURE HEATER=extruder TARGET={nozzle_temperature_initial_layer[0] - 70}
{endif}
; ============================== Bed Mesh Stuff ====================================
;BED_MESH_CLEAR
; Always pass `ADAPTIVE_MARGIN=0` because Orca has already handled `adaptive_bed_mesh_margin` internally
M117 Bed Mesh
BED_MESH_CALIBRATE mesh_min={adaptive_bed_mesh_min[0]},{adaptive_bed_mesh_min[1]} mesh_max={adaptive_bed_mesh_max[0]},{adaptive_bed_mesh_max[1]} ADAPTIVE_MARGIN=0 ALGORITHM=[bed_mesh_algo] ADAPTIVE=1 PROFILE="live-adaptive"
BED_MESH_PROFILE   SAVE="live-adaptive"
BED_MESH_PROFILE   LOAD="live-adaptive"
; ===================================================================================
EUCLID_PROBE_END_BATCH
ASSERT_PROBE_STOWED

{if curr_bed_type=="Textured PEI Plate"}
START_PRINT EXTRUDER_TEMP=[nozzle_temperature_initial_layer] BED_TEMP=[bed_temperature_initial_layer_single] Z_ADJUST=0.0 SOAK_MINUTE=0 HEATSOAK=1
{else}
START_PRINT EXTRUDER_TEMP=[nozzle_temperature_initial_layer] BED_TEMP={bed_temperature_initial_layer_single} Z_ADJUST=0.0 SOAK_MINUTE=0 HEATSOAK=1
{endif}

G90 ; set to absolute positioning
; G1 X177 Y177 F9000
G1 Y20
G1 X0 Y0 F9000
G1 Z0.85 F600

M400 ; Wait for moves to finish
G91 ; set to relative positioning
M83 ; put extrusion axis into relative mode
M140 S[bed_temperature_initial_layer_single] ;set bed temp
M104 S[nozzle_temperature_initial_layer] ;set extruder temp
;M190 S[bed_temperature_initial_layer_single] ;wait for bed temp
;M109 S[nozzle_temperature_initial_layer];wait for extruder temp

G1 E10.5 F300

G4 P1000 ; pause for 1 second
G1 E-0.200 Z5 F600
G1 X88.000 F9000
G1 Z-5.000 F600
; Prime line 1
G1 X87.000 E20.88 F1800
G1 X87.000 E13.92 F1800
G1 Y1 E0.16 F1800
; Prime line 2
;G1 X-87.000 E13.92 F1800
;G1 X-87.000 E20.88 F1800
;G1 Y1 E0.24 F1800
; Prime line 3
;G1 X87.000 E20.88 F1800
;G1 X87.000 E13.92 F1800

; Lift up and get ready to run the actual gcode from slicer
G1 E-0.200 Z1 F600
M400 ; Wait for moves to finish

