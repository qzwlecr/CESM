rm ./a.out
#icc -c ./fft100_cuda.cpp -lmkl_rt -L/media/rgy/linux-file/intel_parallel_studio/mkl/tools/builder/ -I/media/rgy/linux-file/intel_parallel_studio/mkl/include/fftw/ \
#-L/media/rgy/linux-file/intel_parallel_studio/mkl/lib/intel64/
icc -Wall ./test.cpp -lmkl_rt -L/media/rgy/linux-file/intel_parallel_studio/mkl/tools/builder/ -I/media/rgy/linux-file/intel_parallel_studio/mkl/include/fftw/ \
-L/media/rgy/linux-file/intel_parallel_studio/mkl/lib/intel64/

#icc ./fft100_cuda.o ./test.o -lmkl_rt -L/media/rgy/linux-file/intel_parallel_studio/mkl/tools/builder/ -I/media/rgy/linux-file/intel_parallel_studio/mkl/include/fftw/ \
#-L/media/rgy/linux-file/intel_parallel_studio/mkl/lib/intel64/
echo 1
./a.out
exit

rm ./a.out || echo 0
echo 2
icc ./test.o ./fft99_cuda.o -lstdc++\
 -L/usr/local/cuda/lib64 -lcufft -lcudart 
 sleep 1
./a.out
rm ./a.out
ifort ./fft99f.f ./fft_fftw.F90 ./test.F90 -mkl
./a.out