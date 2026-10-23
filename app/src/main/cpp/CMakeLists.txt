cmake_minimum_required(VERSION 3.22.1)
project(flightgear_android LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(flightgear_android SHARED native_bridge.cpp)

target_compile_definitions(flightgear_android PRIVATE FG_ANDROID=1)
