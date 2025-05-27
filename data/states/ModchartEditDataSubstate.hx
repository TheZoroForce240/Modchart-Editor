//
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

import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.util.FlxSort;
import flixel.math.FlxMath;

import funkin.backend.MusicBeatGroup;


class ModchartEditUIButtonList extends UIWindow {
	public var buttons:MusicBeatGroup = new MusicBeatGroup();
	public var addButton:UIButton;
	public var addIcon:FlxSprite;

	public var addButton2:UIButton;
	public var addIcon2:FlxSprite;

	public var buttonCameras:FlxCamera;
	public var cameraSpacing = 30;

	public var buttonSpacing:Float = 16;
	public var buttonSize:FlxPoint = FlxPoint.get();
	public var buttonOffset:FlxPoint = FlxPoint.get();

	public var dragging:Bool = false;
	public var dragCallback = null;

	public var curMoving = null;
	public var curMovingInterval:Float = 0;

	public function new(x:Float, y:Float, width:Int, height:Int, windowName:String, buttonSize:FlxPoint, ?buttonOffset:FlxPoint, ?buttonSpacing:Float) {
		if (buttonSpacing != null) this.buttonSpacing = buttonSpacing;
		this.buttonSize = buttonSize;
		if (buttonOffset != null) this.buttonOffset = buttonOffset;
		super(x, y, width, height, windowName);

		buttonCameras = new FlxCamera(Std.int(x), Std.int(y+cameraSpacing), width, height-cameraSpacing-1);
		FlxG.cameras.add(buttonCameras, false);
		buttonCameras.bgColor = 0;

		addButton = new UIButton(25, 16, "Add Note Modifier", null, Std.int(this.buttonSize.x/2));
		addButton.autoAlpha = false;
		addButton.color = 0xFF00FF00;
		addButton.cameras = [buttonCameras];

		addButton.field.fieldWidth = 0;

		addIcon = new FlxSprite(addButton.x + addButton.bHeight / 2, addButton.y + (32/2) - 8).loadGraphic(Paths.image('editors/charter/add-button'));
		addIcon.antialiasing = false;
		addButton.members.push(addIcon);
		members.push(addButton);

		addButton2 = new UIButton(25, 16, "Add Post Process Shader", null, Std.int(this.buttonSize.x/2));
		addButton2.autoAlpha = false;
		addButton2.color = 0xFF00FF00;
		addButton2.cameras = [buttonCameras];

		addButton2.field.fieldWidth = 0;

		addIcon2 = new FlxSprite(addButton2.x + addButton2.bHeight / 2, addButton2.y + (32/2) - 8).loadGraphic(Paths.image('editors/charter/add-button'));
		addIcon2.antialiasing = false;
		addButton2.members.push(addIcon2);
		members.push(addButton2);

		members.push(buttons);
		nextscrollY = buttonCameras.scroll.y = -this.buttonSpacing;
	}

	public function add(button:T) {
		button.ID = buttons.members.length-1;
		buttons.add(button);
		curMovingInterval = 0;
		nextscrollY += button.bHeight;
	}

	public function insert(button:T, position:Int) {
		button.ID = position;
		buttons.insert(position, button);
		nextscrollY += button.bHeight;
	}

	public function remove(button:T) {
		nextscrollY -= button.bHeight;
		buttons.members.remove(button);
		button.destroy();
	}

