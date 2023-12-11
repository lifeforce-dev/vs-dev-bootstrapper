import dearpygui.dearpygui as dpg
from enum import Enum
from pathlib import Path
import configparser
from tkinter import filedialog, Tk
import json
import os

#TODO: When we clone, we need to clone into package_cache/package_key_name/version/
from git_helper import GitHelper

SLN_DIR = Path(os.path.dirname(os.path.abspath(__file__))).parent
PACKAGE_STORE_PATH = SLN_DIR / 'premake' / 'package_store.json'
DEPENDENCIES_PATH = SLN_DIR / 'dependencies.json'

# UI defaults
NO_OUTPUT_DIR_SELECTED_TEXT = "Choose sln output dir..."

class Mode(Enum):
    CREATE_NEW = 1,
    UPDATE = 2


class SolutionNameMissingException(Exception):
    def __init__(self, message="Solution name cannot be empty"):
        self.message = message
        super().__init__(self.message)


class PackageSelectorGUI:
    def __init__(self):
        self.selected_packages = set()
        self.solution_name = ""
        self.checkboxes = {}
        self.dropdowns = {}
        self.window_id = None
        self.output_dir_label_id = None
        self.dependencies = {}
        self.package_store = {}
        self.mode = Mode.CREATE_NEW
        self.output_dir = ""
        self.create_gui()


    def load_package_store(self):
        try:
            with open(PACKAGE_STORE_PATH, encoding='utf-8') as file:
                self.package_store = json.load(file)['package_store']
        except FileNotFoundError:
            self.package_store = {}


    def load_dependencies(self):
        try:
            with open(DEPENDENCIES_PATH, encoding='utf-8') as file:
                self.dependencies = json.load(file)
        except FileNotFoundError:
            self.dependencies = {}


    def initialize(self):
        config_parser = configparser.ConfigParser()
        config_parser.read(SLN_DIR/'settings.ini')

        mode_str = config_parser.get('DEFAULT', 'mode', fallback="GENERATE")
        self.mode = Mode[mode_str]
        # If mode is UPDATE we don't care about output_dir because we only operate in current dir.
        if self.mode == Mode.CREATE_NEW:
            self.output_dir = config_parser.get('DEFAULT', 'output_dir',
                                                fallback= NO_OUTPUT_DIR_SELECTED_TEXT)

        self.load_package_store()
        self.load_dependencies()


    def create_gui(self):
        self.initialize()
        self.window_id = dpg.add_window(label="Package Selector", no_scrollbar=True,
                                        menubar=False, no_resize=True, no_move=True)
        with dpg.window(id=self.window_id):

            # Output dir select button
            if self.mode == Mode.CREATE_NEW:
                with dpg.group(horizontal=True):
                    dpg.add_button(label="Browse", callback=self.on_choose_output_dir)

                    check_1 = self.output_dir.strip(' "') != ""
                    # Current output dir label
                    self.output_dir_label_id = dpg.add_text(
                        self.output_dir if self.output_dir.strip(' "') != "" else NO_OUTPUT_DIR_SELECTED_TEXT)

                # Solution name Edit box
                self.solution_name_id = dpg.add_input_text(hint="Enter Solution Name")
                dpg.set_item_callback(self.solution_name_id, self.on_solution_text_changed)

            dpg.add_text("Packages")
            # Package Items
            for package_name, package_info in self.package_store.items():
                with dpg.group(horizontal=True):
                    # Checkbox
                    checkbox_id = dpg.add_checkbox(label=package_name,
                                                   callback=self.on_checkbox_checked,
                                                   user_data=package_name)
                    self.checkboxes[checkbox_id] = package_name

                    is_checked = package_name in self.dependencies
                    dpg.set_value(checkbox_id, is_checked)

                    # Dropdown
                    dropdown_id = dpg.add_combo(package_info['versions'],
                                                default_value=self.dependencies.get(package_name, package_info['versions'][0]),
                                                user_data=package_name,
                                                callback=self.on_dropdown_changed)
                    self.dropdowns[dropdown_id] = package_name

            # Generate Button or Update Button
            self.create_execute_button()


    def create_execute_button(self):
        if self.mode == Mode.CREATE_NEW:
            self.generate_button_id = dpg.add_button(label="Generate", callback=self.on_generate_clicked)
            dpg.disable_item(self.generate_button_id)

            dpg.set_item_user_data(self.solution_name_id, self.generate_button_id)

        elif self.mode == Mode.UPDATE:
            dpg.add_button(label="Update", callback=self.on_update_clicked)


    def on_choose_output_dir(self, sender, app_data, user_data):
        root = Tk()
        directory = filedialog.askdirectory()
        root.destroy()
        # update directory if we picked one
        if directory:
            self.output_dir = directory
            config_parser = configparser.ConfigParser()
            config_parser.read(SLN_DIR / 'settings.ini')
            config_parser.set('DEFAULT', 'output_dir', directory)
            with open(SLN_DIR / 'settings.ini', 'w', encoding='utf-8') as config_file:
                config_parser.write(config_file)
            dpg.set_value(self.output_dir_label_id, directory)


    def on_dropdown_changed(self, sender, app_data, user_data):
        self.update_dependencies()


    def on_checkbox_checked(self, sender, app_data, user_data):
        package = user_data
        check_state_str = "Checked" if app_data else "Unchecked"
        print(f"{check_state_str} {package}")
        if app_data:
            self.selected_packages.add(package)
        else:
            self.selected_packages.discard(package)

        self.update_dependencies()


    def on_update_clicked(self, sender, app_data, user_data):
        """
        Basically we just make sure the package repos exist and rerun premake here.
        """
        print("running premake")


    def on_generate_clicked(self, sender, app_data, user_data):
        """
        TODO:
        So, what's gonna happen here is generate button is only available
        when the script is run in "Generate" mode. This is basically only
        when you're running from the repository for the simple-package-manager.
        This mode is specified by a .ini file.

        Once the user presses "generate", the ini file will get created in the destination
        and the mode will be "Update". In this mode, an Update button will be there in place
        of the Generate button. The user can still add/remove/modify their dependencies,
        but everything happens in place in that solution rather than generating a new one.
        """
        self.solution_name = dpg.get_value(self.solution_name_id)
        try:
            if not self.solution_name.strip():
                raise SolutionNameMissingException
        
        except SolutionNameMissingException as e:
            print(e)
        print (self.solution_name)


    def on_solution_text_changed(self, sender, app_data, user_data):
        self.solution_name = dpg.get_value(sender)
        if self.solution_name.strip():
            dpg.enable_item(user_data)
        else:
            dpg.disable_item(user_data)


    def update_dependencies(self):
        # This is the simplest and least error-prone way to update our depdencies.
        # Is it the most efficient? No, but we're talking about dozens of dependencies at most.
        updated_dependencies = {}
        for checkbox_id, package_name in self.checkboxes.items():
            if dpg.get_value(checkbox_id):  # Check if the checkbox is checked
                dropdown_id = next(key for key, value in self.dropdowns.items() if value == package_name)
                dropdown_value = dpg.get_value(dropdown_id)
                updated_dependencies[package_name] = dropdown_value

        # Update the dependencies file
        with open(SLN_DIR / 'dependencies.json', 'w', encoding='utf-8') as file:
            json.dump(updated_dependencies, file, indent=4)


