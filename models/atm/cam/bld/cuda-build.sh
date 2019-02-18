#! /bin/bash
echo "cuda!"
#dog pc
#nvcc   -ccbin gcc-7 -c ../src/utils/fft99_cuda.cu  -I/opt/cuda/inc -L/opt/cuda/lib -lcufft --expt-extended-lambda -o fft99_cuda.o

# for rgy local -I/usr/local/cuda/inc -L/usr/local/cuda/lib 
nvcc   -ccbin gcc-7 -c ../src/utils/fft99_cuda.cu  -I/usr/local/cuda/inc -L/usr/local/cuda/lib -lcufft --expt-extended-lambda -o fft99_cuda.o

#INTEL='/media/rgy/linux-file/intel_parallel_studio/'
#cd /media/rgy/win-file/document/computer/HPC/cesm/CESM/models/atm/cam/bld/
#echo "zm_conv!"
icc  -mkl:sequential -c ../src/physics/cam/zm_conv_cuda.cpp -o zm_conv_cuda.o -O3 -xHost -fPIC -I/usr/include/x86_64-linux-gnu/c++/8/|| exit 2 
#echo "change this to icc for better opt"
#echo $INTEL
#icc -g -c  ../src/utils/fft_mkl.c  -o fft_mkl.o -fPIC -I $INTEL/mkl/include/|| exit 2 
#echo "fft_mkl done ! "