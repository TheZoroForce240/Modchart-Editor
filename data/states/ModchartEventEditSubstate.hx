//
import funkin.editors.ui.UISubstateWindow;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UINumericStepper;
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UICheckbox;

public static var easeList = [
	"linear",

	"quadIn",
	"quadOut",
	"quadInOut",

	"cubeIn",
	"cubeOut",
	"cubeInOut",

	"quartIn",
	"quartOut",
	"quartInOut",

	"quintIn",
	"quintOut",
	"quintInOut",

	"sineIn",
	"sineOut",
	"sineInOut",

	"bounceIn",
	"bounceOut",
	"bounceInOut",

	"circIn",
	"circOut",
	"circInOut",

	"expoIn",
	"expoOut",
	"expoInOut",

	"backIn",
	"backOut",
	"backInOut",

	"elasticIn",
	"elasticOut",
	"elasticInOut",

	"smoothStepIn",
	"smoothStepOut",
	"smoothStepInOut",

	"smootherStepIn",
	"smootherStepOut",
	"smootherStepInOut"
];

var propertyMap = ["" => null];

var eventEditWindowData = {
	curX: 0,
	curY: 0
};

function create() {	
	winTitle = "Edit Modchart Event - " + EVENT_EDIT_EVENT_SCRIPT.call("getDisplayName", [CURRENT_EVENT.event]);
	winWidth = EVENT_EDIT_EVENT_SCRIPT.call("getEventWindowWidth", []);
	winHeight = EVENT_EDIT_EVENT_SCRIPT.call("getEventWindowHeight", []);
}
function addLabelOn(ui:UISprite, text:String)
	add(new UIText(ui.x, ui.y - 24, 0, text));

function addStepperButtons(stepper:UINumericStepper, change1:Float, change2:Float = 0.0, w:Float = 32.0) {

	var leftButton = new UIButton(stepper.x-w, stepper.y, "<", function() {
		stepper.onChange(Std.string(stepper.value-change1));
	}, w); add(leftButton);

	if (change2 != 0.0) {
		var leftButton2 = new UIButton(leftButton.x-w, stepper.y, "<<", function() {
			stepper.onChange(Std.string(stepper.value-change2));
		}, w); add(leftButton2);
	}

	var rightButton = new UIButton(stepper.x+stepper.bWidth, stepper.y, ">", function() {
		stepper.onChange(Std.string(stepper.value+change1));
	}, w); add(rightButton);

	if (change2 != 0.0) {
		var rightButton2 = new UIButton(rightButton.x+rightButton.bWidth, stepper.y, ">>", function() {
			stepper.onChange(Std.string(stepper.value+change2));
		}, w); add(rightButton2);
	}
}

var useEaseBoxes = false;
var easeBoxes = [];
var easeWidth = 300;
var easeBoxWidth = 5;
var easeFunc = FlxEase.linear;

function postCreate() {
	propertyMap.clear();

	eventEditWindowData.curX = windowSpr.x + 20;
	eventEditWindowData.curY = windowSpr.y + 41;
	eventEditWindowData.state = this;
	eventEditWindowData.windowSpr = windowSpr;
	eventEditWindowData.addStepper = addStepper; //uhh maybe could have this better but just transferring funcs through the struct for easy access
	eventEditWindowData.addCheckbox = addCheckbox;
	eventEditWindowData.createEaseBoxes = createEaseBoxes;
	eventEditWindowData.changeEaseFunc = changeEaseFunc;

	EVENT_EDIT_EVENT_SCRIPT.call("setupEventWindow", [CURRENT_EVENT.event, propertyMap, eventEditWindowData]);

	trace(CURRENT_EVENT.event);

	var saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20, windowSpr.y + windowSpr.bHeight - 16 - 32, "Save & Close", function() {
		EVENT_EDIT_EVENT_SCRIPT.call("saveEventWindow", [CURRENT_EVENT.event, propertyMap]);
		EVENT_EDIT_CALLBACK();
		close();
	});
	saveButton.x -= saveButton.bWidth;
	add(saveButton);

	var closeButton = new UIButton(saveButton.x - 10, saveButton.y, "Close", function() {
		EVENT_EDIT_CANCEL_CALLBACK();
		close();
	});
	closeButton.color = 0xFFFF0000;
	closeButton.x -= closeButton.bWidth;
	add(closeButton);

	var deleteButton = new UIButton(windowSpr.x + 20, windowSpr.y + windowSpr.bHeight - 16 - 32, "Delete", function() {
		EVENT_DELETE_CALLBACK();
		close();
	});
	add(deleteButton);
}

function addStepper(name, label, value, ?stepperV1, ?stepperV2) {

	if (stepperV1 == null) stepperV1 = 0.1;
	if (stepperV2 == null) stepperV2 = 1;
	
	var text = new UIText(eventEditWindowData.curX, eventEditWindowData.curY, 0, label);
	add(text);
	eventEditWindowData.curY += 28;

	var numericStepper = new UINumericStepper(eventEditWindowData.curX, eventEditWindowData.curY, value, 1, 3, null, null, 120);
	add(numericStepper);
	eventEditWindowData.curY += 50;

	addStepperButtons(numericStepper, stepperV1, stepperV2, 32);

	text.x += numericStepper.bWidth/2;
	text.x -= text.width/2;

	propertyMap.set(name, numericStepper);
}

function addCheckbox(name, label, value) {
	var checkbox = new UICheckbox(eventEditWindowData.curX, eventEditWindowData.curY, label, value);
	add(checkbox);
	propertyMap.set(name, checkbox);
}


function createEaseBoxes() {
	useEaseBoxes = true;

	var easeText = new UIText(windowSpr.x+(windowSpr.bWidth/2), eventEditWindowData.curY, 0, "Ease");
	add(easeText);
	easeText.x -= easeText.width/2;

	for (i in 0...(easeWidth/easeBoxWidth)) {
		var spr = new FlxSprite();
		spr.makeSolid(easeBoxWidth, easeBoxWidth, -1);
		add(spr);
		spr.x = windowSpr.x + ((windowSpr.bWidth/2) - 150) + (easeBoxWidth/2) + (i * easeBoxWidth);
		spr.y = eventEditWindowData.curY + 40;
		easeBoxes.push(spr);
	}
	easeFunc = CoolUtil.flxeaseFromString(CURRENT_EVENT.event.ease, "");
}
function changeEaseFunc(newFunc) {
	easeFunc = newFunc;
}
function update(elapsed) {

	if (useEaseBoxes) {
		for (i in 0...easeBoxes.length) {
			var spr = easeBoxes[i];
	
			var value = easeFunc(i/easeBoxes.length)*100;
			if (propertyMap.get("value").value < propertyMap.get("startValue").value) value = -value + 100;
	
			spr.offset.y = CoolUtil.fpsLerp(spr.offset.y, value - 100, 0.1);
		}
	}

}