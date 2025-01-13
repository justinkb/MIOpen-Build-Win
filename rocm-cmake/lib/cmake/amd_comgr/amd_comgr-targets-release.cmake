#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "amd_comgr" for configuration "Release"
set_property(TARGET amd_comgr APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(amd_comgr PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "CXX"
  IMPORTED_IMPLIB "${_IMPORT_PREFIX}/lib/amd_comgr0602.lib"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/bin/amd_comgr0602.dll"
  )

list(APPEND _cmake_import_check_targets amd_comgr )
list(APPEND _cmake_import_check_files_for_amd_comgr "${_IMPORT_PREFIX}/lib/amd_comgr0602.lib" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
