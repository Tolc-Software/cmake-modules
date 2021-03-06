include_guard()

# Macro for finding or downloading conan libraries
# This allows easier integration with consuming projects also using conan
macro(find_conan_packages)
  # Define the supported set of keywords
  set(prefix ARG)
  set(noValues DO_NOT_FIND)
  set(singleValues PROFILE)
  set(multiValues OPTIONS REQUIRES SETTINGS)
  # Process the arguments passed in can be used e.g. via ARG_TARGET
  cmake_parse_arguments(${prefix} "${noValues}" "${singleValues}"
                        "${multiValues}" ${ARGN})

  # Download it via conan
  message(STATUS "Will download dependencies via conan: ${ARG_REQUIRES}")
  run_conan(
    REQUIRES
    ${ARG_REQUIRES}
    OPTIONS
    ${ARG_OPTIONS}
    SETTINGS
    ${ARG_SETTINGS}
    PROFILE
    ${ARG_PROFILE})

  # Get the paths for the find_package calls
  include(${CMAKE_CURRENT_BINARY_DIR}/conan_paths.cmake)

  if(NOT ARG_DO_NOT_FIND)
    foreach(package ${ARG_REQUIRES})
      # Get the package name from the conan dependency
      string(REPLACE "/" ";" split_dep ${package})
      list(GET split_dep 0 package_name)

      # Uses Find${package_name} module that was generated by conan
      find_package(${package_name} REQUIRED)
    endforeach()
  endif()
endmacro(find_conan_packages)

# Downloads module to run conan from cmake
function(get_conan_helper)
  if(NOT EXISTS "${CMAKE_BINARY_DIR}/conan.cmake")
    message(STATUS "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
    file(DOWNLOAD "https://raw.githubusercontent.com/conan-io/cmake-conan/0.18.1/conan.cmake"
                  "${CMAKE_BINARY_DIR}/conan.cmake"
                  TLS_VERIFY ON)
  endif()
  include(${CMAKE_BINARY_DIR}/conan.cmake)
endfunction(get_conan_helper)

function(conan_setup_remotes)
  # Avoid running this command often
  if(_conan_has_set_remotes)
    message(STATUS "Conan remotes already set.")
    return()
  endif()
  # For clara
  conan_add_remote(NAME bincrafters URL
                   https://api.bintray.com/conan/bincrafters/public-conan)

  set(_conan_has_set_remotes
      TRUE
      CACHE INTERNAL
            "This is used to avoid setting the remotes twice. Only takes time.")
endfunction()

function(run_conan)
  # Define the supported set of keywords
  set(prefix ARG)
  set(noValues)
  set(singleValues PROFILE)
  set(multiValues SETTINGS OPTIONS REQUIRES)
  # Process the arguments passed in can be used e.g. via ARG_TARGET
  cmake_parse_arguments(${prefix} "${noValues}" "${singleValues}"
                        "${multiValues}" ${ARGN})

  # Get and include to get helper functions
  get_conan_helper()

  # Require that conan is installed
  conan_check(REQUIRED)

  # Add some useful remotes
  conan_setup_remotes()

  # Install dependencies
  conan_cmake_run(
    REQUIRES
    ${ARG_REQUIRES}
    OPTIONS
    ${ARG_OPTIONS}
    SETTINGS
    ${ARG_SETTINGS}
    BASIC_SETUP
    GENERATORS
    cmake_paths
    cmake_find_package
    PROFILE
    ${ARG_PROFILE}
    BUILD
    missing)
endfunction()

# Configure a conan profile that has '.in' as an extension with configure_file
# and puts the output next to the configured file.
# With no input it configures
#   ${PROJECT_SOURCE_DIR}/tools/conan_profiles/${CMAKE_SYSTEM_NAME}/clang.in
function(setup_conan_profile)
  # Define the supported set of keywords
  set(prefix ARG)
  set(noValues)
  set(singleValues VARIABLE PROFILE_TO_CONFIGURE)
  set(multiValues)
  # Process the arguments passed in
  # can be used e.g. via ARG_TARGET
  cmake_parse_arguments(${prefix} "${noValues}" "${singleValues}"
                        "${multiValues}" ${ARGN})

  # Set compiler specific flags that will be expanded in the profiles
  if(MSVC)
    if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")
      set(MSVC_RUNTIME_LIBRARY "MTd")
    else()
      set(MSVC_RUNTIME_LIBRARY "MT")
    endif()
  endif()

  # Get variables for writing the conan profile
  string(REPLACE "." ";" versionList ${CMAKE_CXX_COMPILER_VERSION})
  list(GET versionList 0 COMPILER_MAJOR_VERSION)

  if(ARG_PROFILE_TO_CONFIGURE)
    set(inProfile ${ARG_PROFILE_TO_CONFIGURE})
  else()
    # Default to tools/conan_profiles/{OS}/clang.in
    set(inProfile
        ${PROJECT_SOURCE_DIR}/tools/conan_profiles/${CMAKE_SYSTEM_NAME}/clang.in
    )
  endif()
  if(NOT EXISTS ${inProfile})
    message(
      FATAL_ERROR
        "The profile to configure does not exist. Got the profile: ${inProfile}"
    )
  endif()
  # {[outProfile, 'anythingDotSeparated'], 'in'}
  # Get the profile path without the '.in' extension
  string(REPLACE "." ";" profileList ${inProfile})
  list(REMOVE_AT profileList -1)
  list(JOIN profileList "." outProfile)

  configure_file(${inProfile} ${outProfile} @ONLY)
  if(ARG_VARIABLE)
    set(${ARG_VARIABLE}
        ${outProfile}
        PARENT_SCOPE)
  endif()
endfunction()
