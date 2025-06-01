//
import funkin.editors.ui.UIState;
import funkin.editors.EditorPicker;
import flixel.effects.FlxFlicker;
import funkin.editors.EditorTreeMenu;
import Type;

var modchartEditorID = 5;

function create()
{
	options.push(
		{
			name: "Modchart Editor",
			iconID: 0,
			state: EditorTreeMenu
		}
	);
	modchartEditorID = options.length-1;
	
}
var didSelect = false;
function postUpdate(elapsed)
{
	if (!didSelect)
	{
		if (selected)
		{
			didSelect = true;
			if (curSelected == modchartEditorID)
				overrideStateLoad("ModchartEditorSongSelectState");
		}
	}

}

function overrideStateLoad(script) {
	FlxFlicker.stopFlickering(sprites[curSelected].label); //stop currrent callback
	sprites[curSelected].flicker(function() {
		subCam.fade(0xFF000000, 0.25, false, function() {
			var state = Type.createInstance(options[curSelected].state, []);
			state.scriptName = script;
			FlxG.switchState(state);
		});
	});
}