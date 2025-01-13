
# Derive absolute install prefix from config file path.
get_filename_component(AMD_COMGR_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(AMD_COMGR_PREFIX "${AMD_COMGR_PREFIX}" PATH)
get_filename_component(AMD_COMGR_PREFIX "${AMD_COMGR_PREFIX}" PATH)
get_filename_component(AMD_COMGR_PREFIX "${AMD_COMGR_PREFIX}" PATH)

include("${AMD_COMGR_PREFIX}/lib/cmake/amd_comgr/amd_comgr-targets.cmake")
