cmake_minimum_required(VERSION 3.4.1)

include_directories(../../../../..)

add_library(orchid SHARED
            orchid_native.c
            ../../../../../orchid.c)

# Include libraries needed for orchid lib
target_link_libraries(orchid
                      android
                      log)