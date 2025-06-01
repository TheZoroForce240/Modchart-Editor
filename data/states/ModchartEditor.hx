//
import funkin.editors.ui.UISliceSprite;
import funkin.game.HudCamera;
import funkin.menus.FreeplayState;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UINumericStepper;
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UICheckbox;
import funkin.editors.ui.UIFileExplorer;
import funkin.editors.ui.UIWindow;
import funkin.editors.ui.UISprite;
import funkin.editors.ui.UISlider;
import funkin.editors.ui.UIUtil;
import funkin.editors.ui.UIContextMenu;
import haxe.io.Path;
import funkin.editors.ui.UITopMenu;
import funkin.editors.ui.UISubstateWindow;
import funkin.backend.utils.SortedArrayUtil;
import flixel.input.keyboard.FlxKey;
import funkin.backend.utils.ShaderResizeFix;
import flixel.addons.display.FlxBackdrop;
import funkin.editors.charter.CharterQuantButton;
import openfl.ui.MouseCursor;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import haxe.xml.Printer;
import funkin.game.Stage;
import funkin.backend.MusicBeatGroup;
import Xml;
import ModchartEventObjects;
import UIScrollBarHorizontal;

public static var CURRENT_EVENT = null; //event used by edit substate
public static var EVENT_EDIT_EVENT_SCRIPT = null;
public static var EVENT_EDIT_CALLBACK:Void->Void = null;
public static var EVENT_EDIT_CANCEL_CALLBACK:Void->Void = null;
public static var EVENT_DELETE_CALLBACK:Void->Void = null;

public static var ITEM_EDIT_LOADED_SCRIPTS = ["" => null];
public static var ITEM_EDIT_SAVE_CALLBACK:Void->Void = null;
public static var ITEM_EDIT_SAVED_INIT_EVENTS = null;

public static var CURRENT_XML:Xml;

function destroy() {
	CURRENT_EVENT = null;
	EVENT_EDIT_EVENT_SCRIPT = null;
	EVENT_EDIT_CALLBACK = null;
	EVENT_EDIT_CANCEL_CALLBACK = null;
	EVENT_DELETE_CALLBACK = null;
	ITEM_EDIT_SAVE_CALLBACK = null;
	ITEM_EDIT_SAVED_INIT_EVENTS = null;
	ITEM_EDIT_LOADED_SCRIPTS = null;
	CURRENT_XML = null;
}

public var eventScripts = ["" => null];
public var itemScripts = ["" => null];

public function callItemScriptFromItem(item, func, args) {
	var script = itemScripts.get(item.type);
	if (script != null) {
		script.call(func, args);
	}
}

public function callEventScriptFromItem(item, func, args) {
	//items could technically support multiple types of event based on the name
	var script = eventScripts.get(callItemScriptFromItem(item, "getEventNameFromItem", [item]));
	if (script != null) {
		script.call(func, args);
	}
}

public function callEventScriptFromEvent(e, func, args) {
	var script = eventScripts.get(e.type);
	if (script != null) {
		script.call(func, args);
	}
}

/*
{
	name: "",
	type: "",
	defaultValue: 0,
	currentValue: 0,
	lastValue: -9999
	property: "",
	object: null //shader/modifier/whatever idk
}
*/
public var timelineItems = [];
public var timelineIndexMap = ["" => -1];
public function createTimelineItem(name, type, object) {
	if (timelineIndexMap.exists(name)) {
		trace("duplicate timeline item?");
	}
	var timelineItem = {
		name: name,
		type: type,
		defaultValue: 0,
		currentValue: 0,
		lastValue: Math.NEGATIVE_INFINITY,
		property: "",
		object: object
	}
	timelineItems.push(timelineItem);
	timelineList.push(name);
	timelineIndexMap.set(name, timelineItems.length-1);
	return timelineItem;
}
var eventRenderer = null;
var eventIndexList = [0];
var events = [];

//array<String>
public var timelineList = [];

/*
{
	bg: null,
	nameText: null,
	valueText: null
}
*/
public var timelineUIList = [];

/*
{
	startIndex: -1,
	endIndex: 0,
	color: -1,
	bg: null
}
*/
public var timelineGroups = [];

public var timelineUIBG = new MusicBeatGroup();
public var timelineUINameText = new MusicBeatGroup();
public var timelineUIValueText = new MusicBeatGroup();

var conductorSprY:Float = 0.0;
var vocals:FlxSound;

var songPosInfo:UIText;

public var camGame:FlxCamera;
public var camHUD:HudCamera;
public var camOther:FlxCamera;

var camEditor:FlxCamera;
var camEditorTop:FlxCamera;
var camTimelineList:FlxCamera;
var camTimelineValueList:FlxCamera;
var camTimeline:FlxCamera;

var scrollBar:UIScrollBarHorizontal;

var timelineWindow:UIWindow;
var beatSeparator:FlxBackdrop;
var sectionSeparator:FlxBackdrop;

var hoverBox:FlxSprite;

var stage:Stage;
var defaultCamZoom:Float = 1;
var stagePreviewMode = false;

var xml:Xml;

var ROW_SIZE_X = 20.0;
var ROW_SIZE_Y = 20.0;
var targetRowSizeX = 20.0;
var targetRowSizeY = 20.0;

function updateSize() {
	hoverBox.setGraphicSize(ROW_SIZE_Y,ROW_SIZE_Y);
	hoverBox.updateHitbox();

	for (i => ui in timelineUIList) {
		ui.bg.y = ROW_SIZE_Y*i;
		ui.nameText.y = ROW_SIZE_Y*i;
		ui.valueText.y = ROW_SIZE_Y*i;
	}
}

var topMenu = [];
var topMenuSpr = null;
var selectionBox:UISliceSprite;
var selectedEvents = [];
var clipboard = [];

var snapIndex:Int = 6;
public var quantButtons:Array<CharterQuantButton> = [];
public var quant:Int = 16;
public var quants:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 192]; // different quants

public var strumLines = [];
public var downscroll = Options.downscroll;

