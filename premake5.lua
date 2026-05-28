function string.starts(String,Start)
	if ( _ACTION ) then
		return string.sub(String,1,string.len(Start))==Start
	end

	return false
end

function is_vs()
	return ( string.starts(_ACTION,"vs") )
end

function conf_warnings()
	if not is_vs() then
		buildoptions{ "-Wall -Wno-long-long" }

		if not os.istarget("windows") then
			buildoptions{ "-fPIC" }
		end
	else
		defines { "_SCL_SECURE_NO_WARNINGS" }
	end

	if _OPTIONS["thread-sanitizer"] then
		buildoptions { "-fsanitize=thread" }
		linkoptions { "-fsanitize=thread" }
		if not os.istarget("macosx") then
			links { "tsan" }
		end
	end

	if _OPTIONS["address-sanitizer"] then
		buildoptions { "-fsanitize=address" }
		linkoptions { "-fsanitize=address" }
		if not os.istarget("macosx") then
			links { "asan" }
		end
	end

	if _OPTIONS["force-kqueue"] then
		defines { "EFSW_FSEVENTS_NOT_SUPPORTED" }
	end
end

function conf_links()
	if not os.istarget("windows") and not os.istarget("haiku") then
		links { "pthread" }
	end

	if os.istarget("macosx") then
		links { "CoreFoundation.framework", "CoreServices.framework" }
	end
end

function conf_excludes()
	if os.istarget("windows") then

		excludes { 
			"efsw/src/efsw/WatcherKqueue.cpp",
			"efsw/src/efsw/WatcherFSEvents.cpp",
			"efsw/src/efsw/WatcherInotify.cpp",
			"efsw/src/efsw/FileWatcherKqueue.cpp",
			"efsw/src/efsw/FileWatcherInotify.cpp",
			"efsw/src/efsw/FileWatcherFSEvents.cpp"
		}

	elseif os.istarget("linux") then

		excludes { 
			"efsw/src/efsw/WatcherKqueue.cpp",
			"efsw/src/efsw/WatcherFSEvents.cpp",
			"efsw/src/efsw/WatcherWin32.cpp", 
			"efsw/src/efsw/FileWatcherKqueue.cpp", 
			"efsw/src/efsw/FileWatcherWin32.cpp", 
			"efsw/src/efsw/FileWatcherFSEvents.cpp"
		}

	elseif os.istarget("macosx") then
		excludes { 
			"efsw/src/efsw/WatcherInotify.cpp", 
			"efsw/src/efsw/WatcherWin32.cpp", 
			"efsw/src/efsw/FileWatcherInotify.cpp", 
			"efsw/src/efsw/FileWatcherWin32.cpp" 
		}

	elseif os.istarget("bsd") then
		excludes { 
			"efsw/src/efsw/WatcherInotify.cpp", 
			"efsw/src/efsw/WatcherWin32.cpp", 
			"efsw/src/efsw/WatcherFSEvents.cpp", 
			"efsw/src/efsw/FileWatcherInotify.cpp", 
			"efsw/src/efsw/FileWatcherWin32.cpp", 
			"efsw/src/efsw/FileWatcherFSEvents.cpp" 
		}
	end
end

workspace "efsw"
	location("./make/" .. os.target() .. "/")
	targetdir("./bin")
	configurations { "debug", "release", "relwithdbginfo" }
	platforms { "x86_64", "x86", "ARM", "ARM64" }

	if os.istarget("windows") then
		osfiles = "efsw/src/efsw/platform/win/*.cpp"
	else
		osfiles = "efsw/src/efsw/platform/posix/*.cpp"
	end

	-- Activates verbose mode
	if _OPTIONS["verbose"] then
		defines { "EFSW_VERBOSE" }
	end

	cppdialect "C++11"

	objdir("obj/" .. os.target() .. "/")

	filter "platforms:x86"
		architecture "x86"

	filter "platforms:x86_64"
		architecture "x86_64"

	filter "platforms:arm"
		architecture "ARM"

	filter "platforms:arm64"
		architecture "ARM64"

	project "efsw-static-lib"
		kind "StaticLib"
		language "C++"
		targetdir("./lib")
		includedirs { "efsw/include", "efsw/src" }
		files { "efsw/src/efsw/*.cpp", osfiles }
		conf_excludes()

		filter "configurations:debug"
			defines { "DEBUG" }
			symbols "On"
			targetname "efsw-static-debug"
			conf_warnings()

		filter "configurations:release"
			defines { "NDEBUG" }
			optimize "On"
			targetname "efsw-static-release"
			conf_warnings()

		filter "configurations:relwithdbginfo"
			defines { "NDEBUG" }
			symbols "On"
			optimize "On"
			targetname "efsw-static-reldbginfo"
			conf_warnings()