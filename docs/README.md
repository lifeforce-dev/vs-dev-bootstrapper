# vs-dev-bootstrapper

## What this project is NOT intended for
- Use as a general package manager. If all you want is a **robust fully featured package manager for premier packages**, I strongly suggest using [vcpkg](https://vcpkg.io/en/)
- Cross platform package management. This is windows only, MSVC only
- Detailed customization, such as creating a vcxproj and controlling exactly which of the many dependencies you want it to know about, etc.
- Production code for large projects or "real" code bases that require a more advance and flexible build system

## You should use this if
- You want a consistent, sane, easy organization of your own user-created src files/projects/etc across all slns you create
- You want to be able to create said sln with the click of a button, pulling down all dependencies from their github repos, and hooking them all up properly
- You want creating new vcxprojs and filters within your sln to be as simple as adding code to the `Source/` dir

## Table of Contents
- [Setup](#setup)
- [Creating Your Solution Dir](#creating-your-solution-dir)
- [Generating the C++ solution file](#generating-C-solution-file)
- [Adding Your Own Source Code to the VS Solution](#adding-your-own-source-code-to-the-vs-solution)
- [Creating Your Own Local Static Library](#creating-your-own-local-static-library)

## Setup
- Create an environment variable called `PACKAGE_CACHE_PATH` and set its value to the directory that you want dependencies downloaded to
- Make sure you have Python 3.11+ installed
- `pip install dearpygui`
- Make sure git is in your `Path` environment variable (`C:/Program Files/Git/cmd` is a common location)

## Creating Your Solution Dir
Run `bootstrapper.py` which will bring up the UI

![UI](https://i.imgur.com/YoAYH7F.png)

- Browse to where you want the Solution to generate
- Give the VS Solution a name
- Select your packages that you want and the version that you want them in
- Click `Generate`

## Generating the C++ solution file
- Navigate to where you generated the solution
- Navigate to `<your_sln_name>/Source/` and add some code, see "Adding your own src code" section to learn how.
  
- Double click `run_package_manager.bat`. This will open the same UI but in `Update mode` with a console window for log viewing
  ![UI](https://i.imgur.com/doevEp7.png)
- Click `Update`
- Your `.sln` file should be created in the root dir, you're now all set!

## Adding your own source code to the VS solution
- Your source code goes in `<your_sln_name>/Source`
- Top level directories in this folder will become projects of the same name within the solution file
-- Directories inside will be added as vpaths in your project file so that your VS projects mirror your folder structure.
-- All .cpp/.h files are added to its respective project
- All dependencies selected by the package manager will be hooked up for use in all projects
![UI](https://i.imgur.com/dYNUEB0.gif)

## Creating your own local static library
- In the `<your_sln_name>/Source` dir create a folder called `_static`
- The rules inside this folder are the same as the ones in `Source`. Top level dirs become projects, etc
- It will be treated as a dependency in `contrib` and will be hooked up to all projects so they are ready to use it

## Building
- To build the .sln you just finished generating, simply open in Visual Studio and hit build
- output libs and binaries are all organized in your build folder in their respective configurations
![UI](https://i.imgur.com/3zbZMDG.gif)

## Including contrib packages in your projects

- From any project you should be able to access selected packages by including them like so:

```
#include <glm/glm.hpp>
#include <nlohmann/json.hpp>
#include <asio.hpp>
#include <spdlog/spdlog.h>
#include <catch2/catch.hpp>
```
