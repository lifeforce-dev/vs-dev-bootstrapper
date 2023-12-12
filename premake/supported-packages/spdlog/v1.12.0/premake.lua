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
    local spdlog_json_package_dir = path.join(config.package_cache, project_key, spdlog_version)

    local include_dir = path.join("spdlog", "include")
    config.project_includes[project_key] = include_dir
    local source_dir = path.join("spdlog", "src")
    print("SPDLOG include dir:" .. path.join(spdlog_json_package_dir, include_dir))
    print("SPDLOG source dir" .. path.join(spdlog_json_package_dir, source_dir))

    files {

        path.join(spdlog_json_package_dir, include_dir, "**.h"),
        path.join(spdlog_json_package_dir, source_dir, "**.cpp")
    }
    
    includedirs { path.join(spdlog_json_package_dir, include_dir) }

    filter "system:windows"
        systemversion "latest"

    filter "configurations:Debug"
        defines { "DEBUG" }
        symbols "On"

    filter "configurations:Release"
        defines { "NDEBUG" }
        optimize "On"
