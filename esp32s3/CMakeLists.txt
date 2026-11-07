cmake_minimum_required(VERSION 3.16)

include($ENV{IDF_PATH}/tools/cmake/project.cmake)

idf_build_set_property(MINIMAL_BUILD ON)

project(nu_pogodi_esp32s3)

set_property(TARGET "${PROJECT_NAME}.elf" APPEND PROPERTY
    ADDITIONAL_CLEAN_FILES "${CMAKE_CURRENT_SOURCE_DIR}/.objs"
                           "${CMAKE_CURRENT_SOURCE_DIR}/runtime")
