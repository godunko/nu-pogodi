idf_component_register(
    REQUIRES espidf_gnat_runtime freertos esp_timer a0b_espidf_timer_clock_timer espidfada_button espidfada_driver_gpio espidfada_driver_spi espidfada_timer)

idf_component_get_property(runtime_dir espidf_gnat_runtime COMPONENT_DIR)
include("${runtime_dir}/cmake/ada-application.cmake")

espidf_add_ada_application(
    TARGET "${COMPONENT_LIB}"
    PROJECT_DIR "${PROJECT_DIR}"
    OBJECT ".objs/app_main.o")
