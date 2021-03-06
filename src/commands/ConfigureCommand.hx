package commands;

import massive.sys.cmd.Command;
import utils.ProjectUtils;
import utils.TemplateUtils;
import sys.FileSystem;
import FlxTools.IDE;

class ConfigureCommand extends Command
{
	override public function execute():Void
	{
		TemplateUtils.verifyTemplatesLoaded();
		
		if (console.args.length != 2)
			error("Invalid number of arguments!");
		
		var directory = console.args[1];
		var ide = ProjectUtils.resolveIDEChoice(console);
		if (ide != IDE.VISUAL_STUDIO_CODE)
			// TOOD: support other IDEs (need template replacements)
			error('configure only supports ${IDE.VISUAL_STUDIO_CODE} at the moment');
		
		var projects = [];
		var isProjectFolder = ProjectUtils.findProjectXml(directory) != null;
		if (isProjectFolder)
			projects.push(directory);
		else
		{
			projects = ProjectUtils.findLimeProjects(directory).map(
				function(p) return p.path
			);
		}

		if (projects.length == 0)
		{
			var fullPath = FileSystem.fullPath(directory);
			error('Could not find any Project.xml files in \'$fullPath\'');
		}
			
		for (project in projects)
		{
			var fullPath = FileSystem.fullPath(project);
			print('Adding $ide files to \'$fullPath\'...');
			ProjectUtils.copyIDETemplateFiles(project, null, ide);
		}
	}
}