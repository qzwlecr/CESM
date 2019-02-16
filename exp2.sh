#!/bin/bash

create_newcase -case EXP2 -res 0.47x0.63_gx1v6 -compset B -mach cluster || exit 1
cd EXP2
./xmlchange -file env_run.xml -id DIN_LOC_ROOT -val /home/gpu_ubuntu/zhanglichen/asc2019/cesm/inputdata/inputdata_EXP2
./xmlchange -file env_run.xml -id STOP_N -val 5
./xmlchange -file env_run.xml -id STOP_OPTION -val ndays
./cesm_setup || exit 2
./EXP2.build || exit 3
./EXP2.run || exit 4
