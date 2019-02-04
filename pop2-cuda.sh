#!/bin/bash

export LD_LIBRARY_PATH=/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib:${LD_LIBRARY_PATH}:/media/rgy/win-file/document/computer/HPC/cesm/openmpi/lib/
#add the netcdf lib here!

#if rebuild
rm -rf POP2
rm -rf ../POP2
./scripts/create_newcase -case POP2 -res T62_g16 -compset C -mach single-pc || exit 1
cd POP2

./cesm_setup || exit 2
echo 'http://www.cesm.ucar.edu/models/cesm1.2/pop2/validation/docs/20130109_port_validation'
./POP2.build || exit 3
cd ..


exit 0
echo "run!!!"
cd POP2
./POP2.run || exit 4
