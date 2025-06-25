//
import funkin.editors.ui.UISubstateWindow;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UINumericStepper;
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UISprite;
import haxe.io.Path;
import haxe.io.Bytes;
import funkin.editors.ui.UICheckbox;
import funkin.editors.ui.UIColorwheel;
import funkin.editors.ui.UIWindow;
import funkin.editors.ui.UITextBox;
import funkin.editors.ui.UIAutoCompleteTextBox;
import funkin.backend.utils.IniUtil;
import Xml;

trace("Loaded Item Script: shader");

function getItemTypeName() {
    return "shader";
}
function getEventNameFromItem(item) {
    return "tweenShaderProperty";
}

function setupItemsFromXMLGame(xml) {
    for (node in xml.elementsNamed("Shader")) {

        var path = "modcharts/" + node.get("shader");
        var s = new CustomShader(path);
        
        for (prop in node.elementsNamed("Property")) {
            createModchartItem(node.get("name") + "." + prop.get("name"), prop.get("name"), "shader", Std.parseFloat(prop.get("value")), s);
            s.hset(prop.get("name"), Std.parseFloat(prop.get("value")));
        }

        if (node.exists("camGame") && node.get("camGame") == "true") {
            camGame.addShader(s);
        }
        if (node.exists("camHUD") && node.get("camHUD") == "true") {
            camHUD.addShader(s);
        }
        if (node.exists("camOther") && node.get("camOther") == "true") {
            camOther.addShader(s);
        }
    }
}

