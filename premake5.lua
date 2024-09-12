local config = require "common_paths"
local package_info = require "package_info"

newoption {
    trigger = "sln_name",
    value = "NAME",
    description = "The name of the solution"
}

if not _OPTIONS["sln_name"] then
    print("Error: You must provide a solution name.")
    os.exit(1)
end

print("Working directory: " .. os.getcwd())

local function recursiveAddFiles(dir)
    files { path.join(dir, "**.cpp"), path.join(dir, "**.h") }
    vpaths { ["*"] = { dir .. "/**" } }
    includedirs { dir }
end

-- Folders in here will be treated as projects that should be built as static libs.
-- The folder structure is the same, where _static/<project_name> just as source/<project_name>
-- Currently, all projects will depend on any static lib made in here. Its meant for having something
-- like a "common" lib. Perhaps in the future I'll add more control, for now static libs are global.
local static_folder_name = "_static"
local source_dir = path.join(config.sln_dir, "source")
local static_dir = path.join(source_dir, "_static")
local static_lib_dirs = os.matchdirs(path.join(static_dir, "*")) -- Get all directories in 'static'

workspace (_OPTIONS["sln_name"])
architecture "x64"
configurations { "Debug", "Release" }
cppdialect "C++20"
disablewarnings { "4996" }

print("Creating contrib filter...")

-- These are packages that are not included with the binary, but instead exist outside
-- of the project and are simply referenced by other projects.
local external_packages = {}
group "contrib"
for pkg_name, pkg in pairs(package_info.packages) do
    if pkg.include_in_build == true then
        local premake_script_path = path.join(config.sln_dir,
            "premake/supported-packages", pkg_name, pkg.version, "premake.lua")
        include(premake_script_path)
    elseif pkg.include_in_build == false then
        print("Handling " .. pkg_name .. " as an external package.")

        local config_script_path = path.join(config.sln_dir,
            "premake/supported-packages", pkg_name, pkg.version, "config.lua")
        print("Loading config script at ".. config_script_path)
        table.insert(external_packages, {
            name = pkg_name,
            path = config_script_path
        })
    end
end
group ""



-- Collect directories from contrib packages
local contrib_includes = {}
local contrib_links = {}
local contrib_lib_dirs = {}
local contrib_defines = {}
print("Gathering external package info...")
for _, external_package in pairs(external_packages) do
    pkg_name = external_package.name
    config_path = external_package.path
    print("External Package Config Path="..external_package.path)
    local config = dofile(config_path)
    if type(config.get_dependencies) == "function" then
        local links, lib_dirs, include_dir = config.get_dependencies()
        if include_dir then
            table.insert(contrib_includes, include_dir)
            print("External Package Inlcudes  Added" .. include_dir)
        end
        if links then
            print("External Package Links Added" .. table.concat(links, ", "))
            table.insert(contrib_links, links)
        end
        if lib_dirs then
            print("External package ext lib dirs added" .. table.concat(lib_dirs, ", "))
            table.insert(contrib_lib_dirs, lib_dirs)
        end
    else
        error("Config for package " .. pkg_name .. " does not implement get_dependencies.")
    end
    if type(config.get_defines) == "function" then
        local defines = config.get_defines()
        if defines and type(defines) == "table" then
            print("External package defines added: " .. table.concat(defines, ", "))
            for _, define in ipairs(defines) do
                table.insert(contrib_defines, define)
            end
        end
    else
        error("Config for package " .. pkg_name .. " does not implement get_defines")
    end
end

table.insert(contrib_defines, "_CRT_SECURE_NO_WARNINGS")

print("Gathering list of contrib includes...")

for pkg_name, pkg in pairs(package_info.packages) do
    if pkg.include_in_build and config.project_includes[pkg_name] then
        table.insert(contrib_includes, config.project_includes[pkg_name])
        -- Print the directory being added to the include path
        print("Adding include directory for package '" .. pkg_name .. "': " .. config.project_includes[pkg_name])
    end
end

-- Set up static libraries
for _, lib_dir in ipairs(static_lib_dirs) do
    local lib_name = path.getname(lib_dir)
    project(lib_name)
    kind "StaticLib"
    language "C++"
    location(path.join(config.sln_dir, "build", "projects", "packages"))
    targetdir(config.lib_dir)
    objdir(path.join(config.obj_dir, lib_name))
    includedirs(static_dir)
    includedirs(contrib_includes)
    recursiveAddFiles(lib_dir)
end

-- Set up other projects excluding static libraries
local projects = os.matchdirs(path.join(source_dir, "*"))
for _, project_dir in ipairs(projects) do
    local project_name = path.getname(project_dir)

     -- Skip static lib directories
    if project_name ~= "_static" then
        project(project_name)
        kind "ConsoleApp"
        language "C++"
        location(path.join(config.sln_dir, "build", "projects", "packages"))
        targetdir(config.bin_dir)
        objdir(path.join(config.obj_dir, project_name))

          -- Include directory for all static libs
        includedirs(static_dir)
        includedirs(contrib_includes)
        recursiveAddFiles(project_dir)
        
        for _, lib_dir in ipairs(contrib_lib_dirs) do
            libdirs{lib_dir}
        end

        -- Link all static libraries
        for _, static_lib_dir in ipairs(static_lib_dirs) do
            table.insert(contrib_links, path.getname(static_lib_dir))
        end

        for _, link_name in ipairs(contrib_links) do
            links{ link_name }
        end
    end
end

defines{contrib_defines}

filter "configurations:Debug"
    defines { "DEBUG" }
    symbols "On"
    runtime "Debug"
    staticruntime "On"

filter "configurations:Release"
    defines { "NDEBUG" }
    optimize "On"
    runtime "Release"
    staticruntime "On"
