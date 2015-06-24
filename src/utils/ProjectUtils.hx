package utils;

import massive.sys.io.FileSys;
import utils.CommandUtils;
import utils.TemplateUtils;
import utils.TemplateUtils.TemplateReplacement;
import massive.sys.cmd.Console;

class ProjectUtils
{
	/**
	 * Shortcut Create an OpenFL project by recursively copying the folder according to a name
	 *
	 * @param   Name	The name of the demo to create
	 */
	static public function duplicateProject(Project:OpenFLProject, Destination:String = "", IDE:String = ""):Bool
	{
		var result = CommandUtils.copyRecursively(Project.PATH, Destination);

		if (result)
		{
			CommandUtils.copyRecursively(Project.PATH, Destination);

			var replacements = new Array<TemplateReplacement>();
			replacements.push(TemplateUtils.addOption("${PROJECT_NAME}", "", Project.NAME));
			replacements = copyIDETemplateFiles(Destination, replacements, IDE);

			TemplateUtils.modifyTemplate(Destination, replacements);
		}
		return result;
	}

	/**
	 * Scan a Directory recursively for OpenFL projects
	 * @return An Array containing projects with an XML specified
	 */
	static public function scanOpenFLProjects(TargetDirectory:String, recursive:Bool = true):Array<OpenFLProject>
	{
		var projects = new Array<OpenFLProject>();

		if (FileSys.exists(TargetDirectory))
		{
			for (name in FileSys.readDirectory(TargetDirectory))
			{
				var folderPath:String = CommandUtils.combine(TargetDirectory, name);

				if (FileSys.isDirectory(folderPath) && !StringTools.startsWith(name, "."))
				{
					var projectPath = scanProjectXML(folderPath);

					if (projectPath != "")
					{
						projects.push({
							NAME : name,
							PATH : folderPath,
							PROJECTXMLPATH : projectPath,
							TARGETS : ""
						});
					}

					var subProjects = scanOpenFLProjects(folderPath);
					if (subProjects.length>0)
					{
						for (o in subProjects)
						{
							projects.push(o);
						}
					}
				}
			}
		}
		return projects;
	}

	/**
	 * Scans a path for OpenFL project.xml
	 */
	static private function scanProjectXML(ProjectPath:String):String
	{
		var targetProjectFile = CommandUtils.combine(ProjectPath, "project.xml");

		if (FileSys.exists(targetProjectFile))
		{
			return targetProjectFile;
		}

		targetProjectFile = CommandUtils.combine(ProjectPath, "Project.xml");
		if (FileSys.exists(targetProjectFile))
		{
			return targetProjectFile;
		}
		return "";
	}

	static public function copyIDETemplateFiles(TargetPath:String, ?Replacements:Array<TemplateReplacement>, IDEOption:String = ""):Array<TemplateReplacement>
	{
		if (Replacements == null)
			Replacements = new Array<TemplateReplacement>();

		Replacements.push(TemplateUtils.addOption("${AUTHOR}", "", FlxTools.settings.AuthorName));

		if (IDEOption == "" && FlxTools.settings.IDEAutoOpen)
		{
			IDEOption = FlxTools.settings.DefaultEditor;
		}
		else if (IDEOption == "")
		{
			IDEOption = FlxTools.IDE_NONE;
		}

		if (IDEOption == FlxTools.SUBLIME_TEXT)
		{
			Replacements.push(TemplateUtils.addOption("${PROJECT_PATH}", "", StringTools.replace(TargetPath, '\\', '\\\\')));
			Replacements.push(TemplateUtils.addOption("${HAXE_STD_PATH}", "", StringTools.replace(CommandUtils.combine(CommandUtils.getHaxePath(), "std"), '\\', '\\\\')));
			Replacements.push(TemplateUtils.addOption("${FLIXEL_PATH}", "", StringTools.replace(CommandUtils.getHaxelibPath('flixel'), '\\', '\\\\')));
			Replacements.push(TemplateUtils.addOption("${FLIXEL_ADDONS_PATH}", "", StringTools.replace(CommandUtils.getHaxelibPath('flixel-addons'), '\\', '\\\\')));

			CommandUtils.copyRecursively(FlxTools.sublimeSource, TargetPath, TemplateUtils.TemplateFilter, true);
		}
		else if (IDEOption == FlxTools.INTELLIJ_IDEA)
		{
			Replacements.push(TemplateUtils.addOption("${IDEA_flexSdkName}", "", FlxTools.settings.IDEA_flexSdkName));
			Replacements.push(TemplateUtils.addOption("${IDEA_Flixel_Engine_Library}", "", FlxTools.settings.IDEA_Flixel_Engine_Library));
			Replacements.push(TemplateUtils.addOption("${IDEA_Flixel_Addons_Library}", "", FlxTools.settings.IDEA_Flixel_Addons_Library));

			CommandUtils.copyRecursively(FlxTools.intellijSource, TargetPath, TemplateUtils.TemplateFilter, true);
		}
		else if (IDEOption == FlxTools.FLASH_DEVELOP)
		{
			Replacements.push(TemplateUtils.addOption("${WIDTH}", "", FlxTools.PWIDTH));
			Replacements.push(TemplateUtils.addOption("${HEIGHT}", "", FlxTools.PHEIGHT));

			CommandUtils.copyRecursively(FlxTools.flashDevelopSource, TargetPath, TemplateUtils.TemplateFilter, true);
		}
		else if (IDEOption == FlxTools.FLASH_DEVELOP_FDZ)
		{
			//todo
		}

		return Replacements;
	}

