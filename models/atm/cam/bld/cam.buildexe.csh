#! /bin/csh -f
#build cuda here!
set rootdir = `dirname $0`
set abs_rootdir = `cd $rootdir && pwd`
echo $abs_rootdir
cd $abs_rootdir
cd ../../models/atm/cam/bld/ || exit 2  #这里要cd 到源代码里的那个地方，我不知道集群上的情况，所以你可能要改一下
./cuda-build.sh || exit 2
ls | grep cuda
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

