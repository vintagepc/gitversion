set(DIR_OF_GITVERSION_TOOL "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "DIR_OF_GITVERSION_TOOL")

function (_CREATE_GIT_VERSION_FILE)
  FILE(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/messmer_gitversion")
  FILE(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/messmer_gitversion/gitversion")
  
find_program(PYTHON_BIN NAMES python python3 REQUIRED)

  IF(DEFINED ENV{PYTHONPATH})
      SET(ENV{PYTHONPATH} "${DIR_OF_GITVERSION_TOOL}/src:ENV{PYTHONPATH}")
  ELSE()
      SET(ENV{PYTHONPATH} "${DIR_OF_GITVERSION_TOOL}/src")
  ENDIF()
  EXECUTE_PROCESS(COMMAND /usr/bin/env ${PYTHON_BIN} -m gitversionbuilder --lang cpp --dir "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/messmer_gitversion/gitversion/version.h"
		  RESULT_VARIABLE result)
  IF(NOT ${result} EQUAL 0)
    MESSAGE(FATAL_ERROR "Error running messmer/git-version tool. Return code is: ${result}")
  ENDIF()
endfunction (_CREATE_GIT_VERSION_FILE)

function(_SET_GITVERSION_CMAKE_VARIABLE OUTPUT_VARIABLE)
  # Load version string and write it to a cmake variable so it can be accessed from cmake.
  FILE(READ "${CMAKE_CURRENT_BINARY_DIR}/messmer_gitversion/gitversion/version.h" VERSION_H_FILE_CONTENT)
  STRING(REGEX REPLACE ".*VERSION_STRING = \"([^\"]*)\".*" "\\1" VERSION_STRING "${VERSION_H_FILE_CONTENT}")
  MESSAGE(STATUS "Version from git: ${VERSION_STRING}")
  SET(${OUTPUT_VARIABLE} "${VERSION_STRING}" CACHE INTERNAL "${OUTPUT_VARIABLE}")
endfunction(_SET_GITVERSION_CMAKE_VARIABLE)

######################################################
# Add git version information
# Uses:
#   TARGET_GIT_VERSION_INIT(buildtarget)
# Then, you can write in your source file:
#   #include <gitversion/version.h>
#   cout << gitversion::VERSION.toString() << endl;
######################################################
function(TARGET_GIT_VERSION_INIT TARGET)
  _CREATE_GIT_VERSION_FILE()
  TARGET_INCLUDE_DIRECTORIES(${TARGET} PUBLIC "${CMAKE_CURRENT_BINARY_DIR}/messmer_gitversion")
  _SET_GITVERSION_CMAKE_VARIABLE(GITVERSION_VERSION_STRING)
endfunction(TARGET_GIT_VERSION_INIT)

######################################################
# Load git version information into a cmake variable
# Uses:
#  GET_GIT_VERSION(OUTPUT_VARIABLE)
#  MESSAGE(STATUS "The version is ${OUTPUT_VARIABLE}")
######################################################
function(GET_GIT_VERSION OUTPUT_VARIABLE)
  _CREATE_GIT_VERSION_FILE()
  _SET_GITVERSION_CMAKE_VARIABLE(${OUTPUT_VARIABLE})
endfunction(GET_GIT_VERSION OUTPUT_VARIABLE)

function(GET_GIT_SEMVER OUTPUT_VARIABLE)
  GET_GIT_VERSION(TEMP_VERSION)
  STRING(REGEX MATCH "^v([0-9]+\\.[0-9]+\\.[0-9]+)" match "${TEMP_VERSION}" )
  if (NOT match)
    message(STATUS "No semver detected in version string.")
    SET(${OUTPUT_VARIABLE}  "0.0.0" CACHE INTERNAL "${OUTPUT_VARIABLE}")
  else()
    STRING (REGEX REPLACE "v" "" match "${match}")
    message(STATUS "Semver: ${match}")
    SET(${OUTPUT_VARIABLE} "${match}" CACHE INTERNAL "${OUTPUT_VARIABLE}")
  endif()
endfunction(GET_GIT_SEMVER OUTPUT_VARIABLE)