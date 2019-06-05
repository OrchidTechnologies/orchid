cmake_minimum_required(VERSION 3.4.1)

include_directories(.)

add_library(blocksruntime STATIC
            BlocksRuntime/data.c
            BlocksRuntime/runtime.c)
