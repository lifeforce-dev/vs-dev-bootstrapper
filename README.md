# simple-package-manager

Usage:

**Creating a new .sln**
- Just run "start-package-manager.bat"
- Select the output dir that your new .sln/project will be generated in.
- Name the .sln using the edit box
- Select the packages you want
- Click generate

Updating dependencies on a current.sln
- Just run "start-package-manager.bat"
- Make your modifications
- Click Update

That's all there is to it.

**Adding Package support:**
- Create a premake file and place it in the appropriate director <supported_packages>/<package_name>/<version>/premake
- Add an entry to the package_store.json

Now when you run the package-manager, it should appear in the list.
NOTE: Ensure the key name matches the folder root name so premake hooks everything up properly (follow the other patterns for the package_cache)

**Adding your own .vcxproj files for your own code**
- Simply create a folder named what you want your project to be called in the Source folder. `sln_root/Source/<project_name>/`
- Run the package manager and click update

Premake will treat all root folders in "Source" as a .vcxproj and add all source files within that folder to the filters for said .vcxproj (maintaining the same folder structure)