	public function updateButtonsPos(elapsed:Float) {
		var yVal = 0;
		for (i => button in buttons.members) {
			if (button == null) continue;

			if (curMoving != button) {
				button.setPosition(
					(bWidth/2) - (buttonSize.x/2) + buttonOffset.x,
					CoolUtil.fpsLerp(button.y, yVal + buttonOffset.y, 0.25));
			}
			if (button.hovered && FlxG.mouse.justPressed) curMoving = button;

			yVal += (button.bHeight+buttonSpacing);
		}

		if (addButton != null)
			addButton.setPosition(
				(bWidth/2) - (buttonSize.x/2) + buttonOffset.x,
				CoolUtil.fpsLerp(addButton.y, yVal + buttonOffset.y, 0.25));

		if (addButton2 != null) {
			addButton2.setPosition(
				(bWidth/2),
				CoolUtil.fpsLerp(addButton2.y, yVal + buttonOffset.y, 0.25));
		}

		if (curMoving != null) {
			curMovingInterval += FlxG.mouse.deltaY;
			if (Math.abs(curMovingInterval) > addButton.bHeight / 2) {
				curMovingInterval = 999;
				curMoving.y = CoolUtil.fpsLerp(curMoving.y, FlxG.mouse.getWorldPosition(buttonCameras).y - (curMoving.bHeight / 2), 0.3);
				buttons.sort(function(o, a:T, b:T) return FlxSort.byValues(o, a.y + (a.bHeight / 2), b.y + (a.bHeight / 2)), -1);
			}
			if (FlxG.mouse.justReleased) {
				curMoving = null;
				curMovingInterval = 0;
			}
		}
		addButton.field.offset.x = -(addButton.bWidth / 2 - addButton.field.width / 2);
		addIcon.x = (addButton.x + addButton.bWidth / 2 - addIcon.width / 2) - (addButton.field.width/2) - 12;
		addIcon.y = addButton.y + addButton.bHeight / 2 - addIcon.height / 2;

		addButton2.field.offset.x = -(addButton2.bWidth / 2 - addButton2.field.width / 2);
		addIcon2.x = (addButton2.x + addButton2.bWidth / 2 - addIcon2.width / 2) - (addButton2.field.width/2) - 12;
		addIcon2.y = addButton2.y + addButton2.bHeight / 2 - addIcon2.height / 2;
	}
	public var nextscrollY:Float = 0;
	public override function update(elapsed:Float) {
		updateButtonsPos(elapsed);
		dragging = Math.abs(curMovingInterval) > addButton.bHeight / 2;

		super.update(elapsed);

		nextscrollY = FlxMath.bound(buttonCameras.scroll.y - (hovered ? FlxG.mouse.wheel : 0) * 32, -buttonSpacing, Math.max((addButton.y + 32 + (buttonSpacing*1.5)) - buttonCameras.height, -buttonSpacing));

		if (curMoving != null && dragging) {
			nextscrollY -= Math.min((bHeight - 100) - FlxG.mouse.getWorldPosition(buttonCameras).y, 0) / 8;
			nextscrollY += Math.min(FlxG.mouse.getWorldPosition(buttonCameras).y - 100, 0) / 8;
		}

		buttonCameras.scroll.y = nextscrollY;

		for (i => button in buttons.members) {
			if (button == null) continue;
			button.selectable = button.shouldPress = (hovered && !dragging);
			button.cameras = [buttonCameras];
			if (button.ID != i) {
				if (dragCallback != null) dragCallback(button, button.ID, i);
				button.ID = i; // Ok back to normal :D
			}
		}
		addButton.selectable = (hovered && !dragging);
		addButton2.selectable = (hovered && !dragging);

		if (__lastDrawCameras[0] != null) {
			buttonCameras.height = bHeight - cameraSpacing - 1; // -1 for the little gap at the bottom of the window
			buttonCameras.x = __lastDrawCameras[0].x + x - __lastDrawCameras[0].scroll.x;
			buttonCameras.y = __lastDrawCameras[0].y + y + cameraSpacing - __lastDrawCameras[0].scroll.y;
			buttonCameras.zoom = __lastDrawCameras[0].zoom;
		}
	}

	public function actuallydestroy() {

		if(buttonCameras != null) {
			if (FlxG.cameras.list.contains(buttonCameras))
				FlxG.cameras.remove(buttonCameras);
			buttonCameras = null;
		}
	}
}

class ModchartEditButton extends UIButton {
	public var topText:UIText;
	public var expandButton:UIButton;

	public var nameInput:UITextBox;
	public var fileInput:UIAutoCompleteTextBox;
	public var descText:UIText;

	public var valueInput:UINumericStepper;
	public var strumLineIDInput:UINumericStepper;
	public var strumIDInput:UINumericStepper;

	public var camGameCheckbox:UICheckbox;
	public var camHUDCheckbox:UICheckbox;
	public var camOtherCheckbox:UICheckbox;
	
	public var colorInput:UIColorwheel;

	public var shiftUpButton:UIButton;
	public var shiftDownButton:UIButton;

	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;

	public var labels = [];

	public var xml = null;

	public var expanded = false;

	public var modifierData = {
		name: "",
		type: "modifier",
		color: 0xFF545454,

		modifier: "x",
		value: 0,
		strumID: -1,
		strumLineID: -1,
		subMods: [],

		shader: "MirrorRepeatEffect",
		camGame: true,
		camHUD: false,
		camOther: false,
		properties: [],
	}
	public var modList = [];

