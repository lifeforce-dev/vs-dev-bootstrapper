-- premake5.lua for spdlog located at package_cache/config/spdlog/<hash>/premake5.lua

local config = require "common_paths"

local sln_dir = _OPTIONS["sln_dir"]

project "spdlog"
    kind "StaticLib"
    language "C++"
    cppdialect "C++17"
    staticruntime "On"

    defines { "SPDLOG_COMPILED_LIB" }

    location (path.join(config.sln_dir, "build", "projects", "packages"))

    targetdir (config.lib_dir)
    objdir (path.join(config.obj_dir, "spdlog"))

    files {
        path.join(config.package_cache, "spdlog", "include", "**.h"),
        path.join(config.package_cache, "spdlog", "src", "**.cpp")
    }
    
    includedirs { path.join(config.package_cache, "spdlog", "include") }

    filter "system:windows"
        systemversion "latest"

    filter "configurations:Debug"
        defines { "DEBUG" }
        symbols "On"

    filter "configurations:Release"
        defines { "NDEBUG" }
        optimize "On"