function setupItemsFromXMLEditor(xml) {
    for (node in xml.elementsNamed("Shader")) {

        var path = "modcharts/" + node.get("shader");
        var s = new CustomShader(path);

        var tlStartIndex = timelineList.length;
        
        for (prop in node.elementsNamed("Property")) {
            var n = node.get("name") + "." + prop.get("name");
            var item = createTimelineItem(n, getItemTypeName(), s);
            item.property = prop.get("name");
            item.defaultValue = Std.parseFloat(prop.get("value"));
        }

        if (node.exists("camGame") && node.get("camGame") == "true") {
            camGame.addShader(s);
        }
        if (node.exists("camHUD") && node.get("camHUD") == "true") {
            camHUD.addShader(s);
        }
        if (node.exists("camOther") && node.get("camOther") == "true") {
            camOther.addShader(s);
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
    for (e in xml.elementsNamed("Shader")) {

        var event = Xml.createElement("Shader");
        for (att in e.attributes()) {
            event.set(att, e.get(att));
        }

        if (package) {
            var path = "shaders/modcharts/" + event.get("shader");
            if (Assets.exists(path+".frag")) {
                event.set("fragCode", Bytes.ofString(Assets.getText(path+".frag")).toHex()); //ensures that shader code wont break xml parsing
            } else {
                event.set("fragCode", "");
            }
            if (Assets.exists(path+".vert")) {
                event.set("vertCode", Bytes.ofString(Assets.getText(path+".vert")).toHex());
            } else {
                event.set("vertCode", "");
            }
        }

        for (node in e.elementsNamed("Property")) {
            var prop = Xml.createElement("Property");
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

    item.object.hset(item.property, item.currentValue);
}

function reloadItems() {
    camGame._filters = [];
    camHUD._filters = [];
    camOther._filters = [];
}


//edit menu stuff
function isEditable() { return true; }
function getXMLNodeName() {return "Shader";}
function getEditButtonText() { return "Add Post Process Shader"; }

function setupItemData(data, node) {
    data.file = node.get("shader");
    data.camGame = node.get("camGame") == "true";
    data.camHUD = node.get("camHUD") == "true";
    data.camOther = node.get("camOther") == "true";
    data.properties = [];
    for (prop in node.elementsNamed("Property")) {
        data.properties.push({
            name: prop.get("name"),
            value: Std.parseFloat(prop.get("value"))
        });
    }
}
function setupDefaultItemData(data) {
    data.camGame = true;
    data.camHUD = false;
    data.camOther = false;
    data.properties = [];
}

function getAvailableFiles() {
    var files = [];
    for (path in Paths.getFolderContent('shaders/modcharts/', true, null)) {
        if (Path.extension(path) == "ini") {
            var file = CoolUtil.getFilename(path);
            if (!files.contains(file)) {
                files.push(file);
            }
        }
    }
    return files;
}

function getEditDisplayName() { return "Shader"; }
function getFolderDisplayName() { return "(shaders/modcharts/)"; }

function setupEditMenu(data, itemButton) {
    var camGameCheckbox = new UICheckbox(16, 100, "Use on Game Camera?", data.camGame);
    itemButton.members.push(camGameCheckbox);
    itemButton.menuObjects.set("camGameCheckbox", camGameCheckbox);

    var camHUDCheckbox = new UICheckbox(16, 166, "Use on HUD Camera?", data.camHUD);
    itemButton.members.push(camHUDCheckbox);
    itemButton.menuObjects.set("camHUDCheckbox", camHUDCheckbox);

    var camOtherCheckbox = new UICheckbox(16, 166 + 66, "Use on Other Camera?", data.camOther);
    itemButton.members.push(camOtherCheckbox);
    itemButton.menuObjects.set("camOtherCheckbox", camOtherCheckbox);
}

function updateMenuPositions(itemButton) {
    itemButton.follow(itemButton, itemButton.menuObjects.get("camGameCheckbox"), 16, 80);
    itemButton.follow(itemButton, itemButton.menuObjects.get("camHUDCheckbox"), 16, 120);
    itemButton.follow(itemButton, itemButton.menuObjects.get("camOtherCheckbox"), 16, 160);
}
function getMenuHeight() {
    return 160 + 66;
}
function getBaseWindowHeight() {
    return 250;
}

function updateEditItem(data, itemButton) {
    var fileExists = false;
    var iniExists = false;
    var iniData = ["" => ""];
    if (Assets.exists("shaders/modcharts/" + data.file + ".vert") || Assets.exists("shaders/modcharts/" + data.file + ".frag")) {
        fileExists = true;
    }
    if (Assets.exists("shaders/modcharts/" + data.file + ".ini")) {
        iniExists = true;
        iniData = IniUtil.parseAsset("shaders/modcharts/" + data.file + ".ini");
    }

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

    for (prop in data.properties) {
        if (itemButton.extraValuesList.contains(prop.name)) {
            var inputBox = itemButton.extraValues[itemButton.extraValuesList.indexOf(prop.name)];
            inputBox.value = prop.value;
        }
    }
    data.properties = []; //temp remove to clear out any properties that shouldnt be there
    for (i => names in itemButton.extraValuesList) {
        data.properties.push({
            name: names,
            value: itemButton.extraValues[i].value
        });
    }
}

function setDataValues(data, itemButton) {

    data.camGame = itemButton.menuObjects.get("camGameCheckbox").checked;
    data.camHUD = itemButton.menuObjects.get("camHUDCheckbox").checked;
    data.camOther = itemButton.menuObjects.get("camOtherCheckbox").checked;

    for (i => prop in data.properties) {
        var stepper = itemButton.extraValues[i];
        stepper.__onChange(stepper.label.text);
        prop.value = stepper.value;
    }

}

function createNodeFromData(data) {
    var node = Xml.createElement("Shader");
    node.set("name", data.name);
    node.set("shader", data.file);
    node.set("color", data.colorString);

    node.set("camGame", data.camGame ? "true" : "false");
    node.set("camHUD", data.camHUD ? "true" : "false");
    node.set("camOther", data.camOther ? "true" : "false");

    for (prop in data.properties) {
        var child = Xml.createElement("Property");
        child.set("name", prop.name);
        child.set("value", prop.value);
        node.addChild(child);
    }

    return node;
}