function postCreate() {

	eventScripts.clear();
	for (path in Paths.getFolderContent('data/scripts/modchartEvents/', true, null)) {
		if (Path.extension(path) == "hx") {
			var file = CoolUtil.getFilename(path);
			eventScripts.set(file, importScript("data/scripts/modchartEvents/" + file + ".hx"));
		}
	}

	itemScripts.clear();
	for (path in Paths.getFolderContent('data/scripts/modchartTimelineItems/', true, null)) {
		if (Path.extension(path) == "hx") {
			var file = CoolUtil.getFilename(path);
			itemScripts.set(file, importScript("data/scripts/modchartTimelineItems/" + file + ".hx"));
		}
	}

	topMenu = [
		{
			label: "File",
			childs: [
				{
					label: "Save",
					keybind: [FlxKey.CONTROL, FlxKey.S],
					onSelect: _save
				},
				{
					label: "Save (Optimized)",
					onSelect: _save_opt
				},
				null,
				{
					label: "Exit",
					keybind: [FlxKey.ESCAPE],
					onSelect: _exit
				}
			]
		},
		{
			label: "Edit",
			childs: [
				/*{
					label: "Undo",
					keybind: [FlxKey.CONTROL, FlxKey.Z],
					onSelect: _edit_undo
				},
				{
					label: "Redo",
					keybinds: [[FlxKey.CONTROL, FlxKey.Y], [FlxKey.CONTROL, FlxKey.SHIFT, FlxKey.Z]],
					onSelect: _edit_redo
				},
				null,*/
				{
					label: "Copy",
					keybind: [FlxKey.CONTROL, FlxKey.C],
					onSelect: _edit_copy
				},
				{
					label: "Paste",
					keybind: [FlxKey.CONTROL, FlxKey.V],
					onSelect: _edit_paste
				},
				null,
				{
					label: "Cut",
					keybind: [FlxKey.CONTROL, FlxKey.X],
					onSelect: _edit_cut
				},
				{
					label: "Delete",
					keybind: [FlxKey.DELETE],
					onSelect: _edit_delete
				},
				null,
				{
					label: "Shift Selection Left",
					keybind: [FlxKey.SHIFT, FlxKey.LEFT],
					onSelect: _edit_shiftleft
				},
				{
					label: "Shift Selection Right",
					keybind: [FlxKey.SHIFT, FlxKey.RIGHT],
					onSelect: _edit_shiftright
				}
			]
		},
		{
			label: "Modchart",
			childs: [
				{
					label: "Edit Timeline Items",
					onSelect: _modchart_edititems
				}
			]
		},
		{
			label: "View",
			childs: [
				{
					label: "Fullscreen",
					keybind: [FlxKey.F],
					onSelect: _view_fullscreen
				},
				{
					label: "Swap Scroll",
					onSelect: _view_downscroll
				}
			]
		},
		{
			label: "Song",
			childs: [
				{
					label: "Go back to the start",
					keybind: [FlxKey.HOME],
					onSelect: _song_start
				},
				{
					label: "Go to the end",
					keybind: [FlxKey.END],
					onSelect: _song_end
				},
				null,
				{
					label: "Mute instrumental",
					onSelect: _song_muteinst
				},
				{
					label: "Mute voices",
					onSelect: _song_mutevoices
				}
			]
		},
		{
			label: "Playback",
			childs: [
				{
					label: "Play/Pause",
					keybind: [FlxKey.SPACE],
					onSelect: _playback_play
				},
				null,
				{
					label: "↑ Speed 25%",
					onSelect: _playback_speed_raise
				},
				{
					label: "Reset Speed",
					onSelect: _playback_speed_reset
				},
				{
					label: "↓ Speed 25%",
					onSelect: _playback_speed_lower
				},
				null,
				{
					label: "Go back a section",
					keybind: [FlxKey.A],
					onSelect: _playback_back
				},
				{
					label: "Go forward a section",
					keybind: [FlxKey.D],
					onSelect: _playback_forward
				}
			]
		},
		{
			label: "Snap >",
			childs: [
				{
					label: "wha",
					onSelect: function() {}
				}
			]
		}
	];

	camGame = FlxG.camera;

	camHUD = new HudCamera();
	camHUD.bgColor = 0;
	camHUD.downscroll = downscroll;
	FlxG.cameras.add(camHUD);

	camOther = new FlxCamera();
	camOther.bgColor = 0;
	FlxG.cameras.add(camOther);

	camEditor = new FlxCamera();
	camEditor.bgColor = 0;
	FlxG.cameras.add(camEditor);

	camEditorTop = new FlxCamera();
	camEditorTop.bgColor = 0;
	FlxG.cameras.add(camEditorTop);

	topMenuSpr = new UITopMenu(topMenu);
	topMenuSpr.scrollFactor.set(1,1);
	topMenuSpr.cameras = [camEditorTop];
	add(topMenuSpr);

	quants.reverse();
	for (quant in quants) {
		var button = new CharterQuantButton(0, 0, quant);
		button.cameras = [camEditorTop];
		button.onClick = () -> {setquant(button.quant);};
		quantButtons.push(add(button));
	}
	quants.reverse();
	
	buildSnapsUI();

	camTimelineList = new FlxCamera(0, 720/2, 200, 720/2);
	camTimelineList.bgColor = 0;
	FlxG.cameras.add(camTimelineList);

	camTimelineValueList = new FlxCamera(200, 720/2, 50, 720/2);
	camTimelineValueList.bgColor = 0;
	FlxG.cameras.add(camTimelineValueList);

	camTimeline = new FlxCamera(250, 720/2, 1280-250, 720/2);
	camTimeline.bgColor = 0;
	FlxG.cameras.add(camTimeline);

	//bg = new FlxSprite();
	//bg.loadGraphic(Paths.image('menus/menuBG'));
	//bg.color = 0xFF777777;
	//add(bg);
	//bg.cameras = [camGame];

	if (PlayState.SONG.stage == null) PlayState.SONG.stage = "stage";
	stage = new Stage(PlayState.SONG.stage);
	for (obj in stage.stageSprites) {
		obj.cameras = [camGame];
	}
	if (stage.stageXML != null && stage.stageXML.exists("zoom")) {
		defaultCamZoom = Std.parseFloat(stage.stageXML.get("zoom"));
	}

	FlxG.mouse.visible = true;

	createStrumlines();

	songPosInfo = new UIText(FlxG.width - 30 - 400, 35, 400, "00:00\nBeat: 0\nStep: 0\nMeasure: 0\nBPM: 0\nTime Signature: 4/4");
	songPosInfo.alignment = "right";
	songPosInfo.cameras = [camEditor];
	songPosInfo.scrollFactor.set(0,0);
	if (!stagePreviewMode) add(songPosInfo);

	timelineWindow = new UIWindow(0,720-320, 1280,320, "Timeline");
	timelineWindow.cameras = [camEditor];
	add(timelineWindow);
	
	scrollBar = new UIScrollBarHorizontal();
	scrollBar.newnew(250, timelineWindow.y+5, 1000, 0, 10, 1280-270, 20);
	scrollBar.cameras = [camEditor];
	scrollBar.onChange = function(v) {
		if (!FlxG.sound.music.playing)
			Conductor.songPosition = Conductor.getTimeForStep(v) + Conductor.songOffset;
	}
	add(scrollBar);

	hoverBox = new FlxSprite(-100,0);
	hoverBox.makeGraphic(1,1);
	hoverBox.setGraphicSize(ROW_SIZE_X,ROW_SIZE_Y);
	hoverBox.updateHitbox();
	hoverBox.cameras = [camTimeline];
	
	loadSong();
	loadEvents(false);
	buildXMLFromEvents();

	var valueBG = new FlxSprite(0,0);
	valueBG.makeGraphic(1,1);
	valueBG.setGraphicSize(50,1280);
	valueBG.updateHitbox();
	valueBG.color = 0xff302e32;
	valueBG.cameras = [camTimelineValueList];
	valueBG.scrollFactor.set();
	add(valueBG);

	timelineUIBG.cameras = [camTimeline, camTimelineList, camTimelineValueList];
	timelineUIBG.scrollFactor.set(0, 1);
	add(timelineUIBG);
	timelineUINameText.cameras = [camTimelineList];
	add(timelineUINameText);
	timelineUIValueText.cameras = [camTimelineValueList];
	add(timelineUIValueText);
	createTimelineUI();

	var line = new FlxSprite(200-2,0);
	line.makeGraphic(1,1);
	line.setGraphicSize(2,1280);
	line.updateHitbox();
	line.cameras = [camTimelineList];
	line.scrollFactor.set();
	add(line);

	var line2 = new FlxSprite(50-2,0);
	line2.makeGraphic(1,1);
	line2.setGraphicSize(2,1280);
	line2.updateHitbox();
	line2.cameras = [camTimelineValueList];
	line2.scrollFactor.set();
	add(line2);

	sectionSeparator = new FlxBackdrop(null, FlxAxes.X, 0, 0);
	sectionSeparator.x = -2;

	beatSeparator = new FlxBackdrop(null, FlxAxes.X, 0, 0);
	beatSeparator.x = -1;

	for(sep in [sectionSeparator, beatSeparator]) {
		sep.makeSolid(1, 1, -1);
		sep.alpha = 0.5;
		sep.scrollFactor.set(1, 0);
		sep.scale.set(sep == sectionSeparator ? 4 : 2, 720/2);
		sep.cameras = [camTimeline];
		sep.updateHitbox();
	}
	add(beatSeparator);
	add(sectionSeparator);

	add(hoverBox);

	eventRenderer = new EventRenderer();
	add(eventRenderer);
	eventRenderer.cameras = [camTimeline];

	selectionBox = new UISliceSprite(0, 0, 2, 2, 'editors/ui/selection');
	selectionBox.visible = false;
	selectionBox.scrollFactor.set(1, 1);
	selectionBox.incorporeal = true;
	selectionBox.cameras = [camTimeline];
	add(selectionBox);
}

