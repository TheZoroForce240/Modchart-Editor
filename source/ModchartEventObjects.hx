var shaderEaseList = [
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

	"smoothStepIn",
	"smoothStepOut",
	"smoothStepInOut",

	"smootherStepIn",
	"smootherStepOut",
	"smootherStepInOut",

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
];

class EventRenderer extends funkin.editors.ui.UISprite {
	public var conductorPos:Float = 0;
	public var sizeX:Float = 20;
	public var sizeY:Float = 20;
	public var _timelineScrollY:Float = 0;

	public var events = [];

	public function getVarForEachAdd(e:Dynamic) {
		return e.step + (e.time != null ? e.time : 0);
	}
		
	public function getVarForEachRemove(e:Dynamic) {
		return e.step - (e.time != null ? e.time : 0);
	}

	public function getVar(n:Dynamic)
		return e.step;

	public function getVisibleStartIndex() {
		return SortedArrayUtil.binarySearch(events, conductorPos-1, getVarForEachAdd);
	}
	public function getVisibleEndIndex() {
		return SortedArrayUtil.binarySearch(events, conductorPos+((1280-250)/sizeX), getVarForEachRemove);
	}

	public var easeSpritesUp = [];
	public var easeSpritesDown = [];

	public var arrows = [];
	public var arrowsSelected = [];

	public function new() {
		super();

		for (a in 0...4) {
			var arr = new UISprite(0, 0);
			arr.loadGraphic(Paths.image('editors/charter/note'), true, 157, 154);
			arr.animation.add("note", [for(i in 0...arr.frames.frames.length) i], 0, true);
			arr.animation.play("note");
			arr.setGraphicSize(20,20);
			arr.updateHitbox();
			arr.animation.curAnim.curFrame = a;
			arrows.push(arr);

			var arrS = new UISprite(0, 0);
			arrS.loadGraphic(Paths.image('editors/charter/note'), true, 157, 154);
			arrS.animation.add("note", [for(i in 0...arrS.frames.frames.length) i], 0, true);
			arrS.animation.play("note");
			arrS.setGraphicSize(20,20);
			arrS.updateHitbox();
			arrS.animation.curAnim.curFrame = a;
			arrowsSelected.push(arrS);

			if (a == 1) {
				arr.flipY = true;
				arrS.flipY = true;
			}

			arrS.colorTransform.redMultiplier = arrS.colorTransform.greenMultiplier = arrS.colorTransform.blueMultiplier = 0.75;
			arrS.colorTransform.redOffset = arrS.colorTransform.greenOffset = 96;
			arrS.colorTransform.blueOffset = 168;
		}

		for (i => ease in shaderEaseList) {
			var up = new UISprite(0, 0);
			up.makeSolid(1, 1, -1);
			up.shader = new CustomShader("ease");
			up.shader.easeType = i;
			up.shader.flip = 1;
			easeSpritesUp.push(up);

			var down = new UISprite(20, 10);
			down.makeSolid(1, 1, -1);
			down.shader = new CustomShader("ease");
			down.shader.easeType = i;
			down.shader.flip = 0;
			easeSpritesDown.push(down);
		}
	}

