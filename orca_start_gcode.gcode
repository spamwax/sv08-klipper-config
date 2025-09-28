;ESTIMATOR_ADD_TIME 480 Heating Up and Priming
SET_PRINT_STATS_INFO TOTAL_LAYER={total_layer_count}
G92 E0      ; Set extruder position to 0
M106 S0     ; Turn-off part cooling fan
M220 S100   ; Reset Feedrate
M221 S100   ; Reset Flowrate

G90
CLEAR_PAUSE
BED_MESH_CLEAR

SOAK_WAIT STOP=1
G4 P2000

{if chamber_temperature[0] > 0 }
; It will only start chamber heater if chamber temp is set in the filament settings.
CHAMBER_HEAT_START TARGET={chamber_temperature[0]} DELTA=1
{endif}

; Adding the following line just to ensure SS knows the idle and starting temperatures
M104 S140

SET_HEATER_TEMPERATURE HEATER=extruder TARGET=140
SET_HEATER_TEMPERATURE HEATER=heater_bed TARGET={bed_temperature_initial_layer_single}
TEMPERATURE_WAIT SENSOR=heater_bed MINIMUM={bed_temperature_initial_layer_single-6}
TEMPERATURE_WAIT SENSOR=extruder MINIMUM=139

; First Home the X-Y axes
G28
M400 ; Wait for moves to finish
; STABLE_Z_HOME  ; instead of G28 Z

SET_GCODE_OFFSET Z=0 MOVE=1
; ROUGH_CLEAN

; Move around to release frame stress before QGL
;JERK_OFF

; QUAD GANTRY LEVEL
TEMPERATURE_WAIT SENSOR=heater_bed MINIMUM={bed_temperature_initial_layer_single-1}
M117 QGL
QUAD_GANTRY_LEVEL
M117 Homing Z after QGL
; G28 Z

; BED_MESH_PROFILE LOAD=default_65C
; CLEAN_NOZZLE
; BED_MESH_CLEAR
STABLE_Z_HOME

; ____________________________________________________________________________________
EUCLID_PROBE_BEGIN_BATCH

CALIBRATE_Z BED_POSITION={(adaptive_bed_mesh_min[0]+adaptive_bed_mesh_max[0])/2},{(adaptive_bed_mesh_min[1]+adaptive_bed_mesh_max[1])/2}

TEMPERATURE_WAIT SENSOR=heater_bed MINIMUM={ bed_temperature_initial_layer_single - 1.0 } MAXIMUM={ bed_temperature_initial_layer_single + 3 }

; Further increase extruder temperature while we are doing bed mesh.
{if filament_type[0] == "ABS" or filament_type[0] == "PLA" }
SET_HEATER_TEMPERATURE HEATER=extruder TARGET={nozzle_temperature_initial_layer[0] - 70}
{endif}

; =============== Bed Mesh Stuff =====================
; Always pass ‘ADAPTIVE_MARGIN=0’ because Orca has already handled ‘adaptive_bed_mesh_margin’ internally
M117 Creating Bed Mesh
BED_MESH_CALIBRATE mesh_min={first_layer_print_min[0]},{first_layer_print_min[1]} mesh_max={first_layer_print_max[0]},{first_layer_print_max[1]} ADAPTIVE_MARGIN=0 ALGORITHM=bicubic ADAPTIVE=1 PROFILE="live-adaptive"
BED_MESH_PROFILE   SAVE="live-adaptive"
BED_MESH_PROFILE   LOAD="live-adaptive"
; =====================================================

EUCLID_PROBE_END_BATCH
; ____________________________________________________________________________________
ASSERT_PROBE_STOWED


{if nozzle_diameter[0] == 0.4}
{if curr_bed_type=="Textured PEI Plate"}
SET_GCODE_OFFSET Z_ADJUST=-0.0005 MOVE=1
REPORT_Z_OFFSET
{else}
SET_GCODE_OFFSET Z_ADJUST=-0.01 MOVE=1
REPORT_Z_OFFSET
{endif}
; ===================================================================================
{elif nozzle_diameter[0] == 0.5}
{if curr_bed_type=="Textured PEI Plate"}
SET_GCODE_OFFSET Z_ADJUST=0.01 MOVE=1
REPORT_Z_OFFSET
{else}
SET_GCODE_OFFSET Z_ADJUST=-0.022 MOVE=1
REPORT_Z_OFFSET
{endif}
; ===================================================================================
{elif nozzle_diameter[0] == 0.6}
{if curr_bed_type=="Textured PEI Plate"}
SET_GCODE_OFFSET Z_ADJUST=0.01 MOVE=1
REPORT_Z_OFFSET
{else}
SET_GCODE_OFFSET Z_ADJUST=-0.022 MOVE=1
REPORT_Z_OFFSET
{endif}
; ===================================================================================
{endif}

START_PRINT EXTRUDER_TEMP=[nozzle_temperature_initial_layer] BED_TEMP={bed_temperature_initial_layer_single} SOAK_MINUTE=0 HEATSOAK=1

; ================================ DEFAULT MESH ================================
; ==============================================================================
BED_MESH_PROFILE LOAD=default_65C ; Wham smooth

G90 ; set to absolute positioning
G1 Y20
G1 X0 Y0 F9000
G1 Z0.250 F600

M400 ; Wait for moves to finish
G91 ; set to relative positioning
M83 ; put extrusion axis into relative mode
SET_HEATER_TEMPERATURE HEATER=heater_bed TARGET={bed_temperature_initial_layer_single}
SET_HEATER_TEMPERATURE HEATER=extruder TARGET={nozzle_temperature_initial_layer[0]}

M104 S[nozzle_temperature_initial_layer]
M140 S{bed_temperature_initial_layer_single}

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
;G1 X87.000 E13.9

; Lift up and get ready to run the actual gcode from slicer
G1 E-0.200 Z1 F600

_CLIENT_LINEAR_MOVE Z={first_layer_height+ 0.6} F=1000 ABSOLUTE=1 ; Move Z up to avoid nozzle hitting the bed
G4 P50
; GO TO FIRST PRINT POINT
_CLIENT_LINEAR_MOVE X={first_layer_print_min[0]} Y={first_layer_print_min[1]} F=15000 ABSOLUTE=1
G1 E0.100 F600

; ==================================================================================
; ================================ END DEFAULT MESH ================================

G90
;START_PRINT macro will load default bed mesh profile, so we need to load the live-adaptive profile again
BED_MESH_PROFILE LOAD="live-adaptive"
M400 ; Wait for moves to finish

