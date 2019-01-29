#! /bin/csh -f
#build cuda here!
cd /media/rgy/win-file/document/computer/HPC/cesm/CESM/models/atm/cam/bld/
echo "cuda!"
#nvcc   -ccbin gcc-7 -c ../src/utils/fft99.cu  -I/usr/local/cuda/inc -L/usr/local/cuda/lib -lcufft -o fft_cuda.o
#runtime as static --cudart static
nvcc   -ccbin gcc-7  -c ../src/physics/cam/aer_rad_props_cuda.cu -o aer_rad_props_cuda.o  || exit 2
nvcc   -ccbin gcc-7  -c ../src/dynamics/fv/geopk_cuda.cu -o geopk_cuda.o  || exit 2
#所有的.cu都要用*_cuda.cu 结尾，因为编译脚本就是这么判断的, *_cuda.cu->*_cuda.o
echo "move cuda.o to the obj dir!"
cp ./*_cuda.o $OBJROOT/atm/obj
#cp ./*_cuda.o $OBJROOT/cesm/obj

echo $OBJROOT
cd $OBJROOT/atm/obj

cp $CASEBUILD/camconf/Filepath ./tmp_filepath 
if (-f Filepath) then
  cmp -s tmp_filepath Filepath || mv -f tmp_filepath Filepath 
else
  mv -f tmp_filepath Filepath 
endif

set camdefs = "`cat $CASEBUILD/camconf/CCSM_cppdefs`"
#echo 'we are'
#echo $CASETOOLS
gmake complib -j $GMAKE_J MODEL=cam COMPLIB=$LIBROOT/libatm.a USER_CPPDEFS="$camdefs" -f $CASETOOLS/Makefile   || exit 2

wait

