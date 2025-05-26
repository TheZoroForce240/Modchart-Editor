//

//try to keep it more organized and easier to add custom event types

//importing files will merge the code together so it will be in the same scope
//ModchartEditor.hx
function eventCreate(step, name) {
    var e = null;
    switch(name) {
        case "addCameraZoom":
			e = {
				"type": "addCameraZoom",
				"step": step,
				"value": 0.01,
				"triggered": false
			};
		case "addHUDZoom":
			e = {
				"type": "addHUDZoom",
				"step": step,
				"value": 0.01,
				"triggered": false
			};
		default:
            var item = timelineItems[timelineIndexMap.get(name)];
            switch(item.type) {
                case "shader" | "modifier":
                    var data = name.split(".");
                    e = {
                        "type": item.type == "shader" ? "tweenShaderProperty" : "tweenModifierValue",
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
    }
    return e;
}
//ModchartEditor.hx
function eventUpdate(currentStep, e, name) {
    switch(e.type) {
        case "setShaderProperty" | "setModifierValue":
            timelineItems[timelineIndexMap.get(name)].currentValue = e.value;
        case "tweenShaderProperty" | "tweenModifierValue":

            if (currentStep < e.step + e.time) {
                if (!easeMap.exists(e.ease)) {
                    easeMap.set(e.ease, CoolUtil.flxeaseFromString(e.ease, ""));
                }
                var easeFunc:Float->Float = easeMap.get(e.ease);

                var startVMult:Float = (e.DI_startValue != null && e.DI_startValue && downscroll) ? -1.0 : 1.0;
                var vMult:Float = (e.DI_value != null && e.DI_value && downscroll) ? -1.0 : 1.0;

                var l = 0 + (currentStep - e.step) * ((1 - 0) / ((e.step+e.time) - e.step));
                var newValue = FlxMath.lerp(e.startValue*startVMult, e.value*vMult, easeFunc(l));

                timelineItems[timelineIndexMap.get(name)].currentValue = newValue;
            } else {
                var vMult:Float = (e.DI_value != null && e.DI_value && downscroll) ? -1.0 : 1.0;
                timelineItems[timelineIndexMap.get(name)].currentValue = e.value*vMult;
            }

        case "addCameraZoom":
            if (!e.triggered && Math.floor(currentStep) == Math.floor(e.step)) {
                camGame.zoom += e.value;
                e.triggered = true; 
            }
            if (Math.floor(currentStep) != Math.floor(e.step)) {
                e.triggered = false; //reset once the step has changed
            }
        case "addHUDZoom":
            if (!e.triggered && Math.floor(currentStep) == Math.floor(e.step)) {
                camHUD.zoom += e.value;
                e.triggered = true;   
            }
            if (Math.floor(currentStep) != Math.floor(e.step)) {
                e.triggered = false; //reset once the step has changed
            }
    }
}
//ModchartEditor.hx
function eventCopy(e) {
	var newEvent = null;
	switch(e.type) {
		case "addCameraZoom" | "addHUDZoom":
			newEvent = {
				"type": e.type,
				"step": e.step,
				"value": e.value,
				"triggered": false
			};
		case "setShaderProperty" | "setModifierValue":
			newEvent = {
				"type": e.type,
				"step": e.step,
				"name": e.name,
				"property": e.property,
				"value": e.value,
				"lastValue": e.lastValue
			};
		case "tweenShaderProperty" | "tweenModifierValue":
			newEvent = {
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
	return newEvent;
}
//ModchartEditor.hx
function loadEventFromXML(event) {
    switch(event.get("type")) {
        case "setShaderProperty" | "setModifierValue":
            var n = event.get("name") + "." + event.get("property");
            if (!timelineIndexMap.exists(n)) {
                trace("skipped event for \"" + n + "\"");
                return;
            }

            events.push({
                "type": event.get("type"),
                "step": Std.parseFloat(event.get("step")),
                "name": event.get("name"),
                "property": event.get("property"),
                "value": Std.parseFloat(event.get("value")),
                "lastValue": timelineItems[timelineIndexMap.get(n)].currentValue
            });
            timelineItems[timelineIndexMap.get(n)].currentValue = Std.parseFloat(event.get("value"));

        case "tweenShaderProperty" | "tweenModifierValue":
            var n = event.get("name") + "." + event.get("property");

            if (!timelineIndexMap.exists(n)) {
                trace("skipped event for \"" + n + "\"");
                return;
            }

            events.push({
                "type": event.get("type"),
                "step": Std.parseFloat(event.get("step")),
                "name": event.get("name"),
                "property": event.get("property"),
                "value": Std.parseFloat(event.get("value")),
                "time": Std.parseFloat(event.get("time")),
                "ease": event.get("ease"),
                "startValue": event.exists("startValue") ? Std.parseFloat(event.get("startValue")) : timelineItems[timelineIndexMap.get(n)].currentValue,
                "lastValue": timelineItems[timelineIndexMap.get(n)].currentValue
            });

            //DI = Downscroll Inverse
            if (event.exists("DI_startValue")) {
                events[events.length-1].DI_startValue = event.get("DI_startValue") == "true";
            }
            if (event.exists("DI_value")) {
                events[events.length-1].DI_value = event.get("DI_value") == "true";
            }

            if (events[events.length-1].step <= -1) {
                events[events.length-1].step = 0;
            }

            timelineItems[timelineIndexMap.get(n)].currentValue = Std.parseFloat(event.get("value"));

        case "addCameraZoom" | "addHUDZoom":
            events.push({
                "type": event.get("type"),
                "step": Std.parseFloat(event.get("step")),
                "value": Std.parseFloat(event.get("value")),
                "triggered": false
            });
    }
}
//ModchartEditor.hx
function eventToXML(node, e) {
    switch(e.type) {
        case "setShaderProperty" | "setModifierValue":
            node.set("name", e.name);
            node.set("property", e.property);
            node.set("value", e.value);
        case "tweenShaderProperty" | "tweenModifierValue":
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
        case "addCameraZoom" | "addHUDZoom":
            node.set("value", e.value);
    }
}

//Shared
function getEventTimelineName(e) {
    var n = e.type;
    switch(e.type) {
        case "setShaderProperty" | "tweenShaderProperty" | "setModifierValue" | "tweenModifierValue":
            n = e.name + "." + e.property;
    }
    return n;
}


//ModchartEventEditSubstate.hx
function setWindowSizeForEvent(e) {
    switch(e.type) {
		case "setShaderProperty" | "addCameraZoom" | "addHUDZoom" | "setModifierValue":
			winWidth = 520;
			winHeight = 300;
		case "tweenShaderProperty" | "tweenModifierValue":
			winHeight = 420;
	}
}
//ModchartEventEditSubstate.hx
function getEventDisplayName(e) {
    var displayName = "";
	switch(e.type) {
		case "addCameraZoom": 
			displayName = "Add Camera Zoom";
		case "addHUDZoom": 
			displayName = "Add HUD Zoom";
		case "setShaderProperty": 
			displayName = "Set Shader Property";
		case "setModifierValue": 
			displayName = "Set Modifier Property";
		case "tweenShaderProperty": 
			displayName = "Tween Shader Property";
		case "tweenModifierValue": 
			displayName = "Tween Modifier Property";
	}
    return displayName;
}
//ModchartEventEditSubstate.hx
function setupEventEditMenu(event) {
    var displayName = getEventDisplayName(CURRENT_EVENT.event);
    
    switch(event.type) {
		case "addCameraZoom" | "addHUDZoom":
			add(new UIText(curX, curY, 0, displayName, 24));
			curY += 28 + 50;

			curX = windowSpr.x + (windowSpr.bWidth/2) - 50;
			addStepper("value", "Value", event.value, 0.01, 0.1);

		case "setShaderProperty" | "setModifierValue":
			add(new UIText(curX, curY, 0, displayName, 24));
			curY += 28 + 50;

			curX = windowSpr.x + (windowSpr.bWidth/2) - 50;
			addStepper("value", "Value", event.value);

		case "tweenShaderProperty" | "tweenModifierValue":
			add(new UIText(curX, curY, 0, displayName, 24));
			curY += 28 + 50;

			var temp = curY;
			curX += 115;
			
			curY -= 50;
			createEaseBoxes();
			curY += 50;

			addStepper("startValue", "Start Value", event.startValue);

			curX -= 65;
			addCheckbox("DI_startValue", "Inverse on Downscroll?", event.DI_startValue != null ? event.DI_startValue : false);
			curX += 65;

			curY = temp;
			curX += 600;
			addStepper("value", "End Value", event.value);
			
			curX -= 65;
			addCheckbox("DI_value", "Inverse on Downscroll?", event.DI_value != null ? event.DI_value : false);
			curX += 65;

			curY += 100;
			var dropdown = new UIDropDown(windowSpr.x+(windowSpr.bWidth/2)-150, curY, 320, 32, easeList, easeList.indexOf(event.ease));
			propertyMap.set("ease", dropdown);
			dropdown.onChange = function(index) {
				easeFunc = CoolUtil.flxeaseFromString(easeList[index], "");
			};
			add(dropdown);

			curY -= 28;
			addStepper("time", "Tween Length (steps)", event.time, 1, 4);
	}
}
//ModchartEventEditSubstate.hx
function saveEventEdit(event) {
    switch(event.type) {
        case "setShaderProperty" | "addCameraZoom" | "addHUDZoom" | "setModifierValue":
            event.value = propertyMap.get("value").value;
        case "tweenShaderProperty" | "tweenModifierValue":
            event.startValue = propertyMap.get("startValue").value;
            event.value = propertyMap.get("value").value;
            event.ease = easeList[propertyMap.get("ease").index];
            event.time = propertyMap.get("time").value;

            event.DI_startValue = propertyMap.get("DI_startValue").checked;
            event.DI_value = propertyMap.get("DI_value").checked;
    }
}