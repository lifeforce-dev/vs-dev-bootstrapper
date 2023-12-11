# simple-package-manager
I just want to be able to fetch libraries I commonly use and generate VS .sln/project files with everything hooked up. Premake doesn't do most of this without a significant amount of custom work anyway.

EDIT: I would just like to apologize to premake, this is actually a hard problem and I'll probably just use premake for making the sln/project files.

Motivation:
This is not even attempting to be a "general package manager". I find myself creating new projects frequently, usually to solve leet-code/hacker-rank problems, simple projects, or other toy problems. For these, I develop exclusively for windows, and in the end, this was built for my needs.

But if you too only develop on windows and use some of these packages then this should work for you too!

Usage:

Creating a new .sln
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

Adding Package support:
- Create a premake file and place it in the appropriate director <supported_packages>/<package_name>/<version>/premake
- Add an entry to the package_store.json

Now when you run the package-manager, it should appear in the list.
NOTE: Ensure the key name matches the folder root name so premake hooks everything up properly (follow the other patterns for the package_cache)
