cmake_minimum_required(VERSION 3.20)
project(modbus_actuator_guard CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN 1)

include_directories(/home/kami/blackbox-sentinel/include)

add_library(modbus_actuator_guard SHARED src/plugin.cpp)
set_target_properties(modbus_actuator_guard PROPERTIES PREFIX "")