function createTimelineUI() {
	timelineUIBG.clear();
	timelineUINameText.clear();
	timelineUIValueText.clear();
	timelineUIList = [];

	for (i => name in timelineList) {
		var bg = new FlxSprite(0,(ROW_SIZE_Y*i));
		bg.makeGraphic(1,1);
		bg.setGraphicSize(1280,ROW_SIZE_Y);
		bg.updateHitbox();
		bg.cameras = [camTimeline, camTimelineList, camTimelineValueList];
		bg.scrollFactor.set(0, 1);
		bg.color = i % 2 == 1 ? 0xFF272727 : 0xFF545454;
		timelineUIBG.add(bg);

		var text = new UIText(10, (ROW_SIZE_Y*i),0, name, 15);
		text.cameras = [camTimelineList];
		timelineUINameText.add(text);

		var valueText = new UIText(10, (ROW_SIZE_Y*i),0, "-", 15);
		valueText.cameras = [camTimelineValueList];
		timelineUIValueText.add(valueText);

		timelineUIList.push({
			bg: bg,
			nameText: text,
			valueText: valueText
		});
	}

	for (grp in timelineGroups) {
		grp.bg = new FlxSprite(0, ROW_SIZE_Y * grp.startIndex);
		grp.bg.makeGraphic(1,1);
		grp.bg.setGraphicSize(1280, ROW_SIZE_Y * (grp.endIndex - grp.startIndex));
		grp.bg.updateHitbox();
		grp.bg.cameras = [camTimeline, camTimelineList, camTimelineValueList];
		grp.bg.scrollFactor.set(0, 1);
		grp.bg.color = grp.color;
		grp.bg.alpha = 0.15;
		timelineUIBG.add(grp.bg);
	}
}


