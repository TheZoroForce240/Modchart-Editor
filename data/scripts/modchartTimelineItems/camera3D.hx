//

trace("Loaded Item Script: camera3D");

function getItemTypeName() {
    return "camera3D";
}
function getEventNameFromItem(item) {
    return "tweenCameraPosition";
}

var enabled = false;

function setupDefaults() {
    
    var tlStartIndex = timelineList.length;

    var x = createTimelineItem("camera.x", "camera3D", null);
    x.property = "x";
    var y = createTimelineItem("camera.y", "camera3D", null);
    y.property = "y";
    var z = createTimelineItem("camera.z", "camera3D", null);
    z.property = "z";
    z.defaultValue = -1;

    timelineGroups.push({
        startIndex: tlStartIndex,
        endIndex: timelineList.length,
        color: 0x004CFF,
        bg: null
    });
}

function updateItem(item, i) {
    if (enabled) {
        var text = timelineUIList[i].valueText;
        if (text != null) {
            text.text = Std.string(FlxMath.roundDecimal(item.currentValue, 2));
        }

        switch(item.property) {
            case "x":
                modchartCamera.position.x = item.currentValue;
            case "y":
                modchartCamera.position.y = item.currentValue;
            case "z":
                modchartCamera.position.z = item.currentValue;
        }
    }    
}