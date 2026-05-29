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
			"src/efsw/WatcherKqueue.cpp",
			"src/efsw/WatcherFSEvents.cpp",
			"src/efsw/WatcherInotify.cpp",
			"src/efsw/FileWatcherKqueue.cpp",
			"src/efsw/FileWatcherInotify.cpp",
			"src/efsw/FileWatcherFSEvents.cpp"
		}

	elseif os.istarget("linux") then

		excludes { 
			"src/efsw/WatcherKqueue.cpp",
			"src/efsw/WatcherFSEvents.cpp",
			"src/efsw/WatcherWin32.cpp", 
			"src/efsw/FileWatcherKqueue.cpp", 
			"src/efsw/FileWatcherWin32.cpp", 
			"src/efsw/FileWatcherFSEvents.cpp"
		}

	elseif os.istarget("macosx") then
		excludes { 
			"src/efsw/WatcherInotify.cpp", 
			"src/efsw/WatcherWin32.cpp", 
			"src/efsw/FileWatcherInotify.cpp", 
			"src/efsw/FileWatcherWin32.cpp" 
		}

	elseif os.istarget("bsd") then
		excludes { 
			"src/efsw/WatcherInotify.cpp", 
			"src/efsw/WatcherWin32.cpp", 
			"src/efsw/WatcherFSEvents.cpp", 
			"src/efsw/FileWatcherInotify.cpp", 
			"src/efsw/FileWatcherWin32.cpp", 
			"src/efsw/FileWatcherFSEvents.cpp" 
		}
	end
end

project "efsw"
	kind "StaticLib"
	language "C++"
	targetdir("./lib")
	includedirs { "include", "src" }

	if os.istarget("windows") then
		osfiles = "src/efsw/platform/win/*.cpp"
	else
		osfiles = "src/efsw/platform/posix/*.cpp"
	end

	files { "src/efsw/*.cpp", osfiles }
	conf_excludes()

	filter "configurations:debug"
		defines { "DEBUG" }
		symbols "On"
		optimize "off"
		conf_warnings()
	filter ""

	filter "configurations:release"
		defines { "NDEBUG" }
		symbols "off"
		optimize "on"
		conf_warnings()
	filter ""