	static public function resolveIDEChoice(console:Console):String
	{
		var IDE = "";

		var options = new Map<String, String>();
		options.set("-subl", FlxTools.SUBLIME_TEXT);
		options.set("-fd", FlxTools.FLASH_DEVELOP);
		options.set("-idea", FlxTools.INTELLIJ_IDEA);
		options.set("-noide", FlxTools.IDE_NONE);

		var overrideIDE = "";

		for (option in options.keys())
		{
			var IDEName = options.get(option);

			if (console.getOption(option) != null)
			{
				overrideIDE = IDEName;
			}
		}

		if (FlxTools.settings.IDEAutoOpen || overrideIDE != "")
		{
			if (overrideIDE != "")
			{
				IDE = overrideIDE;
			}
			else
			{
				IDE = FlxTools.settings.DefaultEditor;
			}
		}

		return IDE;
	}

	static public function IDEAutoOpen(ProjectPath:String, ProjectName:String, IDE:String, AutoContinue:Bool = false):Bool
	{
		var answer = Answer.Yes;

		if (!AutoContinue)
		{
			answer = CommandUtils.askYN("Do you want to open it with "+IDE+"?");
		}

		if (answer == Answer.Yes)
		{
			if (IDE == FlxTools.FLASH_DEVELOP)
			{
				var projectFile = CommandUtils.combine(ProjectPath, ProjectName + ".hxproj");
				projectFile = StringTools.replace(projectFile, "/", "\\");

				if (FileSys.exists(projectFile))
				{
					Sys.println(projectFile);
					var sublimeOpen = "explorer " + projectFile;
					Sys.command(sublimeOpen);

					return true;
				}
			}
			else if (IDE == FlxTools.SUBLIME_TEXT)
			{
				var projectFile = CommandUtils.combine(ProjectPath, ProjectName + ".sublime-project");

				if (FileSys.exists(projectFile))
				{
					Sys.println(projectFile);
					if (FileSys.isMac || FileSys.isLinux)
					{
						var sublimeOpen = "subl " + projectFile;
						Sys.command(sublimeOpen);
					}
					else if (FileSys.isWindows)
					{
						//todo
					}

					return true;
				}
			}
			else if (IDE == FlxTools.INTELLIJ_IDEA)
			{
				var projectFile = CommandUtils.combine(ProjectPath, ".idea");

				if (FileSys.exists(projectFile))
				{
					if (FileSys.isMac)
					{
						var cmd = FlxTools.settings.IDEA_Path + " " + ProjectPath;
						Sys.command(cmd);
					}
					else if (FileSys.isWindows)
					{
						//C://
					}
					else if (FileSys.isLinux)
					{
						//todo untested
						var cmd = FlxTools.settings.IDEA_Path + " " + ProjectPath;
						Sys.command(cmd);
					}
					return true;
				}
			}
		}

		return false;
	}
}

typedef OpenFLProject = {
	var NAME:String;
	var PATH:String;
	var PROJECTXMLPATH:String;
	var TARGETS:String;
}