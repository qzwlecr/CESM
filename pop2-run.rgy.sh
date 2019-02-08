#!/bin/bash

export LD_LIBRARY_PATH=/media/rgy/win-file/document/computer/HPC/cesm/netcdf-build/lib:${LD_LIBRARY_PATH}:/media/rgy/win-file/document/computer/HPC/cesm/openmpi/lib/

cd POP2
echo '  2) Enable double-precision time-averaged history-file output files
     ("tavg history files"). To do this, edit  line 133 in the
     $CASEROOT/$CASE1/Buildconf/pop2.buildexe.csh file. Replace

        set pop2defs = "`cat $OBJROOT/ocn/obj/POP2_cppdefs`"

     with

        set pop2defs = "`cat $OBJROOT/ocn/obj/POP2_cppdefs` -DTAVG_R8"
                                                           ^^^^^^^^^^

     Note that you are just adding " -DTAVG_R8" between the single quote and
     the double quote, the '^' characters are used to highlight the change.
 
  3) Modify the tavg_contents file and the base.tavg.csh file to output the
     SSH variable every timestep:
     a) cp $CCSMROOT/models/ocn/pop2/input_templates/gx1v6_tavg_contents \
           $CASEROOT/$CASE1/SourceMods/src.pop2/
     b) Move the variable SSH from stream 1 to stream 2 by editing line 26 of 
        the file $CASEROOT/$CASE1/SourceMods/src.pop2/gx1v6_tavg_contents, 
        replacing

           1  SSH

        with

           2  SSH
          ^^^

     c) cp $CCSMROOT/models/ocn/pop2/input_templates/ocn.base.tavg.csh   \
           $CASEROOT/$CASE1/SourceMods/src.pop2/
     d) Set the output frequency of stream 2 to every timestep rather than
        daily by editing lines 6, 8, 9, and 10. Replace 
...

        As with step 2, the  characters are meant to highlight where you
        need to edit the specified files, they do not need to be included in
        the file itself.'
echo 'http://www.cesm.ucar.edu/models/cesm1.2/pop2/validation/docs/20130109_port_validation'
./POP2.build || exit 3
echo "run!!!"
./POP2.run 
