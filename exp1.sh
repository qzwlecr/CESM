#!/bin/bash

create_newcase -case EXP1 -res 0.47x0.63_gx1v6 -compset E1850CN -mach cluster || exit 1
cd EXP1
./xmlchange -file env_run.xml -id DIN_LOC_ROOT -val /home/gpu_ubuntu/zhanglichen/asc2019/cesm/inputdata/inputdata_EXP1
./xmlchange -file env_run.xml -id DOCN_SOM_FILENAME -val pop_frc.gx1v6.091112.nc
./xmlchange -file env_run.xml -id STOP_N -val 5
./xmlchange -file env_run.xml -id STOP_OPTION -val ndays
./cesm_setup || exit 2
./EXP1.build || exit 3
./EXP1.run || exit 4
