//
import Modifier;
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

trace("Loaded Item Script: modifier");

public var noteModchart = false;

function getItemTypeName() {
    return "modifier";
}
function getEventNameFromItem(item) {
    return "tweenModifierValue";
}

function setupItemsFromXML(xml) {
    for (node in xml.elementsNamed("Modifier")) {
        if (!noteModchart) {
            noteModchart = true;
            importScript("data/scripts/noteModchartManager.hx");
            useNotePaths = true;
        }

        var subMods = [];
        for (sub in node.elementsNamed("SubMod")) {
            subMods.push(new SubModifier(sub.get("name"), Std.parseFloat(sub.get("value"))));
        }
        var modifier = new Modifier(
            node.get("name"), 
            Std.parseFloat(node.get("value")),
            Std.parseInt(node.get("strumLineID")),
            Std.parseInt(node.get("strumID")),
            subMods,
            node.get("modifier")
        );
        modTable.addModifier(modifier);

        var tlStartIndex = timelineList.length;

        var item = createTimelineItem(node.get("name") + ".value", "modifier", modifier);
        item.property = "";
        item.defaultValue = Std.parseFloat(node.get("value"));
        for (submod in subMods) {
            var subItem = createTimelineItem(node.get("name") + "." + submod.name, "modifier", submod);
            subItem.property = submod.name;
            subItem.defaultValue = submod.value;
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
    for (e in xml.elementsNamed("Modifier")) {

        var event = Xml.createElement("Modifier");
        for (att in e.attributes()) {
            event.set(att, e.get(att));
        }

        for (node in e.elementsNamed("SubMod")) {
            var prop = Xml.createElement("SubMod");
            for (att in node.attributes()) {
                prop.set(att, node.get(att));
            }
            event.addChild(prop);
        }

        output.addChild(event);
    }
}

function updateItem(item, i) {
    var text = timelineUIList[i].valueText;
    if (text != null) {
        text.text = Std.string(FlxMath.roundDecimal(item.currentValue, 2));
    }

    item.object.value = item.currentValue;
}

function postXMLLoad(xml) {
    if (noteModchart) initModchart();
}
function onFlipScroll(isDownscroll) {
    if (noteModchart) updateNotePaths();
}

//edit menu stuff
function isEditable() { return true; }
function getXMLNodeName() {return "Modifier";}
function getEditButtonText() { return "Add Note Modifier"; }

function setupItemData(data, node) {
    data.file = node.get("modifier");
    data.value = Std.parseFloat(node.get("value"));
    data.strumLineID = Std.parseInt(node.get("strumLineID"));
    data.strumID = Std.parseInt(node.get("strumID"));
    data.subMods = [];
    for (submod in node.elementsNamed("SubMod")) {
        data.subMods.push({
            name: submod.get("name"),
            value: Std.parseFloat(submod.get("value"))
        });
    }
}
function setupDefaultItemData(data) {
    data.value = 0;
    data.strumLineID = -1;
    data.strumID = -1;
    data.subMods = [];
}

function getAvailableFiles() {
    var files = [];
    for (path in Paths.getFolderContent('modifiers/', true, null)) {
        if (Path.extension(path) == "vert" || Path.extension(path) == "frag") {
            var file = CoolUtil.getFilename(path);
            if (!files.contains(file)) {
                files.push(file);
            }
        }
    }
    return files;
}

function getEditDisplayName() { return "Modifier"; }
function getFolderDisplayName() { return "(modifiers/)"; }

function setupEditMenu(data, itemButton) {
    var valueInput = new UINumericStepper(16, 100, data.value, 0, 6, null, null, 200);
    itemButton.addLabelOn(valueInput, "Default Value");
    itemButton.members.push(valueInput);
    itemButton.menuObjects.set("valueInput", valueInput);

    var strumLineIDInput = new UINumericStepper(16, 166, data.strumLineID, 0, 0, -1, null, 200);
    itemButton.addLabelOn(strumLineIDInput, "StrumLine ID");
    itemButton.members.push(strumLineIDInput);
    itemButton.menuObjects.set("strumLineIDInput", strumLineIDInput);

    var strumIDInput = new UINumericStepper(16, 166 + 66, data.strumID, 0, 0, -1, null, 200);
    itemButton.addLabelOn(strumIDInput, "Strum ID");
    itemButton.members.push(strumIDInput);
    itemButton.menuObjects.set("strumIDInput", strumIDInput);
}

function updateMenuPositions(itemButton) {
    itemButton.follow(itemButton, itemButton.menuObjects.get("valueInput"), 16, 100);
    itemButton.follow(itemButton, itemButton.menuObjects.get("strumLineIDInput"), 16, 166);
    itemButton.follow(itemButton, itemButton.menuObjects.get("strumIDInput"), 16, 166 + 66);
}
function getMenuHeight() {
    return 166 + 66 + 66;
}
function getBaseWindowHeight() {
    return 320;
}

function updateEditItem(data, itemButton) {
    var fileExists = false;
    var iniExists = false;
    var iniData = ["" => ""];
    if (Assets.exists("modifiers/" + data.file + ".vert") || Assets.exists("modifiers/" + data.file + ".frag")) {
        fileExists = true;
    }
    if (Assets.exists("modifiers/" + data.file + ".ini")) {
        iniExists = true;
        iniData = IniUtil.parseAsset("modifiers/" + data.file + ".ini");
    }

    //TODO: make sure ini stuff is sorted same as text file
    //maybe just parse it myself

    if (iniExists) {
        itemButton.descText.text = iniData.exists("desc") ? StringTools.replace(iniData.get("desc"), "#", "\n") : "";
    } else {
        itemButton.descText.text = fileExists ? "" : "\"" + data.file + "\" could not found!";
    }

    for (obj in itemButton.extraValues) {
        itemButton.members.remove(obj);
        obj.destroy();
    }
    for (obj in itemButton.extraLabels) {
        itemButton.members.remove(obj);
        obj.destroy();
    }
    itemButton.extraValues = [];
    itemButton.extraValuesList = [];
    itemButton.extraLabels = [];

    for (key => val in iniData) {
        if (key != "desc" && key != "") {
            var input = new UINumericStepper(16, 100, Std.parseFloat(val), 0, 6, null, null, 200);
            itemButton.members.push(input);
            itemButton.extraValues.push(input);
            itemButton.extraValuesList.push(key);

            var label:UIText = new UIText(0, 0, 0, key);
            itemButton.members.push(label);
            itemButton.extraLabels.push(label);
        }
    }

    for (prop in data.subMods) {
        if (itemButton.extraValuesList.contains(prop.name)) {
            var inputBox = itemButton.extraValues[itemButton.extraValuesList.indexOf(prop.name)];
            inputBox.value = prop.value;
        }
    }
    data.subMods = []; //temp remove to clear out any properties that shouldnt be there
    for (i => names in itemButton.extraValuesList) {
        data.subMods.push({
            name: names,
            value: itemButton.extraValues[i].value
        });
    }
}

function setDataValues(data, itemButton) {
    for (name in ["valueInput", "strumLineIDInput", "strumIDInput"]) {
        var stepper = itemButton.menuObjects.get(name);
        stepper.__onChange(stepper.label.text);
    }

    data.value = itemButton.menuObjects.get("valueInput").value;
    data.strumLineID = itemButton.menuObjects.get("strumLineIDInput").value;
    data.strumID = itemButton.menuObjects.get("strumIDInput").value;

    for (i => prop in data.subMods) {
        var stepper = itemButton.extraValues[i];
        stepper.__onChange(stepper.label.text);
        prop.value = stepper.value;
    }
}

function createNodeFromData(data) {
    var node = Xml.createElement("Modifier");
    node.set("name", data.name);
    node.set("modifier", data.file);
    node.set("color", data.colorString);

    node.set("value", data.value);
    node.set("strumLineID", data.strumLineID);
    node.set("strumID", data.strumID);

    for (prop in data.subMods) {
        var child = Xml.createElement("SubMod");
        child.set("name", prop.name);
        child.set("value", prop.value);
        node.addChild(child);
    }

    return node;
}