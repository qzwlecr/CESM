#! /bin/bash
cd /home/mike/workspace/asc19/CESM/models/atm/cam/bld/
echo "cuda!"
nvcc   -ccbin gcc-7 -c ../src/utils/fft99_cuda.cu  -I/opt/cuda/inc -L/opt/cuda/lib -lcufft -o fft99_cuda.o
#runtime as static --cudart static
nvcc   -ccbin gcc-7  -c ../src/physics/cam/aer_rad_props_cuda.cu -o aer_rad_props_cuda.o  || exit 2
nvcc   -ccbin gcc-7  -c ../src/physics/cam/zm_conv_cuda.cu -o zm_conv_cuda.o  || exit 2
nvcc   -ccbin gcc-7  -c ../src/dynamics/fv/geopk_cuda.cu -o geopk_cuda.o  || exit 2