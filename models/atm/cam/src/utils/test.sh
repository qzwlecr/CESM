rm ./a.out
ifort ./fft99f.f ./fft_fftw.F90 ./test.F90 -mkl
./a.out