	public function new(id, modType, node, parent) {
		super(0, 0, '', function () {}, 928, 280);

		if (node != null) {
			modifierData.name = node.get("name");
			modifierData.type = modType;

			if (modifierData.type == "modifier") {
				modifierData.modifier = node.get("modifier");
				modifierData.value = Std.parseFloat(node.get("value"));
				modifierData.strumLineID = Std.parseInt(node.get("strumLineID"));
				modifierData.strumID = Std.parseInt(node.get("strumID"));
				for (submod in node.elementsNamed("SubMod")) {
					modifierData.subMods.push({
						name: submod.get("name"),
						value: Std.parseFloat(submod.get("value"))
					});
				}
			} else if (modifierData.type == "shader") {
				modifierData.shader = node.get("shader");

				modifierData.camGame = node.get("camGame") == "true";
				modifierData.camHUD = node.get("camHUD") == "true";
				modifierData.camOther = node.get("camOther") == "true";

				for (prop in node.elementsNamed("Property")) {
					modifierData.properties.push({
						name: prop.get("name"),
						value: Std.parseFloat(prop.get("value"))
					});
				}
			}

			modifierData.color = FlxColor.fromString(node.get("color"));
		}
		
		field.text = "";
		resize(928, 280);

		autoAlpha = false; 
		frames = Paths.getFrames('editors/ui/inputbox');

		function addLabelOn(ui:UISprite, text:String, ?size:Int):UIText {
			var uiText:UIText = new UIText(ui.x, ui.y - 24, 0, text, size);
			members.push(uiText); labels.push([ui, uiText]);
			return uiText;
		}

		if (modifierData.type == "modifier") {
			for (path in Paths.getFolderContent('modifiers/', true, null)) {
				if (Path.extension(path) == "vert" || Path.extension(path) == "frag") {
					var file = CoolUtil.getFilename(path);
					if (!modList.contains(file)) {
						modList.push(file);
					}
				}
			}
		} else if (modifierData.type == "shader"){
			for (path in Paths.getFolderContent('shaders/modcharts/', true, null)) {
				if (Path.extension(path) == "ini") {
					var file = CoolUtil.getFilename(path);
					if (!modList.contains(file)) {
						modList.push(file);
					}
				}
			}
		}

		var displayName = "Modifier";
		if (modifierData.type == "shader") displayName = "Shader";

		topText = new UIText(16, 12, 0, modifierData.name + " (" + displayName + ")");
		members.push(topText);

		expandButton = new UIButton(16, 12, "^", function () {
			expanded = !expanded;
			updateExpand();
		}, 32, 24);
		members.push(expandButton);

		nameInput = new UITextBox(16, 34, modifierData.name, 200);
		addLabelOn(nameInput, displayName + " Name");
		members.push(nameInput);

		var file = modifierData.modifier;
		if (modifierData.type == "shader") file = modifierData.shader;

		fileInput = new UIAutoCompleteTextBox(16 + 216, 34, file, 200, 32, modList);
		fileInput.suggestItems = modList;
		addLabelOn(fileInput, displayName + " File" + (modifierData.type == "modifier" ? " (modifiers/)" : " (shaders/modcharts/)") );
		members.push(fileInput);

		fileInput.onChange = function(newfile) {
			if (modifierData.type == "modifier") {
				if (modifierData.modifier != newfile) {
					modifierData.modifier = newfile;
					updateMod();
				}
			} else if (modifierData.type == "shader") {
				if (modifierData.shader != newfile) {
					modifierData.shader = newfile;
					updateMod();
				}
			}
		}

		descText = new UIText(16 + 216, 100, 300, "test");
		members.push(descText);

		if (modifierData.type == "modifier") {
			valueInput = new UINumericStepper(16, 100, modifierData.value, 0, 6, null, null, 200);
			addLabelOn(valueInput, "Default Value");
			members.push(valueInput);

			strumLineIDInput = new UINumericStepper(16, 166, modifierData.strumLineID, 0, 0, -1, null, 200);
			addLabelOn(strumLineIDInput, "StrumLine ID");
			members.push(strumLineIDInput);

			strumIDInput = new UINumericStepper(16, 166 + 66, modifierData.strumID, 0, 0, -1, null, 200);
			addLabelOn(strumIDInput, "Strum ID");
			members.push(strumIDInput);
		} else if (modifierData.type == "shader") {
			camGameCheckbox = new UICheckbox(16, 100, "Use on Game Camera?", modifierData.camGame);
			members.push(camGameCheckbox);

			camHUDCheckbox = new UICheckbox(16, 166, "Use on HUD Camera?", modifierData.camHUD);
			members.push(camHUDCheckbox);

			camOtherCheckbox = new UICheckbox(16, 166 + 66, "Use on Other Camera?", modifierData.camOther);
			members.push(camOtherCheckbox);
		}

		colorInput = new UIColorwheel(560, 34, modifierData.color);
		addLabelOn(colorInput, "Editor Color");
		members.push(colorInput);

		var p = parent;
		deleteButton = new UIButton(16, 280-32-11, "", function () {
			p.remove(this);
		}, 64);
		deleteButton.color = 0xFFFF0000;
		deleteButton.autoAlpha = false;
		members.push(deleteButton);

		deleteIcon = new FlxSprite(deleteButton.x + ((deleteButton.bWidth/2)-(15/2)), deleteButton.y + ((deleteButton.bHeight/2)-(16/2))).loadGraphic(Paths.image('editors/delete-button'));
		deleteIcon.antialiasing = false;
		members.push(deleteIcon);

		updateMod();
	}