function createStrumlines() {
	for(i=>strumLine in PlayState.SONG.strumLines) {
		if (strumLine == null) continue;


		var strOffset:Float = strumLine.strumLinePos == null ? (strumLine.type == 1 ? 0.75 : 0.25) : strumLine.strumLinePos;
		var startingPos:FlxPoint = strumLine.strumPos == null ?
			FlxPoint.get((FlxG.width * strOffset) - ((Note.swagWidth * (strumLine.strumScale == null ? 1 : strumLine.strumScale)) * 2), 50) :
			FlxPoint.get(strumLine.strumPos[0] == 0 ? ((FlxG.width * strOffset) - ((Note.swagWidth * (strumLine.strumScale == null ? 1 : strumLine.strumScale)) * 2)) : strumLine.strumPos[0], strumLine.strumPos[1]);

		var strumScale = (strumLine.strumScale == null ? 1 : strumLine.strumScale);

		strumLines.push([]);

		if (strumLine.visible != false) {
			var dirs = ["arrowLEFT", "arrowDOWN", "arrowUP", "arrowRIGHT"];
			for (dir in 0...4) {
				var babyArrow = new FlxSprite(startingPos.x + (Note.swagWidth * strumScale * dir), startingPos.y);
				babyArrow.frames = Paths.getFrames("game/notes/default");
				babyArrow.animation.addByPrefix('static', dirs[dir]);
				babyArrow.animation.play("static");
				babyArrow.setGraphicSize(Std.int((babyArrow.width * 0.7) * strumScale));
				babyArrow.updateHitbox();
				babyArrow.scrollFactor.set();
				babyArrow.cameras = [camHUD];
				babyArrow.ID = dir;
				if (!stagePreviewMode) add(babyArrow);
				strumLines[i].push(babyArrow);
			}
		}
	}
}

var _fullscreen = false;
var _timelineScrollY = 0;
var __crochet:Float = 0;
var __firstFrame:Bool = true;
function update(elapsed) {

	ROW_SIZE_X = CoolUtil.fpsLerp(ROW_SIZE_X, targetRowSizeX, 0.2);
	ROW_SIZE_Y = CoolUtil.fpsLerp(ROW_SIZE_Y, targetRowSizeY, 0.2);

	if (FlxG.sound.music.playing || __firstFrame) {
		conductorSprY = curStepFloat * ROW_SIZE_X;
	} else {
		conductorSprY = CoolUtil.fpsLerp(conductorSprY, curStepFloat * ROW_SIZE_X, __firstFrame ? 1 : 1/3);
	}
	eventRenderer.conductorPos = conductorSprY/ROW_SIZE_X;

	updateUI();
	updateInputs();

	__crochet = ((60 / Conductor.bpm) * 1000);
	if (timelineWindow.hovered) {
		if (FlxG.keys.pressed.CONTROL) {
			if (FlxG.mouse.wheel != 0.0) {
				targetRowSizeX += FlxG.mouse.wheel * 2;
				if (targetRowSizeX < 4) targetRowSizeX = 4;
				if (targetRowSizeX > 100) targetRowSizeX = 100;
			}
		} else {
			_timelineScrollY += (FlxG.keys.pressed.SHIFT ? 8.0 : 1.0) * -FlxG.mouse.wheel * ROW_SIZE_Y;
			_timelineScrollY = FlxMath.bound(_timelineScrollY, 0, Math.max(0, 30 + (ROW_SIZE_Y*timelineList.length) - 720/2.25));
			camTimelineValueList.scroll.y = camTimeline.scroll.y = camTimelineList.scroll.y = CoolUtil.fpsLerp(camTimelineList.scroll.y, _timelineScrollY, 0.15);
		}
	} else {
		if (!FlxG.sound.music.playing) {
			Conductor.songPosition -= (__crochet*0.25 * (FlxG.keys.pressed.SHIFT ? 8.0 : 1.0) * FlxG.mouse.wheel) - Conductor.songOffset;
		}
	}

	//trace(_timelineScrollY);

	var songLength = FlxG.sound.music.length;
	Conductor.songPosition = FlxMath.bound(Conductor.songPosition + Conductor.songOffset, 0, songLength);
	if (Conductor.songPosition >= songLength - Conductor.songOffset) {
		FlxG.sound.music.pause();
		vocals.pause();
		//for (strumLine in strumLines.members) strumLine.vocals.pause();
	}

	songPosInfo.text = CoolUtil.timeToStr(Conductor.songPosition) + '/' + CoolUtil.timeToStr(songLength)
		+ '\nStep: ' + curStep
		+ '\nBeat: ' + curBeat
		+ '\nMeasure: ' + curMeasure
		+ '\nBPM: ' + Conductor.bpm;


	camGame.zoom = CoolUtil.fpsLerp(camGame.zoom, defaultCamZoom, 0.05);
	camHUD.zoom = CoolUtil.fpsLerp(camHUD.zoom, 1, 0.05);

	updateEvents();
}

