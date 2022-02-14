include_guard()

# Creates a test executable linked with a Catch2 main library (that is created
# for you)

macro(get_catch2)
  # Define the supported set of keywords
  set(prefix ARG)
  set(singleValues VERSION)
  set(multiValues)
  # Process the arguments passed in
  cmake_parse_arguments(${prefix} "${noValues}" "${singleValues}"
                        "${multiValues}" ${ARGN})

  if(NOT ARG_VERSION)
    message(FATAL_ERROR "Must provide a VERSION.")
  endif()


  include(FetchContent)
  FetchContent_Declare(
    Catch2
    GIT_REPOSITORY https://github.com/catchorg/Catch2.git
    GIT_TAG ${ARG_VERSION})
  FetchContent_MakeAvailable(Catch2)

  # These are needed to use create_catch2_test
  set(Catch2_FOUND TRUE)
  set(Catch2_INCLUDE_DIRS ${Catch2_SOURCE_DIR}/single_include)
endmacro()

# NOTE: Depends on find_package(Catch2) has been called before this function
function(create_catch2_test)
  if(NOT Catch2_FOUND)
    message(FATAL_ERROR "Catch2 not found. Did you forget
  to set find_package(catch2)?")
    return()
  endif()

  # Define the supported set of keywords
  set(prefix ARG)
  set(singleValues TARGET)
  set(multiValues SOURCES LINK_LIBRARIES INCLUDE)
  # Process the arguments passed in
  cmake_parse_arguments(${prefix} "${noValues}" "${singleValues}"
                        "${multiValues}" ${ARGN})

  if(NOT ARG_TARGET)
    message(FATAL_ERROR "Must provide a target.")
  endif()
  if(NOT ARG_SOURCES)
    message(FATAL_ERROR "Must provide sources.")
  endif()

  # Define catch2_main_target variable
  _create_main_catch2()

  add_executable(${ARG_TARGET} ${ARG_SOURCES})
  target_link_libraries(${ARG_TARGET} PRIVATE ${catch2_main_target}
                                              ${ARG_LINK_LIBRARIES})
  if(ARG_INCLUDE)
    target_include_directories(${ARG_TARGET} PRIVATE ${ARG_INCLUDE})
  endif()
  set_target_properties(${ARG_TARGET} PROPERTIES CXX_STANDARD_REQUIRED ON
                                                 CXX_EXTENSIONS OFF)

  add_test(NAME ${ARG_TARGET} COMMAND ${ARG_TARGET})
endfunction()

# NOTE: Internal function that should not be called

# Creates a file with a Catch main defined as
# https://github.com/catchorg/Catch2/blob/main/docs/slow-compiles.md#top Then
# it creates a library that can be linked against to get Catch2
function(_create_main_catch2)
  set(main_catch2_file "${CMAKE_CURRENT_BINARY_DIR}/main_catch2.cpp")
  if(NOT EXISTS ${main_catch2_file})
    message(STATUS "Creating Catch2 main file: ${main_catch2_file}")
    file(WRITE ${main_catch2_file}
         "#define CATCH_CONFIG_MAIN\n#include <catch2/catch.hpp>")
  endif()

  # Export catch2_main_target to the caller
  set(catch2_main_target "_catch2Main")
  set(catch2_main_target
      ${catch2_main_target}
      PARENT_SCOPE)
  if(NOT TARGET ${catch2_main_target})
    # Add the main catch library
    message(STATUS "Creating library target: ${catch2_main_target}")

    add_library(${catch2_main_target} ${main_catch2_file})
    target_include_directories(${catch2_main_target} SYSTEM
                               PUBLIC ${Catch2_INCLUDE_DIRS})
  endif()
endfunction()
