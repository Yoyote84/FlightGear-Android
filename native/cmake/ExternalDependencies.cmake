# Native dependency policy shared by the staged Android build.
# The actual dependency libraries are installed into the convergence prefix by
# the CI/bootstrap stages; this file prevents accidental host-library lookup.

if(NOT DEFINED FG_NATIVE_PREFIX)
    message(FATAL_ERROR "FG_NATIVE_PREFIX must point at the ARM64 native install prefix")
endif()

set(CMAKE_PREFIX_PATH "${FG_NATIVE_PREFIX}" ${CMAKE_PREFIX_PATH})
set(CMAKE_FIND_ROOT_PATH "${FG_NATIVE_PREFIX}" ${CMAKE_FIND_ROOT_PATH})

# Never satisfy an Android dependency with a host Linux library.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

message(STATUS "FlightGear Android native dependency prefix: ${FG_NATIVE_PREFIX}")
