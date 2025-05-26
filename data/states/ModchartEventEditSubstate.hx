//
import funkin.editors.ui.UISubstateWindow;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UINumericStepper;
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UICheckbox;
import ModchartEventTypes;

var propertyMap = ["" => null];

var curX = 0;
var curY = 0;

function create() {	
	winTitle = "Edit Modchart Event - " + getEventTimelineName(CURRENT_EVENT.event);
	winWidth = 960;

	setWindowSizeForEvent(CURRENT_EVENT.event);
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
var easeList = [
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

function postCreate() {
	propertyMap.clear();

	curX = windowSpr.x + 20;
	curY = windowSpr.y + 41;

	setupEventEditMenu(CURRENT_EVENT.event);

	trace(CURRENT_EVENT.event);

	var saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20, windowSpr.y + windowSpr.bHeight - 16 - 32, "Save & Close", function() {
		saveEventEdit(CURRENT_EVENT.event);
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
	
	var text = new UIText(curX, curY, 0, label);
	add(text);
	curY += 28;

	var numericStepper = new UINumericStepper(curX, curY, value, 1, 3, null, null, 120);
	add(numericStepper);
	curY += 50;

	addStepperButtons(numericStepper, stepperV1, stepperV2, 32);

	text.x += numericStepper.bWidth/2;
	text.x -= text.width/2;

	propertyMap.set(name, numericStepper);
}

function addCheckbox(name, label, value) {


	var checkbox = new UICheckbox(curX, curY, label, value);
	add(checkbox);
	propertyMap.set(name, checkbox);
}


function createEaseBoxes() {
	useEaseBoxes = true;

	var easeText = new UIText(windowSpr.x+(windowSpr.bWidth/2), curY, 0, "Ease");
	add(easeText);
	easeText.x -= easeText.width/2;

	for (i in 0...(easeWidth/easeBoxWidth)) {
		var spr = new FlxSprite();
		spr.makeSolid(easeBoxWidth, easeBoxWidth, -1);
		add(spr);
		spr.x = windowSpr.x + ((windowSpr.bWidth/2) - 150) + (easeBoxWidth/2) + (i * easeBoxWidth);
		spr.y = curY + 40;
		easeBoxes.push(spr);
	}
	easeFunc = CoolUtil.flxeaseFromString(CURRENT_EVENT.event.ease, "");
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