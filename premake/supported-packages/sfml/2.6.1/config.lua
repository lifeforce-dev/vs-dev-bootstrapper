local config = require "common_paths"
local package_info = require "package_info"

local project_key = "sfml"
local sfml_version = package_info.packages[project_key].version
-- TODO: Fixing this fixes everything:
-- This path needs to point to C:\package_cache\sfml\2.6.1\sfml\build\lib\<Debug/Release>
-- Need to add the debug dlls when config set to debug
-- need to point to C:\package_cache\sfml\2.6.1\sfml\extlibs\libs-msvc\x64 for external .libs (vorbis, freetype, etc)
local sfml_ext_lib_dir = path.join(config.package_cache, project_key, sfml_version, project_key, "extlibs", "libs-msvc-universal", "x64")
local sfml_lib_dir = path.join(config.package_cache, project_key, sfml_version, project_key, "build", "lib", "%{cfg.buildcfg}")
-- C:\package_cache\sfml\2.6.1\sfml\include
local sfml_include_dir = path.join(config.package_cache, project_key, sfml_version, project_key, "include")
    location (path.join(config.sln_dir, "build", "projects", "packages"))

    targetdir (config.lib_dir)
    print("Output directory for SFML: " .. config.lib_dir)
    objdir (path.join(config.obj_dir, project_key))

    -- SFML Version and Library Directory

    -- User-selected SFML modules
    local sfml_modules = package_info.packages.sfml.modules

    -- SFML module to library mapping
    local sfml_dependencies = {
        graphics = {
            "sfml-graphics-s",
            "sfml-window-s",
            "sfml-system-s",
            "opengl32",
            "freetype"
        },
        window = {
            "sfml-window-s",
            "sfml-system-s",
            "opengl32",
            "winmm",
            "gdi32"
        },
        system = {
            "sfml-system-s",
            "winmm"
        },
        audio = {
            "sfml-audio-s",
            "sfml-system-s",
            "openal32",
            "flac",
            "vorbisenc",
            "vorbisfile",
            "vorbis",
            "ogg"
        },
        network = {
            "sfml-network-s",
            "sfml-system-s",
            "ws2_32"
        }
    }

    
local external_package_config = {}

function external_package_config.get_defines()
    return {"SFML_STATIC"}
end

local include_dirs = {}
local lib_dirs = {}
function external_package_config.get_dependencies()
    -- User-selected SFML modules
    local sfml_modules = package_info.packages.sfml.modules
    local is_debug = false
    
    filter { "configurations:Debug" }
        is_debug = true
    filter {}

    -- Collect the libraries to link based on user selection
    local sfml_links = {}
    for _, module in ipairs(sfml_modules) do
        local deps = sfml_dependencies[module]
        if deps then
            for _, lib in ipairs(deps) do
                if string.find(lib, "sfml") then
                    lib = is_debug and (lib .. "-d") or lib
                end
                print("Evaluating SFML lib=" .. lib .. "is_debug" .. tostring(is_debug))
                if not table.contains(sfml_links, lib) then
                    table.insert(sfml_links, lib)
                end
            end
        end
    end

    table.insert(lib_dirs, sfml_lib_dir)
    table.insert(lib_dirs, sfml_ext_lib_dir)

    -- Return the list of libraries and the library directory
    return sfml_links, lib_dirs, sfml_include_dir
end

return external_package_config