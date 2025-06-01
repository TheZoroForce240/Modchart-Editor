//
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UINumericStepper;
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UICheckbox;

trace("Loaded Event Script: addHUDZoom");

function createEventEditor(name, step, item) {
    return {
        "type": "addHUDZoom",
        "step": step,
        "value": 0.01,
        "triggered": false
    };
}

function updateEventEditor(currentStep, e, item) {
    if (!e.triggered && Math.floor(currentStep) == Math.floor(e.step)) {
        camHUD.zoom += e.value;
        e.triggered = true;   
    }
    if (Math.floor(currentStep) != Math.floor(e.step)) {
        e.triggered = false; //reset once the step has changed
    }
}

function copyEventEditor(e) {
    return {
        "type": e.type,
        "step": e.step,
        "value": e.value,
        "triggered": false
    };
}

function eventFromXMLEditor(node) {
    return {
        "type": node.get("type"),
        "step": Std.parseFloat(node.get("step")),
        "value": Std.parseFloat(node.get("value")),
        "triggered": false
    };
}

function eventToXMLEditor(node, e) {
    node.set("value", e.value);
}
function getItemName(e) {
    return "addHUDZoom";
}
function getDisplayName(e) {
    return "Add HUD Zoom";
}
function getEventWindowWidth() {
    return 520;
}
function getEventWindowHeight() {
    return 300;
}
function setupEventWindow(event, propertyMap, windowData) {
    windowData.state.add(new UIText(windowData.curX, windowData.curY, 0, getDisplayName(event), 24));
    windowData.curY += 28 + 50;

    windowData.curX = windowData.windowSpr.x + (windowData.windowSpr.bWidth/2) - 50;
    windowData.addStepper("value", "Value", event.value, 0.01, 0.1);
}
function saveEventWindow(event, propertyMap) {
    event.value = propertyMap.get("value").value;
}