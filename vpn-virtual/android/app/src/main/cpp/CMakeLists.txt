cmake_minimum_required(VERSION 3.4.1)

include_directories(../../../../..
                    ../../../../blocksruntime/BlocksRuntime)

add_library(orchid SHARED
            orchid_native.c
            ../../../../../orchid.c
            ../../../../../tun_client.c)

target_compile_options(orchid PRIVATE -fblocks)

add_subdirectory(../../../../blocksruntime blocksruntime)

target_link_libraries(orchid
                      android
                      log
                      blocksruntime)