#!/bin/bash

export LD_LIBRARY_PATH=/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib:${LD_LIBRARY_PATH}:/media/rgy/win-file/document/computer/HPC/cesm/openmpi/lib/
#add the netcdf lib here!

#if rebuild
rm -rf POP2
rm -rf ../POP2
./scripts/create_newcase -case POP2 -res T62_g16 -compset C -mach single-pc || exit 1
cd POP2
echo 'you can get the input from my sftp, you need to create the dir before the following line!'
./xmlchange -file env_run.xml -id DIN_LOC_ROOT -val /media/rgy/win-file/document/computer/HPC/cesm/inputdata/POP2
./cesm_setup 
echo 'http://www.cesm.ucar.edu/models/cesm1.2/pop2/validation/docs/20130109_port_validation'
