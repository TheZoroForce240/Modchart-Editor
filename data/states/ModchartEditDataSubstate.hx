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


//edit of UIButtonList
class ModchartEditUIButtonList extends UIWindow {
	public var buttons:MusicBeatGroup = new MusicBeatGroup();

	public var addButtons = [];
	public function setupAddButton(text, callback) {
		var addButton = new UIButton(25, 16, text, null, Std.int(this.buttonSize.x));
		addButton.autoAlpha = false;
		addButton.color = 0xFF00FF00;
		addButton.cameras = [buttonCameras];
		addButton.callback = callback;

		addButton.field.fieldWidth = 0;

		var addIcon = new FlxSprite(addButton.x + addButton.bHeight / 2, addButton.y + (32/2) - 8).loadGraphic(Paths.image('editors/charter/add-button'));
		addIcon.antialiasing = false;
		addButton.members.push(addIcon);
		members.push(addButton);

		addButtons.push({
			button: addButton,
			icon: addIcon
		});
	}

	public var buttonCameras:FlxCamera;
	public var cameraSpacing = 30;

	public var buttonSpacing:Float = 16;
	public var buttonSize:FlxPoint = FlxPoint.get();
	public var buttonOffset:FlxPoint = FlxPoint.get();

	public function new(x:Float, y:Float, width:Int, height:Int, windowName:String, buttonSize:FlxPoint, ?buttonOffset:FlxPoint, ?buttonSpacing:Float) {
		if (buttonSpacing != null) this.buttonSpacing = buttonSpacing;
		this.buttonSize = buttonSize;
		if (buttonOffset != null) this.buttonOffset = buttonOffset;
		super(x, y, width, height, windowName);

		buttonCameras = new FlxCamera(Std.int(x), Std.int(y+cameraSpacing), width, height-cameraSpacing-1);
		FlxG.cameras.add(buttonCameras, false);
		buttonCameras.bgColor = 0;

		members.push(buttons);
		nextscrollY = buttonCameras.scroll.y = -this.buttonSpacing;
	}

	public function add(button:T) {
		button.ID = buttons.members.length-1;
		buttons.add(button);
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

			button.selectable = false;
			button.cameras = [buttonCameras];

			button.setPosition(
				(bWidth/2) - (buttonSize.x/2) + buttonOffset.x,
				CoolUtil.fpsLerp(button.y, yVal + buttonOffset.y, 0.25));

			yVal += (button.bHeight+buttonSpacing);
		}

