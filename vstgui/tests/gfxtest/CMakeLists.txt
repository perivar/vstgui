##########################################################################################
# VSTGUI GFXTest Application
##########################################################################################
set(target GFXTest)

set(${target}_sources
  "source/app.cpp"
  "source/drawdevicetests.cpp"
  "source/drawdevicetests.h"
)

##########################################################################################
if(CMAKE_HOST_APPLE)
	set(BUNDLE_PKG_INFO
    "resource/PkgInfo"
	)
	set(gfxtest_resources
		"resource/Window.uidesc"
		"resource/DrawDeviceTests.uidesc"
	)
	set_source_files_properties(${BUNDLE_PKG_INFO} PROPERTIES
		MACOSX_PACKAGE_LOCATION "."
	)
  set_source_files_properties(${gfxtest_resources} PROPERTIES
    MACOSX_PACKAGE_LOCATION "Resources"
  )
  set(gfxtest_resources ${gfxtest_resources} ${BUNDLE_PKG_INFO})
  
	set(${target}_PLATFORM_LIBS
		"-framework Cocoa"
		"-framework OpenGL"
		"-framework QuartzCore"
		"-framework Accelerate"
	)
	get_filename_component(InfoPlistFile "resource/Info.plist" ABSOLUTE)
	set(APP_PROPERTIES
		MACOSX_BUNDLE TRUE
		MACOSX_BUNDLE_INFO_PLIST ${InfoPlistFile}
		OUTPUT_NAME "GFXTest"
	)
endif()

##########################################################################################
# PIN: 07.03.2020 - check for MINGW in addition to MSVC
if(MSVC OR MINGW)
  set(gfxtest_resources
    "resource/gfxtest.rc"
  )
endif()

if(MSVC)  
  set(APP_PROPERTIES
    LINK_FLAGS "/SUBSYSTEM:windows /INCLUDE:wWinMain"
  )
endif()

##########################################################################################
include_directories(../../../)

# PIN: 11.04.2020 - set correct flags and add libraries vstgui and the missing windows libraries
if(MINGW)
	# When the WIN32 property is set to true the executable when linked on Windows will be created with a WinMain() entry point instead of just main(). 
	# This makes it a GUI executable instead of a console application.
	# A WIN32 flag to add_executable means you're going to make it a Windows program, and provide a WinMain function.
	# This also results in no console window.
	add_executable(${target}
		WIN32
		${${target}_sources}
		${gfxtest_resources}
	)

	# together with -mwindows this make the entry point wWinMain instead of WinMain
	# https://gcc.gnu.org/onlinedocs/gcc/x86-Windows-Options.html   
	set_target_properties(${target} PROPERTIES LINK_FLAGS -municode)

	# add libraries vstgui and the missing windows libraries
	set(${target}_PLATFORM_LIBS
		"vstgui"
		"windowscodecs"
		"comctl32"
	)

	# PIN: 15.03.2020 - copy Resource files as well
	set(gfxtest_uiresources
		"resource/Window.uidesc"
		"resource/DrawDeviceTests.uidesc"
	)
	vstgui_add_resources(${target} "${gfxtest_uiresources}")
else()
	add_executable(${target}
		${${target}_sources}
		${gfxtest_resources}
	)
endif()

target_link_libraries(${target}
	vstgui
  	vstgui_uidescription
  	vstgui_standalone
	${${target}_PLATFORM_LIBS}
)

# PIN: 10.03.2020 - change version to 17
vstgui_set_cxx_version(${target} 17)

set_target_properties(${target} PROPERTIES ${APP_PROPERTIES} FOLDER Tests)
target_compile_definitions(${target} ${VSTGUI_COMPILE_DEFINITIONS})
