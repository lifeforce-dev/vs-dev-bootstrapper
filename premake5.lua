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
    local found_files = os.matchfiles(path.join(dir, "**"))
    local dirs = os.matchdirs(path.join(dir, "**"))

    -- Correctly call the global files function
    files(found_files)
    vpaths({ ["*"] = { dir .. "/" .. "**" } })  -- Maps files to their respective directory paths

    -- Add all directories to the include directories
    includedirs(dirs)

    for _, d in ipairs(dirs) do
        recursiveAddFiles(d)
    end
end

local source_dir = path.join(config.sln_dir, "source")
local projects = os.matchdirs(path.join(source_dir, "*"))

workspace (_OPTIONS["sln_name"])
    architecture "x64"

    configurations { "Debug", "Release" }

    print("Populating contrib...")
    group "contrib"
    for name, pkg in pairs(package_info.packages) do
        local premake_script_path = path.join(config.sln_dir, "premake/supported-packages",
                                              name, pkg.version, "premake.lua")
        print("Attempting to load premake script name=" .. name .. 
              " path=" .. premake_script_path)
        include(premake_script_path)
    end
    group ""

    print("Checking configuration for all packages...")
    for pkg_name, _ in pairs(package_info.packages) do
        local include_dir = config.project_includes[pkg_name]
        if not include_dir then
            print("Error: No include directory specified for package: " .. pkg_name)
        else
            print("Include directory for " .. pkg_name .. ": " .. include_dir)
        end
    end

    for _, project_dir in ipairs(projects) do
        local project_name = path.getname(project_dir)
        project(project_name)
            location(path.join(config.sln_dir, "build", "projects", "packages"))
            kind "ConsoleApp"
            language "C++"

            targetdir(config.bin_dir)
            objdir(path.join(config.obj_dir, project_name))

            recursiveAddFiles(project_dir)

            local project_includedirs = {}
            for pkg_name, pkg_details in pairs(package_info.packages) do
                print("Package Name: " .. pkg_name)
                local pkg_include_dir = config.project_includes[pkg_name]
                if pkg_include_dir == nil then
                    print("Error: Include directory not found for package: " .. pkg_name)
                else
                    print("Package Include Directory: " .. pkg_include_dir)
                    local include_dir = path.join(config.package_cache, pkg_name, pkg_details.version, pkg_include_dir)
                    table.insert(project_includedirs, path.join(config.package_cache, include_dir))
                end
            end

            includedirs(project_includedirs)

            local project_links = {}
            for name, pkg in pairs(package_info.packages) do
                table.insert(project_links, name)
            end

            links(project_links)

            staticruntime "on"
            filter "configurations:Debug"
                defines { "DEBUG" }
                symbols "On"
                runtime "Debug"

            filter "configurations:Release"
                defines { "NDEBUG" }
                optimize "On"
                runtime "Release"
end