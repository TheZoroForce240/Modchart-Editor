//
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UINumericStepper;
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UICheckbox;

trace("Loaded Event Script: tweenCameraPosition");

function createEventEditor(name, step, item) {
    var data = name.split(".");
    return {
        "type": "tweenCameraPosition",
        "step": step,
        "name": data[0],
        "property": data[1],
        "value": 0,
        "time": 4,
        "ease": "cubeInOut",
        "startValue": item.currentValue,
        "lastValue": 0
    };
}

function updateEventEditor(currentStep, e, item) {
    if (currentStep < e.step + e.time) {
        var easeFunc:Float->Float = CoolUtil.flxeaseFromString(e.ease, "");

        var startVMult:Float = (e.DI_startValue != null && e.DI_startValue && downscroll) ? -1.0 : 1.0;
        var vMult:Float = (e.DI_value != null && e.DI_value && downscroll) ? -1.0 : 1.0;

        var l = (currentStep - e.step) * ((1) / ((e.step+e.time) - e.step));
        var newValue = FlxMath.lerp(e.startValue*startVMult, e.value*vMult, easeFunc(l));

        item.currentValue = newValue;
    } else {
        var vMult:Float = (e.DI_value != null && e.DI_value && downscroll) ? -1.0 : 1.0;
        item.currentValue = e.value*vMult;
    }
}

function copyEventEditor(e) {
    return {
        "type": e.type,
        "step": e.step,
        "name": e.name,
        "property": e.property,
        "value": e.value,
        "time": e.time,
        "ease": e.ease,
        "startValue": e.startValue,
        "lastValue": e.lastValue,
        "DI_value": e.DI_value,
        "DI_startValue": e.DI_startValue
    };
}

function eventFromXMLEditor(node) {

    var event = {
        "type": node.get("type"),
        "step": Std.parseFloat(node.get("step")),
        "name": node.get("name"),
        "property": node.get("property"),
        "value": Std.parseFloat(node.get("value")),
        "time": Std.parseFloat(node.get("time")),
        "ease": node.get("ease"),
        "startValue": Std.parseFloat(node.get("startValue")),
        "lastValue": 0
    };

    if (node.exists("DI_startValue")) {
        event.DI_startValue = node.get("DI_startValue") == "true";
    }
    if (node.exists("DI_value")) {
        event.DI_value = node.get("DI_value") == "true";
    }

    return event;
}

function eventToXMLEditor(node, e) {
    node.set("name", e.name);
    node.set("property", e.property);
    node.set("value", e.value);
    node.set("time", e.time);
    node.set("ease", e.ease);
    node.set("startValue", e.startValue);
    
    if (e.DI_startValue != null && e.DI_startValue) {
        node.set("DI_startValue", e.DI_startValue);
    }
    if (e.DI_value != null && e.DI_value) {
        node.set("DI_value", e.DI_value);
    }
}
function getItemName(e) {
    return e.name + "." + e.property;
}
function getDisplayName(e) {
    return "Tween Camera Position";
}
function getEventWindowWidth() {
    return 960;
}
function getEventWindowHeight() {
    return 420;
}
function setupEventWindow(event, propertyMap, windowData) {
    windowData.state.add(new UIText(windowData.curX, windowData.curY, 0, getItemName(event), 24));
    windowData.curY += 28 + 50;

    var temp = windowData.curY;
    windowData.curX += 115;
    
    windowData.curY -= 50;
    windowData.createEaseBoxes();
    windowData.curY += 50;

    windowData.addStepper("startValue", "Start Value", event.startValue);

    windowData.curX -= 65;
    windowData.addCheckbox("DI_startValue", "Inverse on Downscroll?", event.DI_startValue != null ? event.DI_startValue : false);
    windowData.curX += 65;

    windowData.curY = temp;
    windowData.curX += 600;
    windowData.addStepper("value", "End Value", event.value);
    
    windowData.curX -= 65;
    windowData.addCheckbox("DI_value", "Inverse on Downscroll?", event.DI_value != null ? event.DI_value : false);
    windowData.curX += 65;

    windowData.curY += 100;
    var dropdown = new UIDropDown(windowData.windowSpr.x+(windowData.windowSpr.bWidth/2)-150, windowData.curY, 320, 32, easeList, easeList.indexOf(event.ease));
    propertyMap.set("ease", dropdown);
    var changeEaseFunc = windowData.changeEaseFunc;
    dropdown.onChange = function(index) {
        changeEaseFunc(CoolUtil.flxeaseFromString(easeList[index], ""));
    };
    windowData.state.add(dropdown);

    windowData.curY -= 28;
    windowData.addStepper("time", "Tween Length (steps)", event.time, 1, 4);
}
function saveEventWindow(event, propertyMap) {
    event.startValue = propertyMap.get("startValue").value;
    event.value = propertyMap.get("value").value;
    event.ease = easeList[propertyMap.get("ease").index];
    event.time = propertyMap.get("time").value;

    event.DI_startValue = propertyMap.get("DI_startValue").checked;
    event.DI_value = propertyMap.get("DI_value").checked;
}