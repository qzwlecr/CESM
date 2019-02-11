#!/bin/bash


#if rebuild
rm -rf EXP1
rm -rf ../EXP1
./scripts/create_newcase -case EXP1 -res 0.47x0.63_gx1v6 -compset E1850CN -mach single-pc || exit 1
cd EXP1
./xmlchange -file env_run.xml -id DIN_LOC_ROOT -val /home/mike/workspace/asc19/inputdata/inputdata_EXP1
./xmlchange -file env_run.xml -id DOCN_SOM_FILENAME -val pop_frc.gx1v6.091112.nc
./xmlchange -file env_run.xml -id STOP_N -val 5
./xmlchange -file env_run.xml -id STOP_OPTION -val ndays
./cesm_setup || exit 2
./EXP1.build || exit 3
cd ..
# if the make file failed at final link step of cesm.exe, use this to link it 
#echo "move cuda.o to the obj dir!"
#cp ./models/atm/cam/bld/*_cuda.o ../EXP1/bld/cesm/obj
#cd 
#../openmpi/bin/mpifort -o ../EXP1/bld/cesm.exe ../EXP1/bld/cesm/obj/*.o  -L../EXP1/bld/lib/ -latm  -L../EXP1/bld/lib/ -lice  -L../EXP1/bld/lib/ -llnd  -L../EXP1/bld/lib/ -locn  -L../EXP1/bld/lib/ -lrof  -L../EXP1/bld/lib/ -lglc  -L../EXP1/bld/lib/ -lwav -L../EXP1/bld/gnu/openmpi/nodebug/nothreads/MCT/noesmf/a1l1r1i1o1g1w1/csm_share -lcsm_share -L../EXP1/bld/gnu/openmpi/nodebug/nothreads/lib -lpio -lgptl -lmct -lmpeu -L../netcdf-build/lib -lnetcdf -lnetcdff  -L/opt/cuda/lib64/ -lcuda -L../openmpi/lib -lmpi  -lstdc++ || echo 'cuda link failed!!' 

exit 0
echo "run!!!"
cd EXP1
./EXP1.run || exit 4