def main():
    dpg.create_context()
    gui = PackageSelectorGUI()

    dpg.create_viewport(title='Package Selector', width=600, height=300)
    dpg.setup_dearpygui()

    if gui.window_id is not None:
        dpg.set_primary_window(gui.window_id, True)

    disabled_color = (0.50 * 255, 0.50 * 255, 0.50 * 255, 1.00 * 255)
    disabled_button_color = (45, 45, 48)
    disabled_button_hover_color = (45, 45, 48)
    disabled_button_active_color = (45, 45, 48)

    with dpg.theme() as disabled_theme:
        with dpg.theme_component(dpg.mvButton, enabled_state=False):
            dpg.add_theme_color(dpg.mvThemeCol_Text, disabled_color, category=dpg.mvThemeCat_Core)
            dpg.add_theme_color(dpg.mvThemeCol_Button, disabled_button_color, category=dpg.mvThemeCat_Core)
            dpg.add_theme_color(dpg.mvThemeCol_ButtonHovered, disabled_button_hover_color, category=dpg.mvThemeCat_Core)
            dpg.add_theme_color(dpg.mvThemeCol_ButtonActive, disabled_button_active_color, category=dpg.mvThemeCat_Core)

        dpg.bind_theme(disabled_theme)

    dpg.show_viewport()
    dpg.start_dearpygui()
    dpg.destroy_context()

if __name__ == "__main__":
    main()