	public function follow(parent, obj, X, Y) {
		obj.x = parent.x + X;
		obj.y = parent.y + Y;
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		follow(this, topText, 16, 10);
		follow(this, expandButton, 880, 8);

		follow(this, nameInput, 16, 34);
		follow(this, fileInput, 232, 34);
		follow(this, descText, 232, 100-24);

		var lastHeight = 100;
		if (modifierData.type == "modifier") {
			follow(this, valueInput, 16, 100);
			follow(this, strumLineIDInput, 16, 166);
			follow(this, strumIDInput, 16, 166 + 66);
			lastHeight = 166 + 66 + 66;
		} else if (modifierData.type == "shader") {
			follow(this, camGameCheckbox, 16, 80);
			follow(this, camHUDCheckbox, 16, 80 + 40);
			follow(this, camOtherCheckbox, 16, 80 + 80);
			lastHeight = 160 + 66;
		}

		for (obj in extraValues) {
			follow(this, obj, 16, lastHeight);
			lastHeight += 66;
		}

		follow(this, colorInput, 560, 34);
		fixColorWheelPos(colorInput);

		follow(this, deleteButton, 16, bHeight-32-11);
		follow(this, deleteIcon, 16 + ((deleteButton.bWidth/2)-(15/2)), (bHeight-32-11) + ((deleteButton.bHeight/2)-(16/2)));

		for (shit in labels) {
			follow(shit[0], shit[1], 0, -24);
			shit[1].visible = expanded;
		}
	}

	public var extraValuesList = []; //make sure order is correct
	public var extraValues = [];

	public function updateMod() {
		var fileExists = false;
		var iniExists = false;
		var iniData = ["" => ""];
		if (modifierData.type == "modifier") {
			if (Assets.exists("modifiers/" + modifierData.modifier + ".vert") || Assets.exists("modifiers/" + modifierData.modifier + ".frag")) {
				fileExists = true;
			}
			if (Assets.exists("modifiers/" + modifierData.modifier + ".ini")) {
				iniExists = true;
				iniData = IniUtil.parseAsset("modifiers/" + modifierData.modifier+ ".ini");
			}
		} else if (modifierData.type == "shader") {
			if (Assets.exists("shaders/modcharts/" + modifierData.shader + ".vert") || Assets.exists("shaders/modcharts/" + modifierData.shader + ".frag")) {
				fileExists = true;
			}
			if (Assets.exists("shaders/modcharts/" + modifierData.shader + ".ini")) {
				iniExists = true;
				iniData = IniUtil.parseAsset("shaders/modcharts/" + modifierData.shader + ".ini");
			}
		}

		if (iniExists) {
			descText.text = iniData.exists("desc") ? StringTools.replace(iniData.get("desc"), "#", "\n") : "";
		} else {
			var file = modifierData.modifier;
			if (modifierData.type == "shader") file = modifierData.shader;
			descText.text = fileExists ? "" : "\"" + file + "\" could not found!";
		}

		for (obj in extraValues) {
			members.remove(obj);
			obj.destroy();
		}
		extraValues = [];
		extraValuesList = [];

		//create submod/prop boxes
		for (key => val in iniData) {
			if (key != "desc" && key != "") {
				//trace(key);
				var input = new UINumericStepper(16, 100, Std.parseFloat(val), 0, 6, null, null, 200);
				members.push(input);
				extraValues.push(input);
				extraValuesList.push(key);
			}
		}
		
		if (modifierData.type == "modifier") {
			for (submod in modifierData.subMods) {
				if (extraValuesList.contains(submod.name)) {
					var inputBox = extraValues[extraValuesList.indexOf(submod.name)];
					inputBox.value = submod.value;
				}
			}
			modifierData.subMods = []; //temp remove to clear out any submods that shouldnt be there
			for (i => names in extraValuesList) {
				modifierData.subMods.push({
					name: names,
					value: extraValues[i].value
				});
			}
		} else if (modifierData.type == "shader") {
			for (prop in modifierData.properties) {
				if (extraValuesList.contains(prop.name)) {
					var inputBox = extraValues[extraValuesList.indexOf(prop.name)];
					inputBox.value = prop.value;
				}
			}
			modifierData.properties = []; //temp remove to clear out any properties that shouldnt be there
			for (i => names in extraValuesList) {
				modifierData.properties.push({
					name: names,
					value: extraValues[i].value
				});
			}
		}

		updateExpand();
	}


