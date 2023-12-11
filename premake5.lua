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

workspace (_OPTIONS["sln_name"])

    architecture "x64"
    startproject "package_mgr_demo"

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
    -- Top level directories in this dir will be treated as the root for a .vcxproj.
    local source_dir = path.join(config.sln_dir, "source")

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

    -- The .vcxproj filters will be setup identical to the folder structure of its root dir.
    local projects = find_projects(source_dir)
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
                local include_dir = path.join(config.package_cache, pkg_name, pkg_details.version,
                                               pkg_details.include_dir)
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
