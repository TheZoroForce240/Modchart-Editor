//
import Modifier;
import Xml;

trace("Loaded Item Script: modifier");

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
function copyXML(xml, output) {
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