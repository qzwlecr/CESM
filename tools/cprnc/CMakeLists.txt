cmake_minimum_required(VERSION 3.13)
PROJECT(CPRNC C Fortran)

ENABLE_LANGUAGE(Fortran) 

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/CMake)

set (NETCDF_F90 "YES")
find_package (NetCDF REQUIRED)
include_directories(${NetCDF_INCLUDES})
#target_link_libraries (uses_f90_interface ${NETCDF_LIBRARIES})
#target_link_libraries (only_uses_c_interface ${NETCDF_LIBRARIES_C}) 
message("fuckit ${NetCDF_LIBRARIES}")
# Defining NETCDF_LIBRARIES and NETCDF_INCLUDE_DIR enables bypassing
##   the search for Netcdf
#IF (NOT DEFINED NETCDF_LIBRARIES OR NOT DEFINED NETCDF_INCLUDE_DIR)
#  FIND_PACKAGE(Netcdf REQUIRED)
#  SET(NETCDF_INCLUDE_DIR ${Netcdf_INCLUDE_DIR})
#  SET(NETCDF_LIBRARIES ${Netcdf_LIBRARIES})
#ENDIF ()

include_directories(/usr/include)
link_directories(/usr/lib)

ADD_CUSTOM_COMMAND(
  OUTPUT ${PROJECT_BINARY_DIR}/compare_vars_mod.F90
  COMMAND perl ${PROJECT_SOURCE_DIR}/genf90/genf90.pl
    ${PROJECT_SOURCE_DIR}/compare_vars_mod.F90.in > ${PROJECT_BINARY_DIR}/compare_vars_mod.F90
)

ADD_CUSTOM_TARGET(COMPARE_VARS DEPENDS ${PROJECT_BINARY_DIR}/compare_vars_mod.F90)

# Support extended line lengths
IF (${CMAKE_Fortran_COMPILER_ID} STREQUAL GNU)
  SET(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -ffree-line-length-none")
ELSEIF (CMAKE_COMPILER_ID STREQUAL PGI)
  SET(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -Mextend")
ELSEIF (CMAKE_COMPILER_ID STREQUAL PathScale)
  SET(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -extend-source")
ENDIF ()

INCLUDE_DIRECTORIES(
  ${NETCDF_INCLUDE_DIR}
  ${PROJECT_SOURCE_DIR}
  ${PROJECT_BINARY_DIR}
)                

SET (CPRNC_SRCS
  ${PROJECT_BINARY_DIR}/compare_vars_mod.F90
  filestruct.F90
  utils.F90
  prec.F90
  cprnc.F90
)

ADD_EXECUTABLE(cprnc ${CPRNC_SRCS})
ADD_DEPENDENCIES(cprnc COMPARE_VARS)

TARGET_LINK_LIBRARIES(cprnc netcdff)

INSTALL(TARGETS cprnc
        RUNTIME DESTINATION bin)