	override public function draw() {

		var begin = getVisibleStartIndex();
		var end = getVisibleEndIndex();

		var minTimelineIndex = Math.floor(_timelineScrollY / sizeY) - 1;
		var maxTimelineIndex = minTimelineIndex + Math.ceil(320 / sizeY) + 1;

		for(i in begin...end) {
			var e = events[i];

			if (e.timelineIndex >= minTimelineIndex && e.timelineIndex < maxTimelineIndex) {
				var arrowIndex = 0;

				x = e.step * sizeX;
				y = e.timelineIndex * sizeY;

				if (e.time != null && e.time > 0) {
					var sus = (e.value > e.lastValue ? easeSpritesUp[e.easeIndex] : easeSpritesDown[e.easeIndex]);
					arrowIndex = e.value > e.lastValue ? 2 : 1;
					sus.x = this.x;
					sus.y = this.y;
					sus.scale.set((e.time*sizeX), sizeY);
					sus.updateHitbox();
					sus.cameras = this.cameras;
					sus.draw();
				}

				var arrow = e.selected ? arrowsSelected[arrowIndex] : arrows[arrowIndex];
				arrow.x = this.x;
				arrow.y = this.y;
				arrow.cameras = this.cameras;
				arrow.draw();
			}
		}
	}
}
/*
class EventObject extends funkin.editors.ui.UISprite {
	public var sustainSpr:UISprite;

	public var selected:Bool = false;

	public var event:Dynamic;

	public var timelineIndex:Int = -1;

	public function new(e:Dynamic) {
		super();

		event = e;
		antialiasing = true; ID = -1;
		loadGraphic(Paths.image('editors/charter/note'), true, 157, 154);
		animation.add("note", [for(i in 0...frames.frames.length) i], 0, true);
		animation.play("note");
		setGraphicSize(20,20);
		updateHitbox();

		sustainSpr = new UISprite(20, 10);
		sustainSpr.makeSolid(1, 1, -1);
		sustainSpr.scale.set(0, 10);
		sustainSpr.shader = new CustomShader("ease");
		sustainSpr.shader.easeType = 0;
		sustainSpr.shader.flip = 0;
		members.push(sustainSpr);

		cursor = MouseCursor.BUTTON;
		moves = false;
		updateEvent();
	}

	public function updateLength(size:Float) {
		sustainSpr.scale.set(0,0);
		if (event.type == "tweenShaderProperty" || event.type == "tweenModifierValue") {
			sustainSpr.scale.set((event.time*size), 20);
			sustainSpr.updateHitbox();
			sustainSpr.cameras = this.cameras;
			sustainSpr.x = x;
			sustainSpr.y = y;
		}
	}

	public function updateEvent() {
		if (event.type == "tweenShaderProperty" || event.type == "tweenModifierValue") {
			sustainSpr.shader.easeType = shaderEaseList.indexOf(event.ease);
			if (event.value > event.lastValue) {
				animation.curAnim.curFrame = 2;
				angle = 0;
				sustainSpr.shader.flip = 1;
			} else {
				animation.curAnim.curFrame = 1;
				angle = -180;
				sustainSpr.shader.flip = 0;
			}
		} else {
			angle = -90;
		}

		colorTransform.redMultiplier = colorTransform.greenMultiplier = colorTransform.blueMultiplier = selected ? 0.75 : 1;
		colorTransform.redOffset = colorTransform.greenOffset = selected ? 96 : 0;
		colorTransform.blueOffset = selected ? 168 : 0;
	}
}

class EventGroup extends funkin.backend.MusicBeatGroup {

	public var size:Float = 20.0;

	public function getVarForEachAdd(n:Dynamic) {
		return n.event.step + (n.event.time != null ? n.event.time : 0);
	}
		
	public function getVarForEachRemove(n:Dynamic) {
		return n.event.step - (n.event.time != null ? n.event.time : 0);
	}

	public function getVar(n:Dynamic)
		return n.event.step;

	public function getVisibleStartIndex() {
		return SortedArrayUtil.binarySearch(members, conductorPos-1, getVarForEachAdd);
	}
	public function getVisibleEndIndex() {
		return SortedArrayUtil.binarySearch(members, conductorPos+((1280-250)/size), getVarForEachRemove);
	}

	public function addSorted(e:Dynamic) {
		SortedArrayUtil.addSorted(members, e, getVar);
		return e;
	}

	public var conductorPos:Float = 0;
	public function _update(elapsed:Float):Void
	{
		var begin = getVisibleStartIndex();
		var end = getVisibleEndIndex();

		for(i in begin...end) {
			__loopSprite = members[i];
			__loopSprite.update(elapsed);
		}
	}
	public function _draw():Void
	{
		/*final oldDefaultCameras = FlxCamera._defaultCameras;
		if (_cameras != null)
		{
			FlxCamera._defaultCameras = _cameras;
		}*/

		/*
		var begin = getVisibleStartIndex();
		var end = getVisibleEndIndex();

		

		for(i in begin...end) {
			__loopSprite = members[i];
			__loopSprite.cameras = this.cameras;
			__loopSprite.draw();
		}


		//FlxCamera._defaultCameras = oldDefaultCameras;
	}
}
*/