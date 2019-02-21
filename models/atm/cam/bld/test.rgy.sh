#!/bin/bash
ipcrm -a
ulimit -s unlimited
#echo 'you need to download tar cam53_f19c4aqpgro_ys.tar.gz and cam.zip from sftp first'
#echo "you need to build cprnc in tools/cprnc first"
#./build-cprnc.sh || exit 2

#if you are RGY

export INC_MPI=/media/rgy/win-file/document/computer/HPC/cesm/openmpi/include
export LIB_MPI=/media/rgy/win-file/document/computer/HPC/cesm/openmpi/lib
export LIB_NETCDF=/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib
export INC_NETCDF=/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/include
export LDFLAGS='-L/media/rgy/win-file/document/computer/HPC/cesm/openmpi/lib -L/opt/cuda/lib64/ -lcuda -lcudart -lstdc++'
export LD_LIBRARY_PATH=/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib:${LD_LIBRARY_PATH}:/media/rgy/win-file/document/computer/HPC/cesm/openmpi/lib/:$INTEL/mkl/lib/intel64/ 

INTEL='/media/rgy/linux-file/intel_parallel_studio/'

#rm -f ./*.o
./cuda-build.sh || exit 1

 ./configure -dyn fv -hgrid 1.9x2.5 -ntasks 1 -phys cam4 -ocn aquaplanet -pergro -fc gfortran  -fopt '-lmkl:sequential  -g -O3' #-debug
 ./build-namelist -s -case cam5.0_port -runtype startup  -csmdata ./ -namelist "&camexp stop_option='ndays', stop_n=2 nhtfrq=1 ndens=1 \
    mfilt=97 hfilename_spec='h%t.nc' empty_htapes=.true.    fincl1='T:I','PS:I' /"
 rm -f Depends

export FC=ifort
gmake -j 2 > gmake.log 2>&1
tail ./gmake.log

echo "now link the cam"
rm -f ./cam 
mpifort -o /media/rgy/win-file/document/computer/HPC/cesm/CESM/models/atm/cam/bld/cam \
./*.o  -lstdc++ \
-L/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib -lnetcdff \
-L/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib -lnetcdf -lnetcdf -Wl,-rpath=/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib  \
-L/media/rgy/win-file/document/computer/HPC/cesm/CESM/models/atm/cam/bld/mct/mct -lmct \
-L/media/rgy/win-file/document/computer/HPC/cesm/CESM/models/atm/cam/bld/mct/mpeu -lmpeu  -L/media/rgy/win-file/document/computer/HPC/cesm/openmpi/lib -lmpi \
-lmkl_intel_ilp64 -lmkl_sequential -lmkl_core \
 -L/usr/local/cuda/lib64 -lcufft -lcudart|| exit 3
#-L $INTEL/mkl/lib/intel64/ -lmkl_rt

rm -f ./h0.nc 

echo "run the cam"
optirun mpirun ./cam >cam.run.log 2>&1|| exit 4

echo "cprncdf !"
rm -f ./result 
./cprncdf -X ../../../../tools/cprnc/  f19c4aqpgro_cam53_ys_intel.nc h0.nc  > result
cat ./result
