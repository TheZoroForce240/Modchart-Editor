//
import funkin.editors.ui.UISubstateWindow;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UINumericStepper;
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UISprite;
import haxe.io.Path;
import funkin.editors.ui.UICheckbox;
import funkin.editors.ui.UIColorwheel;
import funkin.editors.ui.UIWindow;
import funkin.editors.ui.UITextBox;
import funkin.editors.ui.UIAutoCompleteTextBox;
import funkin.backend.utils.IniUtil;
import Xml;

import modchart.Manager;
import modchart.core.ModifierGroup;
import modchart.standalone.Adapter;
import modchart.standalone.adapters.codename.Codename;


class EditorAdapter extends modchart.standalone.adapters.codename.Codename {
    public var downscroll = false;
    public var strumLines = [];
    public var camHUD = null;
    public var scrollSpeed = 2.0;

	public function new() {}

	public function onModchartingInitialization() {
		__fCrochet = Conductor.crochet;
	}

	public function isTapNote(sprite:FlxSprite) {
		return false;
	}

	// Song related
	public function getSongPosition():Float {
		return Conductor.songPosition;
	}

	public function getCurrentBeat():Float {
		return Conductor.curBeatFloat;
	}

	public function getStaticCrochet():Float {
		return __fCrochet;
	}

	public function getBeatFromStep(step:Float):Float {
		return step * Conductor.stepsPerBeat;
	}

	public function arrowHit(arrow:FlxSprite) {
		return false;
	}

	public function isHoldEnd(arrow:FlxSprite) {
		return false;
	}

	public function getLaneFromArrow(arrow:FlxSprite) {
		return arrow.ID;
	}

	public function getPlayerFromArrow(arrow:FlxSprite) {
        for (i => group in strumLines) {
            if (group.contains(arrow)) return i;
        }
		return 0;
	}

	public function getHoldParentTime(arrow:FlxSprite) {
		return 0;
	}

	// im so fucking sorry for those conditionals
	public function getKeyCount(?player:Int = 0):Int {
		return strumLines != null && strumLines[player] != null ? strumLines[player].length : 4;
	}

	public function getPlayerCount():Int {
		return strumLines != null ? strumLines.length : 2;
	}

	public function getTimeFromArrow(arrow:FlxSprite) {
		return 0;
	}

	public function getHoldSubdivisions():Int {
		final val = Options.modchartingHoldSubdivisions;
		return val < 1 ? 1 : val;
	}

	public function getDownscroll():Bool {
		return downscroll;
	}

	public function getDefaultReceptorX(lane:Int, player:Int):Float {
		return strumLines[player][lane].x;
	}

	public function getDefaultReceptorY(lane:Int, player:Int):Float {
		return strumLines[player][lane].y;
	}

	public function getArrowCamera():Array<FlxCamera>
		return [camHUD];

	public function getCurrentScrollSpeed():Float {
		return scrollSpeed;
	}

	// 0 receptors
	// 1 tap arrows
	// 2 hold arrows
	// 3 lane attachments
	public function getArrowItems() {
		var pspr:Array<Array<Array<FlxSprite>>> = [];

        
		var strumLineMembers = strumLines;

		for (i in 0...strumLineMembers.length) {
			var sl = strumLineMembers[i];

			//final splashHandler = PlayState.instance.splashHandler;

			// this is somehow more optimized than how i used to do it (thanks neeo for the code!!)
			pspr[i] = [];
			pspr[i][0] = sl.copy();
			pspr[i][1] = [];
			pspr[i][2] = [];
		}
        

		return pspr;
	}
}

class EditorManager extends modchart.Manager {
    override public function new() {
        Manager.instance = this;

		addPlayfield();
    }
}

trace("Loaded Item Script: funkinModifier");

function getItemTypeName() {
    return "funkinModifier";
}
function getEventNameFromItem(item) {
    return "tweenModPercent";
}

var setup = false;

function setupDefaultsEditor() {
    if (!setup) {
        
        var funkin_modchart_instance:EditorManager = new EditorManager();
        //funkin_modchart_instance.setPercent("arrowPathDivisions", 8, -1); //shit is way too slow
        //funkin_modchart_instance.renderArrowPaths = true;
        Adapter.instance = new EditorAdapter();
		Adapter.instance.onModchartingInitialization();
        Adapter.instance.downscroll = downscroll;
        Adapter.instance.strumLines = strumLines;
        Adapter.instance.camHUD = camHUD;
        Adapter.instance.scrollSpeed = PlayState.SONG.scrollSpeed;
        // On your create function.
        add(funkin_modchart_instance);

        //funkin_modchart_instance.addModifier("drunk", -1);
        //funkin_modchart_instance.setPercent("drunk", 2, -1);

        //funkin_modchart_instance.setPercent("reverse", 1, -1);

        setup = true;
    }
}

function setupItemsFromXMLGame(xml) {
    for (node in xml.elementsNamed("FunkinModifier")) {
    
        /*
        createModchartItem(node.get("name") + ".value", "value", "modifier", Std.parseFloat(node.get("value")), modifier);
        for (submod in subMods) {
            createModchartItem(node.get("name") + "." + submod.name, submod.name, "modifier", submod.value, submod);
        }
        */
    }
}

