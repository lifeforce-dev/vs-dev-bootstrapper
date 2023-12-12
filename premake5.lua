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

print("working dir" .. os.getcwd())

-- Try and pick an intelligent startup project if one exists.
local function determine_startup_project(projects, default_name)
    -- Check if a project with the same name as the workspace exists
    for _, project_name in ipairs(projects) do
        if project_name == default_name then
            return project_name
        end
    end
    
    -- If the workspace-named project was not found,
    -- return the first project in the list, if available
    return #projects > 0 and projects[1] or nil
end


-- Returns a list of dirs to be treated as .vcxproj dirs.
local function find_projects(src_path)
    local projects = {}
    local p = io.popen('dir "' .. src_path .. '" /b /ad')
    for directory in p:lines() do
        table.insert(projects, directory)
    end
    p:close()
    return projects
end

-- Top level directories in this dir will be treated as the root for a .vcxproj.
local source_dir = path.join(config.sln_dir, "source")

-- Retrieve the list of projects
local projects = find_projects(source_dir)

-- Determine the startup project
local startup_project = determine_startup_project(projects, _OPTIONS["sln_name"])

workspace (_OPTIONS["sln_name"])

    architecture "x64"
    if startup_project then
        startproject (startup_project)
    end


    configurations { "Debug", "Release" }

    print("Populating contrib...")
    group "contrib"
    for name, pkg in pairs(package_info.packages) do
        local premake_script_path = path.join(config.sln_dir, "premake/supported-packages",
                                              name, pkg.version, "premake.lua")
        print("Attempting to load premake script"..
              " name=" .. name .. 
              " path=" .. premake_script_path)
        include(premake_script_path)
    end
    group ""

    -- The .vcxproj filters will be setup identical to the folder structure of its root dir.
    for _, project_name in ipairs(projects) do
        project (project_name)
            location (path.join(sln_dir, "build", "projects", "packages"))
            kind "ConsoleApp"
            language "C++"

            targetdir (config.bin_dir)
            objdir (path.join(config.obj_dir, project_name))

            files {
                path.join(source_dir, project_name, "**.cpp"),
                path.join(source_dir, project_name, "**.h")
            }

            -- Handle includes for user source.
            local project_includedirs = { path.join(source_dir, project_name, "include") }

            -- Handle includes for packages.
            for pkg_name, pkg_details in pairs(package_info.packages) do
                print("pkg_name" .. pkg_name)
                local pkg_include_dir = config.project_includes[pkg_name]
                print("PACKAGE_INCLUDE_DIR" .. pkg_include_dir)
                local include_dir = path.join(config.package_cache, pkg_name, pkg_details.version,
                                              pkg_include_dir)
                table.insert(project_includedirs, path.join(config.package_cache, include_dir))
            end

            includedirs(project_includedirs)

            -- Handle linking packages
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
