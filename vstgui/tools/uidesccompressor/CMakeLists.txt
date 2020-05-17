set(TargetName uidesccompressor)

set(${TargetName}_sources
    main.cpp
)

set(${TargetName}_PLATFORM_LIBS "")

if(CMAKE_HOST_APPLE)
  set(${TargetName}_PLATFORM_LIBS
    "-framework Cocoa"
    "-framework OpenGL"
    "-framework QuartzCore"
    "-framework Accelerate"
    "-framework CoreAudio"
  )
endif()

# PIN: 10.03.2020 - add libraries vstgui and the missing windows libraries
if(MINGW)
  # For some reason we need to reorder the libs and include vstgui_uidescription before vstgui to avoid compilation errors
  set(${TargetName}_PLATFORM_LIBS
    "vstgui_uidescription"
    "vstgui"
    "windowscodecs"
  )
else()
  set(${TargetName}_PLATFORM_LIBS
    "vstgui"
    "vstgui_uidescription"
  )
endif()

add_executable(${TargetName}
  ${${TargetName}_sources}
)
target_link_libraries(${TargetName}
  # PIN 17.05.2020: use the platform libs variable instead of specifying them directly  
  ${${TargetName}_PLATFORM_LIBS}
)
target_include_directories(${TargetName} PRIVATE ../../../)

# PIN: 10.03.2020 - change version to 17
vstgui_set_cxx_version(${TargetName} 17)

set_target_properties(${TargetName} PROPERTIES ${APP_PROPERTIES} ${VSTGUI_TOOLS_FOLDER})
target_compile_definitions(${TargetName} ${VSTGUI_COMPILE_DEFINITIONS})