function setupItemsFromXMLEditor(xml) {
    for (node in xml.elementsNamed("FunkinModifier")) {
        var tlStartIndex = timelineList.length;

        var item = createTimelineItem(node.get("name"), "funkinModifier", node.get("mod"));
        item.playFieldID = Std.parseInt(node.get("playFieldID"));
        item.modClass = node.get("modClass");
        item.defaultValue = Std.parseFloat(node.get("value"));

        if (StringTools.trim(item.modClass) != "") {
            Manager.instance.addModifier(item.modClass, item.playFieldID);
            Manager.instance.setPercent(item.object, item.defaultValue, item.playFieldID);
        }

        timelineGroups.push({
            startIndex: tlStartIndex,
            endIndex: timelineList.length,
            color: FlxColor.fromString(node.get("color")),
            bg: null
        });
    }
}

function copyXMLItems(xml, output) {
    for (e in xml.elementsNamed("FunkinModifier")) {

        var event = Xml.createElement("FunkinModifier");
        for (att in e.attributes()) {
            event.set(att, e.get(att));
        }

        output.addChild(event);
    }
}

function updateItem(item, i) {
    var text = timelineUIList[i].valueText;
    if (text != null) {
        text.text = Std.string(FlxMath.roundDecimal(item.currentValue, 2));
    }

    //item.object.value = item.currentValue;
    Manager.instance.setPercent(item.object, item.currentValue, item.playFieldID);
}

function reloadItems() {
    
}

function postXMLLoad(xml) {
    
}
function postXMLLoadGame(xml) {
    
}
function onFlipScroll(isDownscroll) {
    Adapter.instance.downscroll = downscroll;
}

//edit menu stuff
function isEditable() { return true; }
function getXMLNodeName() {return "FunkinModifier";}
function getEditButtonText() { return "Add FunkinModchart Modifier"; }

function setupItemData(data, node) {
    data.file = node.get("modClass");
    data.mod = node.get("mod");
    data.value = Std.parseFloat(node.get("value"));
    data.strumLineID = Std.parseInt(node.get("strumLineID"));
    data.playFieldID = Std.parseInt(node.get("playFieldID"));
}
function setupDefaultItemData(data) {
    data.value = 0;
    data.strumLineID = -1;
    data.playFieldID = -1;
    data.mod = "";
}

function getAvailableFiles() {
    var files = [];

    for (name => cl in ModifierGroup.GLOBAL_MODIFIERS) {
        files.push(name);
    }
    
    return files;
}

function getEditDisplayName() { return "FunkinModifier"; }
function getFolderDisplayName() { return ""; }

function setupEditMenu(data, itemButton) {
    for (shit in itemButton.labels) {
        if (shit[0] == itemButton.fileInput) {
            shit[1].text = "Registered Mod Class (if needed)";
        }
    }

    itemButton.descText.text = "";

    var modInput = new UIAutoCompleteTextBox(16 + 216, 34, data.mod, 200, 32, []);
    itemButton.addLabelOn(modInput, "Mod Name");
    itemButton.members.push(modInput);
    itemButton.menuObjects.set("modInput", modInput);

    var valueInput = new UINumericStepper(16, 100, data.value, 0, 6, null, null, 200);
    itemButton.addLabelOn(valueInput, "Default Value");
    itemButton.members.push(valueInput);
    itemButton.menuObjects.set("valueInput", valueInput);

    var strumLineIDInput = new UINumericStepper(16, 166, data.strumLineID, 0, 0, -1, null, 200);
    itemButton.addLabelOn(strumLineIDInput, "StrumLine ID");
    itemButton.members.push(strumLineIDInput);
    itemButton.menuObjects.set("strumLineIDInput", strumLineIDInput);

    var playFieldIDInput = new UINumericStepper(16, 166 + 66, data.playFieldID, 0, 0, -1, null, 200);
    itemButton.addLabelOn(playFieldIDInput, "PlayField ID");
    itemButton.members.push(playFieldIDInput);
    itemButton.menuObjects.set("playFieldIDInput", playFieldIDInput);
}

function updateMenuPositions(itemButton) {
    itemButton.follow(itemButton, itemButton.menuObjects.get("modInput"), 16 + 216, 100);
    itemButton.follow(itemButton, itemButton.menuObjects.get("valueInput"), 16, 100);
    itemButton.follow(itemButton, itemButton.menuObjects.get("strumLineIDInput"), 16, 166);
    itemButton.follow(itemButton, itemButton.menuObjects.get("playFieldIDInput"), 16, 166 + 66);
}
function getMenuHeight() {
    return 166 + 66 + 66;
}
function getBaseWindowHeight() {
    return 320;
}

function updateEditItem(data, itemButton) {

}

function setDataValues(data, itemButton) {
    for (name in ["valueInput", "strumLineIDInput", "playFieldIDInput"]) {
        var stepper = itemButton.menuObjects.get(name);
        stepper.__onChange(stepper.label.text);
    }

    data.mod = itemButton.menuObjects.get("modInput").label.text;
    data.value = itemButton.menuObjects.get("valueInput").value;
    data.strumLineID = itemButton.menuObjects.get("strumLineIDInput").value;
    data.playFieldID = itemButton.menuObjects.get("playFieldIDInput").value;
}

function createNodeFromData(data) {
    var node = Xml.createElement("FunkinModifier");
    node.set("name", data.name);
    node.set("modClass", data.file);
    node.set("color", data.colorString);

    node.set("mod", data.mod);
    node.set("value", data.value);
    node.set("strumLineID", data.strumLineID);
    node.set("playFieldID", data.playFieldID);

    return node;
}