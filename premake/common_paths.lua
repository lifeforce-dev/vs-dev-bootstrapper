-- common_config.lua
newoption {
    trigger = "sln_dir",
    value = "PATH",
    description = "The path to the solution directory"
}

if not _OPTIONS["sln_dir"] then
    print ("Error: You must provide the root dir to your VS .sln")
    os.exit(1)
end

local package_cache = os.getenv("PACKAGE_CACHE_PATH")

local sln_dir = _OPTIONS["sln_dir"]

local base_build_dir = path.join(sln_dir, "build")
local bin_dir = path.join(base_build_dir, "bin", "%{cfg.buildcfg}")
local lib_dir = path.join(base_build_dir, "lib", "%{cfg.buildcfg}")
local obj_dir = path.join(base_build_dir, "obj", "%{cfg.buildcfg}")

return {
    package_cache = package_cache,
    sln_dir = sln_dir,
    base_build_dir = base_build_dir,
    bin_dir = bin_dir,
    lib_dir = lib_dir,
    obj_dir = obj_dir
}
