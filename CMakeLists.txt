cmake_minimum_required(VERSION 3.17)

project(
  tolc-cmake-modules
  VERSION 0.1
  LANGUAGES CXX)

# Only build tests and benchmarks if building this project directly
if(PROJECT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
  option(ENABLE_TESTING "Build the testing tree" OFF)
  if(ENABLE_TESTING)
    enable_testing()
    # add_subdirectory(tests)
  endif()

  option(ENABLE_BENCHMARKS "Build the benchmarks" OFF)
  if(ENABLE_BENCHMARKS)
    # TODO: Add benchmarks
  endif()

  option(ENABLE_PACKAGING "Enables install and packaging via CPack" OFF)
  if(ENABLE_PACKAGING)
    # add_subdirectory(tools/packaging)
    if(ENABLE_TESTING)
      # add_subdirectory(tests/packaging)
    endif()
  endif()
endif()
