###########################################################################################
get_filename_component(PkgInfoResource "${CMAKE_CURRENT_SOURCE_DIR}/cmake/resources/PkgInfo" ABSOLUTE)

###########################################################################################
if(LINUX)
  pkg_check_modules(GTKMM3 REQUIRED gtkmm-3.0)
endif(LINUX)

###########################################################################################
function(vstgui_add_executable target sources)

    if(MSVC)
    # PIN: 04.03.2020 - added a comment related to the difference between MINGW and MSVC
    # When the WIN32 property is set to true the executable when linked on Windows will be created with a WinMain() entry point instead of just main(). 
    # This makes it a GUI executable instead of a console application.
    add_executable(${target} WIN32 ${sources})
    set_target_properties(${target} PROPERTIES LINK_FLAGS "/INCLUDE:wWinMain")
    get_target_property(OUTPUTDIR ${target} RUNTIME_OUTPUT_DIRECTORY)
    set_target_properties(${target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${OUTPUTDIR}/${target}")
  endif(MSVC)

  # PIN: 04.03.2020 - added MINGW support
  if(MINGW)
    # When the WIN32 property is set to true the executable when linked on Windows will be created with a WinMain() entry point instead of just main(). 
    # This makes it a GUI executable instead of a console application.
    # A WIN32 flag to add_executable means you're going to make it a Windows program, and provide a WinMain function.
    # This also results in no console window.
    add_executable(${target} WIN32 ${sources})

    #  -municode
    # This option is available for MinGW-w64 targets.  It causes the
    # "UNICODE" preprocessor macro to be predefined, and chooses
    # Unicode-capable runtime startup code.
    # with the -municode flag:
    # .... in function `wmain': crt0_w.c:23: undefined reference to `wWinMain'
    # without this flag:
    # .... in function `main': crt0_c.c:18: undefined reference to `WinMain'
    # together with -mwindows this make the entry point wWinMain instead of WinMain
    # https://gcc.gnu.org/onlinedocs/gcc/x86-Windows-Options.html
    set_target_properties(${target} PROPERTIES LINK_FLAGS -municode)

    get_target_property(OUTPUTDIR ${target} RUNTIME_OUTPUT_DIRECTORY)
    set_target_properties(${target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${OUTPUTDIR}/${target}")

    # PIN: ensure that the find library also finds windows dll's 
    # the standard find_library` command does no longer consider .dll files to be linkable libraries. 
    # all dynamic link libraries are expected to provide separate .dll.a or .lib import libraries.
    set(CMAKE_FIND_LIBRARY_SUFFIXES ".dll" ".dll.a" ".a" ".lib")
    find_library(DWMAPI_FRAMEWORK dwmapi REQUIRED)                  # Desktop Window Manager (DWM)
    find_library(COMCTL32_FRAMEWORK comctl32 REQUIRED)              # The Common Controls Library - provider of the more interesting window controls

    message(STATUS "Linking vstgui executable with libraries (${target}): 
        ${DWMAPI_FRAMEWORK}
        ${COMCTL32_FRAMEWORK}
    " )

    # ensure the vst gui sources finds eachother modules
    set(PLATFORM_LIBRARIES 
        ${DWMAPI_FRAMEWORK}     # win32window.cpp
        ${COMCTL32_FRAMEWORK}   # win32window.cpp
    )

  endif(MINGW)

  if(LINUX)
    add_executable(${target} ${sources})
    get_target_property(OUTPUTDIR ${target} RUNTIME_OUTPUT_DIRECTORY)
    set_target_properties(${target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${OUTPUTDIR}/${target}")
    set(PLATFORM_LIBRARIES ${GTKMM3_LIBRARIES})
  endif(LINUX)

  if(CMAKE_HOST_APPLE)
    set_source_files_properties(${PkgInfoResource} PROPERTIES
      MACOSX_PACKAGE_LOCATION "."
    )
    add_executable(${target} ${sources} ${PkgInfoResource})
    set(PLATFORM_LIBRARIES
      "-framework Cocoa"
      "-framework OpenGL"
      "-framework QuartzCore"
      "-framework Accelerate"
    )
    set_target_properties(${target} PROPERTIES
      MACOSX_BUNDLE TRUE
      XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT $<$<CONFIG:Debug>:dwarf>$<$<NOT:$<CONFIG:Debug>>:dwarf-with-dsym>
      XCODE_ATTRIBUTE_DEPLOYMENT_POSTPROCESSING $<$<CONFIG:Debug>:NO>$<$<NOT:$<CONFIG:Debug>>:YES>
      OUTPUT_NAME "${target}"
    )
  endif(CMAKE_HOST_APPLE)

  target_link_libraries(${target}
    vstgui
    vstgui_uidescription
    vstgui_standalone
    ${PLATFORM_LIBRARIES}
  )
  target_compile_definitions(${target} ${VSTGUI_COMPILE_DEFINITIONS})

  if(ARGC GREATER 2)
    vstgui_add_resources(${target} "${ARGV2}")
    message(DEPRECATION "Please use vstgui_add_resources to add resources to an executable now.")
  endif()

endfunction()

###########################################################################################
function(vstgui_add_resources target resources)
  set(destination "Resources")
  if(ARGC GREATER 2)
    set(destination "${destination}/${ARGV2}")
  endif()
  if(CMAKE_HOST_APPLE)
    set_source_files_properties(${resources} PROPERTIES
      MACOSX_PACKAGE_LOCATION "${destination}"
    )
    target_sources(${target} PRIVATE ${resources})
  else()
    get_target_property(OUTPUTDIR ${target} RUNTIME_OUTPUT_DIRECTORY)
    set(destination "${OUTPUTDIR}/${destination}")
    if(NOT EXISTS ${destination})
      add_custom_command(TARGET ${target} PRE_BUILD
          COMMAND ${CMAKE_COMMAND} -E make_directory
          "${destination}"
      )
    endif()
    foreach(resource ${resources})
      add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
        "${CMAKE_CURRENT_LIST_DIR}/${resource}"
        "${destination}"
      )
    endforeach(resource ${resources})
  endif()  
endfunction()

###########################################################################################
function(vstgui_set_target_infoplist target infoplist)
  if(CMAKE_HOST_APPLE)
    get_filename_component(InfoPlistFile "${infoplist}" ABSOLUTE)
    set_target_properties(${target} PROPERTIES
      MACOSX_BUNDLE_INFO_PLIST ${InfoPlistFile}
    )
  endif(CMAKE_HOST_APPLE)
endfunction()

###########################################################################################
function(vstgui_set_target_rcfile target rcfile)
  # PIN: 07.03.2020 - added MINGW support
  if(MINGW)
    # check if the rcfile is empty to avoid windres errors
    file(READ ${rcfile} rcfile_content)
    if(NOT ${rcfile_content} STREQUAL "")
      message("Using resource file: ${rcfile}")

      # call windres with the resource fil
      target_sources(${target} PRIVATE ${rcfile})
    endif()
  elseif(MSVC)
    target_sources(${target} PRIVATE ${rcfile})
  endif()

endfunction()
