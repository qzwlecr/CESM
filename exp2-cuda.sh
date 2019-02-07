#!/bin/bash

export LD_LIBRARY_PATH=/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib:${LD_LIBRARY_PATH}:/media/rgy/win-file/document/computer/HPC/cesm/openmpi/lib/
#add the netcdf lib here!

#if rebuild
rm -rf EXP2
rm -rf ../EXP2
./scripts/create_newcase -case EXP2 -res 0.47x0.63_gx1v6 -compset B -mach single-pc || exit 1
cd EXP2
./xmlchange -file env_run.xml -id DIN_LOC_ROOT -val /media/rgy/win-file/document/computer/HPC/cesm/inputdata/inputdata_EXP1 #just copy it to the same dir, for they share some inputs
./xmlchange -file env_run.xml -id STOP_N -val 5
./xmlchange -file env_run.xml -id STOP_OPTION -val ndays
./cesm_setup || exit 2
./EXP2.build || exit 3
cd ..


exit 0
echo "run!!!"
cd EXP2
./EXP2.run || exit 4