function updateUI() {
	camTimeline.scroll.x = conductorSprY;
	sectionSeparator.spacing.x = ((ROW_SIZE_X/4) * Conductor.beatsPerMeasure * Conductor.stepsPerBeat) - 1;
	beatSeparator.spacing.x = ((ROW_SIZE_X/2) * Conductor.stepsPerBeat) - 1;
	
	var lastCamScale = camGame.flashSprite.scaleX;
	var camScale = _fullscreen ? 1.0 : 0.5;
	var newScale = CoolUtil.fpsLerp(camGame.flashSprite.scaleX, camScale, 0.15);
	if (Math.abs(camScale-newScale) < 0.01) newScale = camScale;
	camGame.flashSprite.scaleX = camGame.flashSprite.scaleY = camOther.flashSprite.scaleX = camOther.flashSprite.scaleY = camHUD.flashSprite.scaleX = camHUD.flashSprite.scaleY = newScale;
	

	if (camGame.flashSprite.scaleX != lastCamScale) {
		ShaderResizeFix.fixSpriteShaderSize(camGame.flashSprite);
		ShaderResizeFix.fixSpriteShaderSize(camHUD.flashSprite);
		ShaderResizeFix.fixSpriteShaderSize(camOther.flashSprite);
	}

	camGame.y = camHUD.y = camOther.y = ((-720/4)+32) * (-((camGame.flashSprite.scaleX-0.5)*2)+1);
	camEditor.scroll.y = CoolUtil.fpsLerp(camEditor.scroll.y, _fullscreen ? -720/2 : 0, 0.15);
	camEditorTop.scroll.y = CoolUtil.fpsLerp(camEditorTop.scroll.y, _fullscreen ? 100 : 0, 0.15);
	camTimelineValueList.y = camTimelineList.y = camTimeline.y = ((-camEditor.scroll.y) + 720/2) + 30 + 40;

	scrollBar.size = (1280-250)/ROW_SIZE_X;
	scrollBar.start = Conductor.curStepFloat - (scrollBar.size / 2);

	if (topMenuSpr.members[snapIndex] != null) {
		var snapButton = topMenuSpr.members[snapIndex];
		var lastButtonX = snapButton.x + snapButton.bWidth + 100;

		var buttonI:Int = 0;
		for (button in quantButtons) {
			button.visible = ((button.quant == quant) ||
				(button.quant == quants[FlxMath.wrap(quants.indexOf(quant)-1, 0, quants.length-1)]) ||
				(button.quant == quants[FlxMath.wrap(quants.indexOf(quant)+1, 0, quants.length-1)]));
			button.selectable = button.visible;
			if (!button.visible) continue;

			button.x = lastButtonX -= button.bWidth;
			button.framesOffset = button.quant == quant ? 9 : 0;
			button.alpha = button.quant == quant ? 1 : (button.hovered ? 0.4 : 0);
		}
		//snapButton.x = (lastButtonX -= snapButton.bWidth)-10;
	}
	
}
var dragStartPos = null;
var isDragging = false;
function updateInputs() {

	if(FlxG.keys.justPressed.ANY && currentFocus == null)
		UIUtil.processShortcuts(topMenu);

	eventRenderer.visible = !_fullscreen;
	if (_fullscreen) return;

	scrollBar.active = !isDragging;
	

	//if (timelineWindow.hovered) {
		var mousePos = FlxG.mouse.getWorldPosition(camTimeline);
		if (FlxG.mouse.justPressed && timelineWindow.hovered) {
			dragStartPos = FlxG.mouse.getWorldPosition(camTimeline);
			isDragging = false;
		} else if (FlxG.mouse.justReleased) {
			if (isDragging) {
				resetSelection();
				for (e in events) {
					if (!selectedEvents.contains(e)) {
						var x = e.step * ROW_SIZE_X;
						var y = e.timelineIndex * ROW_SIZE_Y;
						if ((selectionBox.x + selectionBox.bWidth > x) && (selectionBox.x < x + 20) && 
							(selectionBox.y + selectionBox.bHeight > y) && (selectionBox.y < y + 20)) {
							selectEvent(e, false);
						}
					}
				}
			}
			dragStartPos = null;
		}

		hoverBox.x = quantStep(mousePos.x / ROW_SIZE_X) * ROW_SIZE_X;
		hoverBox.y = Math.floor(mousePos.y / ROW_SIZE_Y) * ROW_SIZE_Y;

		selectionBox.visible = false;

		if (dragStartPos != null) {
			if (FlxG.mouse.pressed && (Math.abs(mousePos.x - dragStartPos.x) > 20 || Math.abs(mousePos.y - dragStartPos.y) > 20)) {
				isDragging = true;
			}
		}
		if (FlxG.mouse.pressed && dragStartPos != null && isDragging) {
			selectionBox.visible = true;
			selectionBox.x = Math.min(mousePos.x, dragStartPos.x);
			selectionBox.y = Math.min(mousePos.y, dragStartPos.y);
			selectionBox.bWidth = Std.int(Math.abs(mousePos.x - dragStartPos.x));
			selectionBox.bHeight = Std.int(Math.abs(mousePos.y - dragStartPos.y));
		}

		eventRenderer.sizeX = ROW_SIZE_X;
		eventRenderer.sizeY = ROW_SIZE_Y;
		eventRenderer._timelineScrollY = camTimeline.scroll.y;
		/*
		for(i in eventGroup.getVisibleStartIndex()...eventGroup.getVisibleEndIndex()) {
			var obj = eventGroup.members[i];
			obj.x = obj.event.step * ROW_SIZE_X;
			obj.y = obj.timelineIndex * ROW_SIZE_Y;
			obj.updateLength(ROW_SIZE_X);
		}
		*/


		if (FlxG.mouse.justReleased && !isDragging && timelineWindow.hovered) {
			var clickedEvent = null;
			for(i in eventRenderer.getVisibleStartIndex()...eventRenderer.getVisibleEndIndex()) {
				var e = events[i];
				var x = e.step * ROW_SIZE_X;
				var y = e.timelineIndex * ROW_SIZE_Y;
				if ((mousePos.x >= x) && (mousePos.x < x + 20) && (mousePos.y >= y) && (mousePos.y < y + 20)) {
					if (clickedEvent == null) {
						clickedEvent = e;
					}
					break;
				}
			}

			if (FlxG.keys.pressed.CONTROL) {
				if (clickedEvent != null) {
					selectEvent(clickedEvent, false);
				}
			} else {
				if (clickedEvent == null) {
					var step = quantStep((mousePos.x)/ROW_SIZE_X);
					var timelineIndex = Math.floor(mousePos.y / ROW_SIZE_Y);
					if (timelineIndex > -1 && timelineIndex < timelineList.length) {
						addEvent(step, timelineItems[timelineIndex]);
					}
				} else {
					editEvent(clickedEvent, false);
				}
			}
		}

		if (FlxG.mouse.justReleased) {
			isDragging = false;
		}
	//}

	
}

function quantStep(step:Float):Float {
	var stepMulti:Float = 1/(quant/16);
	return Math.floor(step/stepMulti) * stepMulti;
}

function quantStepRounded(step:Float, ?roundRatio:Float = 0.5):Float {
	var stepMulti:Float = 1/(quant/16);
	return ratioRound(step/stepMulti, roundRatio) * stepMulti;
}

function addEvent(step, item) {
	updateEvents(step);
	var e = callEventScriptFromItem(item, "createEventEditor", [item.name, step, item]);
	if (e != null) {
		SortedArrayUtil.addSorted(events, e, function(n){return n.step;});

		/*
		var obj = new EventObject(e);
		obj.timelineIndex = timelineItems.indexOf(item);
		obj.x = e.step * ROW_SIZE_X;
		obj.y = obj.timelineIndex * ROW_SIZE_Y;
		obj.cameras = [camTimeline];
		eventGroup.addSorted(obj); 
		obj.updateEvent();
		*/
		refreshEventTimings();

		editEvent(e, true);
	}
	resetSelection();
}

