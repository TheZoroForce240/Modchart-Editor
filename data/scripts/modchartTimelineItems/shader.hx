//
import Xml;

trace("Loaded Item Script: shader");

function getItemTypeName() {
    return "shader";
}
function getEventNameFromItem(item) {
    return "tweenShaderProperty";
}

function setupItemsFromXML(xml) {
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
function copyXMLItems(xml, output) {
    for (e in xml.elementsNamed("Shader")) {

        var event = Xml.createElement("Shader");
        for (att in e.attributes()) {
            event.set(att, e.get(att));
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