import funkin.editors.ui.UISprite;
import funkin.editors.ui.UISliceSprite;
import flixel.math.FlxMath;
import openfl.ui.MouseCursor;

class UIScrollBarHorizontal extends UISprite {
	public var length:Float;
	public var start:Float;
	public var size:Float;

	public var thumb:UISliceSprite;
	public var thumbIcon:FlxSprite;

	public var value:Float;

	public var onChange:Float->Void;

	public function newnew(X:Float, Y:Float, Length:Float, Start:Float, Size:Float, w:Int, h:Int) {
		this.x = X;
		this.y = Y;

		loadGraphic(Paths.image("editors/ui/scrollbarhorizontal-bg"));
		scale.x = w;
		alpha = 0.5;
		updateHitbox();
		start = Start;
		size = Size;
		length = Length;
		
		thumb = new UISliceSprite(0, 0, w, h, 'editors/ui/scrollbar');
		thumb.cursor = MouseCursor.BUTTON;
		members.push(thumb);

		thumbIcon = new FlxSprite(0, 0);
		thumbIcon.loadGraphic(Paths.image('editors/ui/scrollbar-icon'));
		members.push(thumbIcon);
	}


	public override function update(elapsed:Float) {
		var lastHovered = hovered;
		var lastHoveredThumb = thumb.hovered;
		super.update(elapsed);
		
		//thumb.follow(this, 0, FlxMath.remapToRange(start, -(size/2), length + size, 0, height));
		thumb.y = y;
		thumb.x = x + FlxMath.remapToRange(start, -(size/2), length + size, 0, width);
		thumb.cameras = cameras;
		thumb.bWidth = Std.int(FlxMath.remapToRange(size, -(size/2), length + size, 0, width));

		//trace("s");
		//thumbIcon.follow(thumb, 0, Std.int((thumb.bHeight - thumbIcon.height) / 2));
		thumbIcon.y = thumb.y;
		thumbIcon.x = thumb.x + Std.int((thumb.bWidth - thumbIcon.width) / 2);
		thumbIcon.cameras = cameras;
		thumbIcon.alpha = thumb.bWidth > 30 ? 1 : 0;

		
		if ((lastHovered || lastHoveredThumb) && FlxG.mouse.pressed) {
			thumb.framesOffset = 18;
			var mousePos = FlxG.mouse.getScreenPosition(__lastDrawCameras[0], FlxPoint.get());
			var yPos = FlxMath.bound(FlxMath.remapToRange(mousePos.x, x, x+width, -(size/2), length + size), 0, length);
			if (yPos >= 0 && yPos < length) {
				value = yPos;
				if (onChange != null)
					onChange(value);
			}
			mousePos.put();
		} else
			thumb.framesOffset = lastHoveredThumb ? 9 : 0;
		
	}
}