function editEvent(e, justPlaced:Bool) {
	CURRENT_EVENT = e;
	EVENT_EDIT_EVENT_SCRIPT = eventScripts.get(e.type);
	EVENT_EDIT_CALLBACK = function() {
		refreshEventTimings();
	}
	EVENT_EDIT_CANCEL_CALLBACK = function() {
		if (justPlaced) {
			events.remove(e);
			e = null;
		}
		
		refreshEventTimings();
	}
	EVENT_DELETE_CALLBACK = function() {
		if (selectedEvents.contains(e)) selectedEvents.remove(e);
		events.remove(e);
		e = null;
		
		refreshEventTimings();
	}
	var win = new UISubstateWindow(true, 'ModchartEventEditSubstate');
	FlxG.sound.music.pause();
	vocals.pause();
	openSubState(win);

	//selectEvent(e, true);
}

function loadSong() {
	Conductor.setupSong(PlayState.SONG);

	CoolUtil.setMusic(FlxG.sound, FlxG.sound.load(Paths.inst(PlayState.SONG.meta.name, PlayState.difficulty)));
	if (PlayState.SONG.meta.needsVoices != false) // null or true
		vocals = FlxG.sound.load(Paths.voices(PlayState.SONG.meta.name, PlayState.difficulty));
	else
		vocals = new FlxSound();
	vocals.group = FlxG.sound.defaultMusicGroup;

	scrollBar.length = Conductor.getStepForTime(FlxG.sound.music.length);
}

function loadDefaults() {
	for (name => script in itemScripts) {
		script.call("setupDefaultsEditor", []);
	}
}

function loadEvents(reload) {

	if (!reload) {
		var xmlPath = Paths.getPath("songs/"+PlayState.SONG.meta.name+"/modchart.xml");
		if (Assets.exists(Paths.getPath("songs/"+PlayState.SONG.meta.name+"/modchart-" + PlayState.difficulty + ".xml"))) {
			xmlPath = Paths.getPath("songs/"+PlayState.SONG.meta.name+"/modchart-" + PlayState.difficulty + ".xml");
		}
		if (!Assets.exists(xmlPath)) return;

		xml = Xml.parse(Assets.getText(xmlPath)).firstElement();
		loadDefaults();
	} else {
		//clear stuff for reload
		timelineGroups = [];
		timelineItems = [];
		timelineList = [];
		timelineIndexMap.clear();
		for (name => script in itemScripts) {
			script.call("reloadItems", []);
		}
		loadDefaults();
	}

	for (list in xml.elementsNamed("Init")) {
		for (name => script in itemScripts) {
			script.call("setupItemsFromXMLEditor", [list]);
		}
	}
	for (item in timelineItems) {
		item.currentValue = item.defaultValue;
	}
	if (!reload) {
		for (list in xml.elementsNamed("Events")) {
			for (event in list.elementsNamed("Event")) {

				var eventType = event.get("type");
				if (eventScripts.exists(eventType)) {
					var e = eventScripts.get(eventType).call("eventFromXMLEditor", [event]);
					var n = callEventScriptFromEvent(e, "getItemName", [e]);
					if (timelineIndexMap.exists(n)) {
						events.push(e);
					} else {
						trace("skipping event for \"" + n + "\"");
					}
				}
			}
		}
	}
	for (name => script in itemScripts) {
		script.call("postXMLLoad", [xml]);
	}

	resetValuesToDefault();
	refreshEventTimings();

	if (reload) {
		createTimelineUI();

		/*
		for(i in 0...eventGroup.members.length) {
			var obj = eventGroup.members[i];
			var n = callEventScriptFromEvent(obj.event, "getItemName", [obj.event]);
			obj.timelineIndex = timelineList.indexOf(n);
		}
		*/
	}
}

function resetValuesToDefault() {
	for (item in timelineItems) {
		item.currentValue = item.defaultValue;
	}
}

function refreshEventTimings() {
	eventIndexList = [];

	for (item in timelineItems) {
		item.currentValue = item.defaultValue;
		item.lastValue = Math.NEGATIVE_INFINITY;
		eventIndexList.push(-1);
	}
	lastStep = Math.NEGATIVE_INFINITY;

	for (i in 0...events.length) {
		var e = events[i];
		e.lastIndex = -1;
		e.nextIndex = -1;
		
		var n = callEventScriptFromEvent(e, "getItemName", [e]);
		var itemIndex = timelineIndexMap.get(n);
		e.lastValue = timelineItems[itemIndex].currentValue;
		e.timelineIndex = itemIndex;
		if (e.time != null) e.easeIndex = shaderEaseList.indexOf(e.ease);
		if (e.selected == null) e.selected = false;

		if (eventIndexList[itemIndex] == -1) {
			eventIndexList[itemIndex] = i;
		} else {
			var lastIndex = eventIndexList[itemIndex];

			events[lastIndex].nextIndex = i;
			e.lastIndex = lastIndex;
			e.lastValue = events[lastIndex].value;
			if (events[lastIndex].DI_value != null && events[lastIndex].DI_value)
				e.lastValue = -e.lastValue;

			eventIndexList[itemIndex] = i;
		}
	}

	//force update current event indexes
	var currentStep = curStepFloat;
	if (!FlxG.sound.music.playing) {
		currentStep = conductorSprY / ROW_SIZE_X;
	}
	for (itemIndex => index in eventIndexList) {
		var i = index;
		if (events[i] == null) continue;

		if (events[i].nextIndex != -1) {
			while(true) {
				var nextIndex = events[i].nextIndex;
				if (currentStep >= events[nextIndex].step) {
					i = nextIndex;
					if (events[i].nextIndex == -1) {
						break;
					}
				} else {
					break;
				}
			}
		}
		if (events[i].lastIndex != -1) {
			while(true) {
				var lastIndex = events[i].lastIndex;
				if (currentStep < events[lastIndex].step + (events[lastIndex].time != null ? events[lastIndex].time : 0.0)) {
					i = lastIndex;
					if (events[i].lastIndex == -1) {
						break;
					}
				} else {
					break;
				}
			}
		}
		if (i != index) {
			eventIndexList[itemIndex] = i;
		}
	}
}
/*
function createEventObjects() {
	for (i in 0...events.length) {
		var e = events[i];
		var n = callEventScriptFromEvent(e, "getItemName", [e]);

		var obj = new EventObject(e);
		obj.timelineIndex = timelineList.indexOf(n);
		obj.x = e.step * ROW_SIZE_X;
		obj.y = obj.timelineIndex * ROW_SIZE_Y;
		obj.cameras = [camTimeline];
		eventGroup.addSorted(obj);
		obj.updateEvent();
	}
}
*/

