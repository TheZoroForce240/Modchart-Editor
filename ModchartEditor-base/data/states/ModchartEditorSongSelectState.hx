import funkin.options.type.TextOption;
import funkin.options.OptionsScreen;
import funkin.editors.ui.UISubstateWindow;
import funkin.options.type.EditorIconOption;
import funkin.editors.ui.UIState;
import funkin.menus.FreeplayState.FreeplaySonglist;

function create()
{
	bgType = "charter";

	var freeplayList = FreeplaySonglist.get(false);

	var list:Array<OptionType> = [];

	for(s in freeplayList.songs) {
		var songOption = new EditorIconOption(s.name, "Press ACCEPT to choose a difficulty.", s.icon, function() {
			curSong = s;
			var list:Array<OptionType> = [
				for(d in s.difficulties) if (d != "")
					new TextOption(d, "Press ACCEPT to edit the modchart for the selected difficulty", function() {
						PlayState.loadSong(s.name, d);
						var s = new UIState();
						s.scriptName = "ModchartEditor";
						FlxG.switchState(s);
					})
			];
			optionsTree.add(new OptionsScreen(s.name, "Select a difficulty to continue.", list));
		}, 0xFFFFFFFF);
		list.push(songOption);
	}



	main = new OptionsScreen("Modchart Editor", "Select a song to edit the modchart from.", list);

}