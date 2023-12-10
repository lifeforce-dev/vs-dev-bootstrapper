local config = require "common_paths"
local package_info = require "package_info"

local sln_dir = _OPTIONS["sln_dir"]
local project_key = "spdlog"
project (project_key)
    kind "StaticLib"
    language "C++"
    cppdialect "C++17"
    staticruntime "On"

    defines { "SPDLOG_COMPILED_LIB" }

    location (path.join(config.sln_dir, "build", "projects", "packages"))

    targetdir (config.lib_dir)
    print("Output directory for spdlog: " .. config.lib_dir)
    objdir (path.join(config.obj_dir, project_key))

    local spdlog_version = package_info.packages[project_key].version
    print(path.join(config.package_cache, project_key, spdlog_version, project_key, "include"))
    print(path.join(config.package_cache, project_key, spdlog_version, project_key, "src"))

    files {

        path.join(config.package_cache, project_key, spdlog_version, project_key, "include", "**.h"),
        path.join(config.package_cache, project_key, spdlog_version, project_key, "src", "**.cpp")
    }
    
    includedirs { path.join(config.package_cache, project_key, spdlog_version, project_key, "include") }

    filter "system:windows"
        systemversion "latest"

    filter "configurations:Debug"
        defines { "DEBUG" }
        symbols "On"

    filter "configurations:Release"
        defines { "NDEBUG" }
        optimize "On"