var lastStep = Math.NEGATIVE_INFINITY;
function updateEvents(?forceStep:Float = null) {

	for (item in timelineItems) {
		//item.currentValue = item.defaultValue;
	}

	var currentStep = curStepFloat;
	if (!FlxG.sound.music.playing) {
		currentStep = conductorSprY / ROW_SIZE_X;
	}
	if (forceStep != null) currentStep = forceStep;

	for (itemIndex => index in eventIndexList) {
		var i = index;
		if (events[i] == null) continue;

		if (lastStep != currentStep) {

			if (currentStep > lastStep) {
				//check for next event
				if (events[i].nextIndex != -1) {
					while(true) {
						var nextIndex = events[i].nextIndex;
						if (currentStep >= events[nextIndex].step) {
							i = nextIndex;
							if (events[i].nextIndex == -1) {
								break;
							}
						} else {
							break;
						}
					}
				}
			} else {
				//check for last (for rewinding)
				if (events[i].lastIndex != -1) {
					while(true) {
						var lastIndex = events[i].lastIndex;
						if (currentStep < events[lastIndex].step + (events[lastIndex].time != null ? events[lastIndex].time : 0.0)) {
							i = lastIndex;
							if (events[i].lastIndex == -1) {
								break;
							}
						} else {
							break;
						}
					}
				}
			}
		}

		if (i != index) {
			eventIndexList[itemIndex] = i;
		}

		

		var e = events[i];
		if (currentStep >= e.step) {
			var item = timelineItems[itemIndex];
			callEventScriptFromItem(item, "updateEventEditor", [currentStep, e, item]);
		} else {
			timelineItems[itemIndex].currentValue = e.lastValue;
		}
	}

	for (i => item in timelineItems) {
		if (item.currentValue != item.lastValue) {
			item.lastValue = item.currentValue;
			callItemScriptFromItem(item, "updateItem", [item, i]);
		}
	}

	lastStep = currentStep;

	//TODO: reimplement iTime + speed
	/*
	for (obj => value in currentValueList) {
		if (noteModifiers.contains(obj)) {

			var mod = null;
			for (m in modifiers)
				if (m[MOD_NAME] == obj)
					mod = m;

			if (mod != null) {
				mod[MOD_VALUE] = value;
			}

			var text = timelineValueTextList[timelineList.indexOf(obj)];
			if (text != null) {
				text.text = Std.string(FlxMath.roundDecimal(value, 2));
			}
		} else {
			var data = obj.split(".");

			var s = shaders.get(data[0]);
			if (s != null && data[1] != "iTime") {
				s.hset(data[1], value);
			}
	
			var text = timelineValueTextList[timelineList.indexOf(obj)];
			if (text != null && data[1] != "iTime") {
				text.text = Std.string(FlxMath.roundDecimal(value, 2));
			}
		}		
	}

	for (shader in iTimeShaders) {
		if (iTimeWithSpeedShaders.contains(shader)) {
			if (FlxG.sound.music.playing)
				shader.iTime += FlxG.elapsed * shader.speed;
		} else {
			shader.iTime = Conductor.songPosition*0.001;
		}
	}
	*/
}


function buildXMLFromEvents(?newInitEvents = null) {
	var newXml = Xml.createElement("Modchart");
	var initEvents = newInitEvents == null ? Xml.createElement("Init") : newInitEvents;
	var xmlEvents = Xml.createElement("Events");
	
	//copy init events
	if (xml != null && newInitEvents == null) {
		for (list in xml.elementsNamed("Init")) {
			for (name => script in itemScripts) {
				script.call("copyXMLItems", [list, initEvents]);
			}
		}
	}

	for (i in 0...events.length) {
		var e = events[i];
		var node = Xml.createElement("Event");
		node.set("type", e.type);
		node.set("step", e.step);

		callEventScriptFromEvent(e, "eventToXMLEditor", [node, e]);

		xmlEvents.addChild(node);
	}

	newXml.addChild(initEvents);
    newXml.addChild(xmlEvents);
	refreshEventTimings();
	return newXml;
}



function _save() {
	xml = buildXMLFromEvents();
	var path = Paths.getAssetsRoot() + '/songs/'+PlayState.SONG.meta.name+'/modchart.xml';
	if (Assets.exists(Paths.getPath("songs/"+PlayState.SONG.meta.name+"/modchart-" + PlayState.difficulty + ".xml"))) {
		path = Paths.getAssetsRoot() + '/songs/'+PlayState.SONG.meta.name+"/modchart-" + PlayState.difficulty + ".xml";
	}
	CoolUtil.safeSaveFile(path, Printer.print(xml, true));
}
function _save_opt() {
	xml = buildXMLFromEvents();
	var path = Paths.getAssetsRoot() + '/songs/'+PlayState.SONG.meta.name+'/modchart.xml';
	if (Assets.exists(Paths.getPath("songs/"+PlayState.SONG.meta.name+"/modchart-" + PlayState.difficulty + ".xml"))) {
		path = Paths.getAssetsRoot() + '/songs/'+PlayState.SONG.meta.name+"/modchart-" + PlayState.difficulty + ".xml";
	}
	CoolUtil.safeSaveFile(path, Printer.print(xml, false));
}
function _exit() {
	FlxG.switchState(new FreeplayState());
}
function _modchart_edititems() {
	CURRENT_XML = xml;
	ITEM_EDIT_LOADED_SCRIPTS = itemScripts;
	ITEM_EDIT_SAVE_CALLBACK = function() {
		xml = buildXMLFromEvents(ITEM_EDIT_SAVED_INIT_EVENTS);
		xml = buildXMLFromEvents(); //do twice just in case

		loadEvents(true);
	}
	var win = new UISubstateWindow(true, 'ModchartEditDataSubstate');
	FlxG.sound.music.pause();
	vocals.pause();
	openSubState(win);
}