	public function getHeight() {
		var h = 250;
		if (modifierData.type == "modifier") {
			h = 320;
		}
		h += extraValuesList.length * 66;
		return h;
	}

	public function updateExpand() {
		if (expanded) {
			resize(bWidth, getHeight());
		} else {
			resize(bWidth, 40);
		}

		var expandedItems = [nameInput, fileInput, descText, colorInput, deleteButton, deleteIcon];
		if (modifierData.type == "modifier") {
			expandedItems.push(valueInput);
			expandedItems.push(strumLineIDInput);
			expandedItems.push(strumIDInput);
		} else if (modifierData.type == "shader") {
			expandedItems.push(camGameCheckbox);
			expandedItems.push(camHUDCheckbox);
			expandedItems.push(camOtherCheckbox);
		}
		for (obj in extraValues) {
			expandedItems.push(obj);
		}

		for (item in expandedItems) {
			if (item is UISprite) {
				item.selectable = expanded;
			}
			if (item is UIColorwheel) {
				for (thing in item.rgbNumSteppers) thing.selectable = expanded;
				item.colorHexTextBox.selectable = expanded;
			}
			item.visible = expanded;
		}

		expandButton.field.text = expanded ? "^" : "<";
		topText.visible = !expanded;
	}

	public function fixColorWheelPos(wheel) {
		wheel.colorPicker.setPosition(wheel.x + 12.5, (wheel.y + 125/2) - (100/2));
		wheel.colorSlider.setPosition(wheel.colorPicker.x + 100 + 12.5, wheel.colorPicker.y);
		wheel.colorHexTextBox.setPosition(wheel.colorSlider.x + 16 + 12.5, wheel.colorSlider.y + 16);

		for (i in 0...3) { //numStepper
			wheel.members[i].setPosition(wheel.colorSlider.x + 18 + 12.5 + (i * 44), wheel.colorHexTextBox.y + 28 + 6 + 13 + 6 + 0.5);
		}
		wheel.updateColorPickerSelector();
		wheel.updateColorSliderPickerSelector();

		wheel.members[wheel.members.length-2].setPosition(wheel.colorHexTextBox.x - 2, wheel.colorHexTextBox.y - 18); //hexlabel
		wheel.members[wheel.members.length-1].setPosition(wheel.rgbNumSteppers[0].x - 2, wheel.rgbNumSteppers[0].y - 18); //rgblabel
	}
}

var modifierList = null;

function create() {

	winTitle = "Edit Modchart Data";
	winWidth = 960;

}

function postCreate() {

	modifierList = new ModchartEditUIButtonList(windowSpr.x + 16, windowSpr.y + 64, 928, 420, "", FlxPoint.get(928, 280), FlxPoint.get(0, 0), 0);
	modifierList.frames = Paths.getFrames('editors/ui/inputbox');
	modifierList.cameraSpacing = 0;

	modifierList.addButton.callback = function() {
		modifierList.add(new ModchartEditButton(modifierList.buttons.length, "modifier", null, modifierList));
	}

	for (list in CURRENT_XML.elementsNamed("Init")) {
		for (node in list.elementsNamed("Shader")) {
			modifierList.add(new ModchartEditButton(modifierList.buttons.length, "shader", node, modifierList));
		}

		for (node in list.elementsNamed("Modifier")) {
			modifierList.add(new ModchartEditButton(modifierList.buttons.length, "modifier", node, modifierList));
		}
	}

	add(modifierList);

	//modifierList.dragCallback = (object, oldIndex:Int, newIndex:Int) -> {};


	var saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20, windowSpr.y + windowSpr.bHeight - 16 - 32, "Save & Close", function() {
		close();
	});
	saveButton.x -= saveButton.bWidth;
	add(saveButton);

	var closeButton = new UIButton(saveButton.x - 10, saveButton.y, "Close", function() {
		close();
	});
	closeButton.color = 0xFFFF0000;
	closeButton.x -= closeButton.bWidth;
	add(closeButton);
}

function destroy() {
	modifierList.actuallydestroy();
}