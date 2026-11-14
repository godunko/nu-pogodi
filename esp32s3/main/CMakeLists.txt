idf_component_register(
    REQUIRES espidf_gnat_runtime freertos esp_timer a0b_espidf_timer_clock_timer espidfada_driver_gpio espidfada_driver_spi)

include(ExternalProject)

ExternalProject_Add(app_main_build
    PREFIX ${COMPONENT_DIR}
    SOURCE_DIR ${COMPONENT_DIR}
    BUILD_IN_SOURCE 1
    BUILD_ALWAYS 1
    CONFIGURE_COMMAND ""
    BUILD_COMMAND alr -n build
    INSTALL_COMMAND ""
    BUILD_BYPRODUCTS ${COMPONENT_DIR}/../.objs/app_main.o
)

add_prebuilt_library(app_main "${COMPONENT_LIB}" REQUIRES freertos)
add_dependencies(app_main app_main_build)

target_link_libraries(
    ${COMPONENT_LIB} INTERFACE ${COMPONENT_DIR}/../.objs/app_main.o)