function _view_fullscreen() {
	_fullscreen = !_fullscreen;
	for (name => script in itemScripts) {
		script.call("onFullscreen", [_fullscreen]);
	}
}
function _view_downscroll() {
	downscroll = !downscroll;
	camHUD.downscroll = downscroll;
	refreshEventTimings();

	for (name => script in itemScripts) {
		script.call("onFlipScroll", [downscroll]);
	}
}

function _song_start(_) {
	if (FlxG.sound.music.playing) return;
	Conductor.songPosition = 0;
}
function _song_end(_) {
	if (FlxG.sound.music.playing) return;
	Conductor.songPosition = FlxG.sound.music.length;
}

function _song_muteinst(t) {
	FlxG.sound.music.volume = FlxG.sound.music.volume > 0 ? 0 : 1;
	t.icon = 1 - Std.int(Math.ceil(FlxG.sound.music.volume));
}
function _song_mutevoices(t) {
	vocals.volume = vocals.volume > 0 ? 0 : 1;
	//for (strumLine in strumLines.members) strumLine.vocals.volume = strumLine.vocals.volume > 0 ? 0 : 1;
	t.icon = 1 - Std.int(Math.ceil(vocals.volume));
}

function _playback_speed_change(change) {
	var v = FlxG.sound.music.pitch + change;
	if (v < 0.25) v = 0.25;
	if (v > 2.0) v = 2.0;
	FlxG.sound.music.pitch = vocals.pitch = v;
}

function _playback_speed_raise(_) _playback_speed_change(0.25);
function _playback_speed_reset(_) FlxG.sound.music.pitch = vocals.pitch = 1;
function _playback_speed_lower(_) _playback_speed_change(-0.25);

function _playback_play() {
	if (Conductor.songPosition >= FlxG.sound.music.length - Conductor.songOffset) return;

	if (FlxG.sound.music.playing) {
		FlxG.sound.music.pause();
		vocals.pause();
		//for (strumLine in strumLines.members) strumLine.vocals.pause();
	} else {
		FlxG.sound.music.play();
		vocals.play();
		vocals.time = FlxG.sound.music.time = Conductor.songPosition + Conductor.songOffset * 2;
		//for (strumLine in strumLines.members) {
		//	strumLine.vocals.play();
		//	strumLine.vocals.time = vocals.time;
		//}
	}
}
function _playback_back(_) {
	if (FlxG.sound.music.playing) return;
	Conductor.songPosition -= (Conductor.beatsPerMeasure * __crochet);
}
function _playback_forward(_) {
	if (FlxG.sound.music.playing) return;
	Conductor.songPosition += (Conductor.beatsPerMeasure * __crochet);
}

function selectEvent(e, reset:Bool) {
	if (reset) {
		resetSelection();
	}
	SortedArrayUtil.addSorted(selectedEvents, e, function(n){return n.step;});
	e.selected = true;
}
function resetSelection() {
	for (event in selectedEvents) {
		event.selected = false;
	}
	selectedEvents = [];
}


function _edit_undo() {

}
function _edit_redo() {

}
function _edit_copy() {
	clipboard = [];
	for (event in selectedEvents) {
		clipboard.push(callEventScriptFromEvent(event, "copyEventEditor", [event]));
	}
	clipboard.sort(function(a, b) {
		if(a.step < b.step) return -1;
		else if(a.step > b.step) return 1;
		else return 0;
	});
}
function _edit_paste() {
	resetSelection();
	if (clipboard.length > 0) {
		var diff = curStep - clipboard[0].step; //TODO: maybe switch to use mouse pos instead?

		//trace(clipboard[0].step);
		//trace(diff);

		for (event in clipboard) {
			var e = callEventScriptFromEvent(event, "copyEventEditor", [event]);
			e.step += diff;
			SortedArrayUtil.addSorted(events, e, function(n){return n.step;});
			selectEvent(e, false);
		}

		refreshEventTimings();
	}
}
function _edit_cut() {
	_edit_copy();
	_edit_delete();
}
function _edit_delete() {
	for (e in selectedEvents) {
		events.remove(e);
	}
	selectedEvents = [];
	refreshEventTimings();
}
function _edit_shiftleft() {
	for (event in selectedEvents) {
		event.step -= 1;
		if (event.step < 0) event.step = 0;
	}
	sortAllEvents();
	refreshEventTimings();
}
function _edit_shiftright() {
	for (event in selectedEvents) {
		event.step += 1;
	}
	sortAllEvents();
	refreshEventTimings();
}

function sortAllEvents() {
	events.sort(function(a, b) {
		if(a.step < b.step) return -1;
		else if(a.step > b.step) return 1;
		else return 0;
	});
}


inline function _snap_increasesnap(_) changequant(1);
inline function _snap_decreasesnap(_) changequant(-1);
inline function _snap_resetsnap(_) setquant(16);

inline function changequant(change:Int) {quant = quants[FlxMath.wrap(quants.indexOf(quant) + change, 0, quants.length-1)]; buildSnapsUI();};
inline function setquant(newquant:Int) {quant = newquant; buildSnapsUI();}

function buildSnapsUI() {
	var snapsTopButton = topMenuSpr.members[snapIndex];
	var newChilds:Array<UIContextMenuOption> = [
		{
			label: "↑ Grid Snap",
			keybind: [FlxKey.X],
			onSelect: _snap_increasesnap
		},
		{
			label: "Reset Grid Snap",
			onSelect: _snap_resetsnap
		},
		{
			label: "↓ Grid Snap",
			keybind: [FlxKey.Z],
			onSelect: _snap_decreasesnap
		},
		null
	];

	for (_quant in quants)
		newChilds.push({
			label: _quant + 'x Grid Snap',
			onSelect: (_) -> {setquant(_quant); buildSnapsUI();},
			icon: _quant == quant ? 1 : 0
		});

	topMenu[snapIndex].childs = newChilds;

	if (snapsTopButton != null) snapsTopButton.contextMenu = newChilds;
	return newChilds;
}