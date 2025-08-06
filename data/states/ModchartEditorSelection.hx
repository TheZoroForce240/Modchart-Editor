import funkin.options.type.TextOption;
import funkin.editors.ui.UISubstateWindow;
import funkin.options.type.IconOption;
import funkin.editors.ui.UIState;
import funkin.menus.FreeplayState.FreeplaySonglist;
import funkin.editors.EditorTreeMenu;
import funkin.editors.EditorTreeMenu.EditorTreeMenuScreen;

/*
class ModchartEditorSelectionScreen extends EditorTreeMenuScreen {

	
	public function makeChartOption(d:String, name:String) {
		return new TextOption(d, getID('acceptDifficulty'), function() {
			PlayState.loadSong(s.name, d);
			var s = new UIState();
			s.scriptName = "ModchartEditor";
			FlxG.switchState(s);
		});
	}

	public function makeSongOption(s) {
		
		return opt;
	}

	public function new() {		
		super('editor.modchart-editor.name', 'modchartEditorSelection.desc', 'modchartEditorSelection.');
		
	}
	
}
	*/

var freeplayList:FreeplaySonglist;
var songList:Array<String> = [];

function postCreate() {

	freeplayList = FreeplaySonglist.get(false);	

	var screen = new EditorTreeMenuScreen('editor.modchart-editor.name', 'modchartEditorSelection.desc', 'modchartEditorSelection.');
	addMenu(screen);
	for (i => s in freeplayList.songs) {
		screen.add(makeSongOption(s, screen));
	}

	bgType = 'charter';
}

function makeSongOption(s, parentScreen) {
	songList.push(s.name.toLowerCase());

	var opt = new IconOption(s.name, parentScreen.getID('acceptSong'), s.icon, () -> {
		var screen = new EditorTreeMenuScreen(s.name, parentScreen.getID('selectDifficulty'));
		parentScreen.parent.addMenu(screen);
		for (d in s.difficulties) if (d != '') screen.add(makeChartOption(d, s.name, parentScreen));
	});
	opt.suffix = ' >';
	opt.editorFlashColor = 0xFFFFFFFF;
	return opt;
}

function makeChartOption(d:String, name:String, parentScreen) {
	return new TextOption(d, parentScreen.getID('acceptDifficulty'), "", function() {
		PlayState.loadSong(name, d);
		var s = new UIState();
		s.scriptName = "ModchartEditor";
		FlxG.switchState(s);
	});
}