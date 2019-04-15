#! /bin/bash
#icc  -mkl:sequential -c ../src/physics/cam/zm_conv_cuda.cpp -o zm_conv_cuda.o -O3 -xHost -fPIC -I/usr/include/x86_64-linux-gnu/c++/8/|| exit 2 