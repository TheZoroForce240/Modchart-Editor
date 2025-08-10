//
import modchart.backend.standalone.adapters.codename.Codename;

class EditorAdapter extends modchart.backend.standalone.adapters.codename.Codename {
    public var downscroll = false;
    public var strumLines = [];
    public var camHUD = null;
    public var scrollSpeed = 2.0;

	public function new() {super();}

	override public function onModchartingInitialization() {
		__fCrochet = Conductor.crochet;
		trace("called from onModchartingInitialization");
	}

	public function isTapNote(sprite:FlxSprite) {
		return false;
	}

	// Song related
	public function getSongPosition():Float {
		return Conductor.songPosition;
	}

	public function getCurrentBeat():Float {
		return Conductor.curBeatFloat;
	}

	public function getCurrentCrochet():Float {
		return Conductor.crochet;
	}	

	public function getStaticCrochet():Float {
		return __fCrochet;
	}

	public function getBeatFromStep(step:Float):Float {
		return step * Conductor.stepsPerBeat;
	}

	public function arrowHit(arrow:FlxSprite) {
		return false;
	}

	public function isHoldEnd(arrow:FlxSprite) {
		return false;
	}

	public function getLaneFromArrow(arrow:FlxSprite) {
		return arrow.ID;
	}

	public function getPlayerFromArrow(arrow:FlxSprite) {
        for (i => group in strumLines) {
            if (group.contains(arrow)) return i;
        }
		return 0;
	}

	public function getHoldLength(item:FlxSprite):Float {
		return 0;
	}

	public function getHoldParentTime(arrow:FlxSprite) {
		return 0;
	}

	// im so fucking sorry for those conditionals
	public function getKeyCount(?player:Int = 0):Int {
		return strumLines != null && strumLines[player] != null ? strumLines[player].length : 4;
	}

	public function getPlayerCount():Int {
		return strumLines != null ? strumLines.length : 2;
	}

	public function getTimeFromArrow(arrow:FlxSprite) {
		return 0;
	}

	public function getHoldSubdivisions():Int {
		final val = Options.modchartingHoldSubdivisions;
		return val < 1 ? 1 : val;
	}

	public function getDownscroll():Bool {
		return downscroll;
	}

	public function getDefaultReceptorX(lane:Int, player:Int):Float {
		return strumLines[player][lane].x;
	}

	public function getDefaultReceptorY(lane:Int, player:Int):Float {
		return strumLines[player][lane].y;
	}

	public function getArrowCamera():Array<FlxCamera>
		return [camHUD];

	public function getCurrentScrollSpeed():Float {
		return scrollSpeed;
	}

	// 0 receptors
	// 1 tap arrows
	// 2 hold arrows
	// 3 lane attachments
	public function getArrowItems() {
		var pspr:Array<Array<Array<FlxSprite>>> = [];

		for (i in 0...strumLines.length) {
			var sl = strumLines[i];
			pspr[i] = [];
			pspr[i][0] = sl.copy();
			pspr[i][1] = [];
			pspr[i][2] = [];
		}
        
		return pspr;
	}
}