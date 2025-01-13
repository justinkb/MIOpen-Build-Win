#----------------------------------------------------------------
# Generated CMake target import file for configuration "RelWithDebInfo".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "amd_comgr" for configuration "RelWithDebInfo"
set_property(TARGET amd_comgr APPEND PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO)
set_target_properties(amd_comgr PROPERTIES
  IMPORTED_LOCATION_RELWITHDEBINFO "${_IMPORT_PREFIX}/lib/libamd_comgr.so.2.8.60203"
  IMPORTED_SONAME_RELWITHDEBINFO "libamd_comgr.so.2"
  )

list(APPEND _cmake_import_check_targets amd_comgr )
list(APPEND _cmake_import_check_files_for_amd_comgr "${_IMPORT_PREFIX}/lib/libamd_comgr.so.2.8.60203" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
