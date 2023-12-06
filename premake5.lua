-- premake5.lua for the solution located at sln_root/premake5.lua

local config = require "common_paths"

workspace "package_mgr_demo"
    architecture "x64"
    startproject "package_mgr_demo"

    configurations { "Debug", "Release" }

    -- TODO: Revisit this. Since my design has changed, this probably does not need to live
    -- in the package_cache anymore. 1) This should be generated and 2) leave in home repo.
    local spdlog_premake_script_path = path.join(config.package_cache, "config", "spdlog",
        "ac55e60488032b9acde8940a5de099541c4515da", "premake5.lua")

    -- Include the spdlog premake script to set up its project
    group "contrib"
        include(spdlog_premake_script_path)
    group ""

    -- Define user projects based on top-level directories in sln_dir/source/
    local source_dir = path.join(config.sln_dir, "source") -- No trailing slash needed

    -- Use a custom function to find all top-level directories in source_dir
    local function find_projects(src_path)
        local projects = {}
        local p = io.popen('dir "' .. src_path .. '" /b /ad') -- Assuming Windows
        for directory in p:lines() do
            table.insert(projects, directory)
        end
        p:close()
        return projects
    end

    -- Create projects for each top-level directory
    local projects = find_projects(source_dir)
    for _, project_name in ipairs(projects) do
        project (project_name)
            location (path.join(sln_dir, "build", "projects", "packages"))
            kind "ConsoleApp"
            language "C++"

            targetdir (config.bin_dir)
            objdir (path.join(config.obj_dir, project_name))

            -- Add all files from the project directory and subdirectories
            files {
                path.join(source_dir, project_name, "**.cpp"),
                path.join(source_dir, project_name, "**.h")
            }

            -- Reflect the directory structure in the project using vpaths
            vpaths {
                ["src/*"] = path.join(source_dir, project_name, "src", "**.cpp"),
                ["include/*"] = path.join(source_dir, project_name, "include", "**.h"),
                ["*"] = { path.join(source_dir, project_name, "*.cpp"), path.join(source_dir, project_name, "*.h") }
            }

            includedirs {
                path.join(source_dir, project_name, "include"),
                path.join(config.package_cache, "spdlog", "include")
            }

            links { "spdlog" }

            filter "configurations:Debug"
                defines { "DEBUG" }
                symbols "On"

            filter "configurations:Release"
                defines { "NDEBUG" }
                optimize "On"
    end