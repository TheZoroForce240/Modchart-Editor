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
		//animation.add("note", [for(i in 0...frames.frames.length) i], 0, true);
		//animation.play("note");
		setGraphicSize(20,20);
		updateHitbox();
		//this.setUnstretchedGraphicSize(40, 40, false);

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
		var begin = SortedArrayUtil.binarySearch(members, conductorPos-1, getVarForEachAdd);
		var end = SortedArrayUtil.binarySearch(members, conductorPos+((1280-250)/size), getVarForEachRemove);

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

		var begin = SortedArrayUtil.binarySearch(members, conductorPos-1, getVarForEachAdd);
		var end = SortedArrayUtil.binarySearch(members, conductorPos+((1280-250)/size), getVarForEachRemove);

		

		for(i in begin...end) {
			__loopSprite = members[i];
			__loopSprite.cameras = this.cameras;
			__loopSprite.draw();
		}


		//FlxCamera._defaultCameras = oldDefaultCameras;
	}
}
class EventGroupContainer extends FlxSprite {
	public var eventGroup:EventGroup = null;

	//currently cant override group update/draw so using this as a workaround
	override public function update(elapsed) {
		eventGroup._update(elapsed);
	}
	override public function draw() {
		eventGroup._draw();
	}
}