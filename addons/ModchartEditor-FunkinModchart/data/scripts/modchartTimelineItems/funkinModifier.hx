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

import funkin.backend.system.macros.DefinesMacro;
if (!DefinesMacro.defines.exists("funkin-modchart")) {
    trace("FunkinModchart not found, skipping Item Script for: funkinModifier");
    return;
}

import modchart.Manager;
import modchart.Config;
import modchart.engine.modifiers.ModifierGroup;
import modchart.backend.standalone.Adapter;
import EditorAdapter;

trace("Loaded Item Script: funkinModifier");

function getItemTypeName() {
    return "funkinModifier";
}
function getEventNameFromItem(item) {
    return "tweenModPercent";
}

var setup = false;

function setupItemsFromXMLGame(xml) {
    for (node in xml.elementsNamed("FunkinModifier")) {
        if (!setup) {
            Adapter.instance = new Codename();
            var funkin_modchart_instance = new Manager();
            add(funkin_modchart_instance);
            setup = true;
        }
    
        var item = createModchartItem(node.get("name"), node.get("mod"), "funkinModifier", Std.parseFloat(node.get("value")), node.get("mod"));
        item.strumLineID = Std.parseInt(node.get("strumLineID"));
        item.playFieldID = Std.parseInt(node.get("playFieldID"));

        if (StringTools.trim(node.get("modClass")) != "") {
            Manager.instance.addModifier(node.get("modClass"), item.playFieldID);
            Manager.instance.setPercent(item.object, item.value, item.strumLineID, item.playFieldID);
        }
    }
}

function setupItemsFromXMLEditor(xml) {
    for (node in xml.elementsNamed("FunkinModifier")) {
         if (!setup) {
			var funkin_modchart_instance = new Manager();
			Adapter.instance = new EditorAdapter().superClass;
        	Adapter.instance.onModchartingInitialization();
			Adapter.instance.downscroll = downscroll;
        	Adapter.instance.strumLines = strumLines;
        	Adapter.instance.camHUD = camHUD;
        	Adapter.instance.scrollSpeed = PlayState.SONG.scrollSpeed;
			//Adapter.instance = new EditorAdapter();
           
            Config.RENDER_ARROW_PATHS = true;
            add(funkin_modchart_instance);
            setup = true;
        }
        var tlStartIndex = timelineList.length;

        var item = createTimelineItem(node.get("name"), "funkinModifier", node.get("mod"));
        item.strumLineID = Std.parseInt(node.get("strumLineID"));
        item.playFieldID = Std.parseInt(node.get("playFieldID"));
        item.modClass = node.get("modClass");
        item.defaultValue = Std.parseFloat(node.get("value"));

        if (StringTools.trim(item.modClass) != "") {
            Manager.instance.addModifier(item.modClass, item.playFieldID);
            Manager.instance.setPercent(item.object, item.defaultValue, item.strumLineID, item.playFieldID);
        }

        timelineGroups.push({
            startIndex: tlStartIndex,
            endIndex: timelineList.length,
            color: FlxColor.fromString(node.get("color")),
            bg: null
        });
    }
}

function copyXMLItems(xml, output, package) {
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

    Manager.instance.setPercent(item.object, item.currentValue, item.strumLineID, item.playFieldID);
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