#! /bin/bash
#icc  -mkl:sequential -c ../src/physics/cam/zm_conv_cuda.cpp -o zm_conv_cuda.o -O3 -xHost -fPIC -I/usr/include/x86_64-linux-gnu/c++/8/|| exit 2 
icc -c /media/rgy/win-file/document/computer/HPC/cesm/CESM/models/atm/cam/src/utils/fft100_cuda.cpp -lmkl_rt -L/media/rgy/linux-file/intel_parallel_studio/mkl/tools/builder/ -I/media/rgy/linux-file/intel_parallel_studio/mkl/include/fftw/ \
-L/media/rgy/linux-file/intel_parallel_studio/mkl/lib/intel64/    -lintlc  -fPIC