		for (data in addButtons) {

			data.button.setPosition(
				(bWidth/2) - (buttonSize.x/2) + buttonOffset.x,
				CoolUtil.fpsLerp(data.button.y, yVal + buttonOffset.y, 0.25));

			data.button.field.offset.x = -(data.button.bWidth / 2 - data.button.field.width / 2);
			data.icon.x = (data.button.x + data.button.bWidth / 2 - data.icon.width / 2) - (data.button.field.width/2) - 12;
			data.icon.y = data.button.y + data.button.bHeight / 2 - data.icon.height / 2;

			data.button.selectable = (hovered);

			yVal += (data.button.bHeight+buttonSpacing);
		}


	}
	public var nextscrollY:Float = 0;
	public override function update(elapsed:Float) {
		updateButtonsPos(elapsed);

		super.update(elapsed);

		var maxY = 0;
		if (addButtons.length > 0) {
			maxY = (addButtons[addButtons.length-1].button.y + 32 + (buttonSpacing*1.5));
		} else {
			for (i => button in buttons.members) {
				if (button == null) continue;

				maxY += (button.bHeight+buttonSpacing);
			}
		}

		nextscrollY = FlxMath.bound(buttonCameras.scroll.y - (hovered ? FlxG.mouse.wheel : 0) * 32, -buttonSpacing, Math.max(maxY - buttonCameras.height, -buttonSpacing));

		buttonCameras.scroll.y = nextscrollY;
		

		if (__lastDrawCameras[0] != null) {
			buttonCameras.height = bHeight - cameraSpacing - 1; // -1 for the little gap at the bottom of the window
			buttonCameras.x = __lastDrawCameras[0].x + x - __lastDrawCameras[0].scroll.x;
			buttonCameras.y = __lastDrawCameras[0].y + y + cameraSpacing - __lastDrawCameras[0].scroll.y;
			buttonCameras.zoom = __lastDrawCameras[0].zoom;
		}
	}

	//custom class workaround
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

	public var menuObjects = ["" => null];
	
	public var colorInput:UIColorwheel;

	public var shiftUpButton:UIButton;
	public var shiftDownButton:UIButton;

	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;

	public var labels = [];

	public var xml = null;

	public var expanded = false;

	public var itemData = {
		name: "",
		type: "modifier",
		color: 0xFF545454,		
		file: ""
	}
	public var modList = [];

	public function addLabelOn(ui:UISprite, text:String, ?size:Int):UIText {
		var uiText:UIText = new UIText(ui.x, ui.y - 24, 0, text, size);
		members.push(uiText); labels.push([ui, uiText]);
		return uiText;
	}

	public var script = null;

	public function new(id, modType, node, parent, scrip) {
		super(0, 0, '', function () {}, 928, 280);
		script = scrip;

		if (node != null) {
			itemData.name = node.get("name");
			itemData.type = modType;

			script.call("setupItemData", [itemData, node]);

			itemData.color = FlxColor.fromString(node.get("color"));
		} else {
			itemData.type = modType;
			script.call("setupDefaultItemData", [itemData]);
		}
		
		field.text = "";
		resize(928, 280);

		autoAlpha = false; 
		frames = Paths.getFrames('editors/ui/inputbox');

		modList = script.call("getAvailableFiles", []);

		var displayName = script.call("getEditDisplayName", []);
		var folderDisplayName = script.call("getFolderDisplayName", []);

		topText = new UIText(16, 12, 0, itemData.name + " (" + displayName + ")");
		members.push(topText);

		expandButton = new UIButton(16, 12, "^", function () {
			expanded = !expanded;
			updateExpand();
		}, 32, 24);
		members.push(expandButton);

		nameInput = new UITextBox(16, 34, itemData.name, 200);
		addLabelOn(nameInput, displayName + " Name");
		members.push(nameInput);

		fileInput = new UIAutoCompleteTextBox(16 + 216, 34, itemData.file, 200, 32, modList);
		fileInput.suggestItems = modList;
		addLabelOn(fileInput, displayName + " File " + folderDisplayName);
		members.push(fileInput);

		fileInput.onChange = function(newfile) {
			if (itemData.file != newfile) {
				itemData.file = newfile;
				updateMod();
			}
		}

		descText = new UIText(16 + 216, 100, 300, "test");
		members.push(descText);

		menuObjects.clear();
		script.call("setupEditMenu", [itemData, this]);

		colorInput = new UIColorwheel(560, 34, itemData.color);
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

		if (expanded) {
			follow(this, nameInput, 16, 34);
			follow(this, fileInput, 232, 34);
			follow(this, descText, 232, 100-24);

			var lastHeight = script.call("getMenuHeight", []);
			script.call("updateMenuPositions", [this]);

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
			for (i => label in extraLabels) {
				follow(extraValues[i], label, 0, -24);
				label.visible = expanded;
			}
		}
	}

	public var extraValuesList = []; //make sure order is correct
	public var extraValues = [];
	public var extraLabels = [];

	public function updateMod() {
		script.call("updateEditItem", [itemData, this]);
		updateExpand();
	}


	public function getHeight() {
		var h = script.call("getBaseWindowHeight", []);
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
		for (name => obj in menuObjects) {
			expandedItems.push(obj);
		}
		for (obj in extraValues) {
			expandedItems.push(obj);
		}
		for (obj in extraLabels) {
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

		for (shit in labels) {
			shit[1].visible = expanded;
		}
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

var itemList = null;

function create() {
	winTitle = "Edit Modchart Data";
	winWidth = 960;
}

function postCreate() {

	itemList = new ModchartEditUIButtonList(windowSpr.x + 16, windowSpr.y + 64, 928, 420, "", FlxPoint.get(928, 280), FlxPoint.get(0, 0), 0);
	itemList.frames = Paths.getFrames('editors/ui/inputbox');
	itemList.cameraSpacing = 0;

	for (name => script in ITEM_EDIT_LOADED_SCRIPTS) {
		if (script.call("isEditable", []) == true) {
			var itemScript = script;
			var itemName = name;
			itemList.setupAddButton(script.call("getEditButtonText", []), function() {
				itemList.add(new ModchartEditButton(itemList.buttons.length, itemName, null, itemList, itemScript));
			});
		}
	}

	for (list in CURRENT_XML.elementsNamed("Init")) {
		for (name => script in ITEM_EDIT_LOADED_SCRIPTS) {
			if (script.call("isEditable", []) == true) {
				for (node in list.elementsNamed(script.call("getXMLNodeName", []))) {
					itemList.add(new ModchartEditButton(itemList.buttons.length, name, node, itemList, script));
				}
			}
		}
	}

	add(itemList);

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
	itemList.actuallydestroy();
}