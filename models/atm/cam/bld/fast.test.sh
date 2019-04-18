./cuda-build.sh
gmake
rm -f ./cam
mpifort -o /media/rgy/win-file/document/computer/HPC/cesm/CESM/models/atm/cam/bld/cam ./*.o  \
-lstdc++ -L/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib -lnetcdff \
-L/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib -lnetcdf -lnetcdf \
-Wl,-rpath=/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib  \
-L/media/rgy/win-file/document/computer/HPC/cesm/CESM/models/atm/cam/bld/mct/mct -lmct \
-L/media/rgy/win-file/document/computer/HPC/cesm/CESM/models/atm/cam/bld/mct/mpeu -lmpeu  \
-L/media/rgy/win-file/document/computer/HPC/cesm/openmpi/lib -lmpi \
-lmkl_intel_ilp64 -lmkl_sequential -lmkl_core -lsvml -lintlc \
 -L/usr/local/cuda/lib64 -lcufft -lcudart && ./cam