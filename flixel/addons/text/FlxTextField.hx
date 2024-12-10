package flixel.addons.text;

import openfl.display.BitmapData;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;

/**
 * Extends FlxText for better support rendering text on cpp target.
 * Doesn't have multicamera support.
 * Displays over all other objects.
 */
class FlxTextField extends FlxText
{
	/**
	 * Creates a new FlxText object at the specified position.
	 * @param	X				The X position of the text.
	 * @param	Y				The Y position of the text.
	 * @param	Width			The width of the text object (height is determined automatically).
	 * @param	Text			The actual text you would like to display initially.
	 * @param	Size			The font size for this text object.
	 * @param	EmbeddedFont	Whether this text field uses embedded fonts or not
	 */
	public function new(X:Float, Y:Float, Width:Int, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
	{
		super(X, Y, Width, Text, Size, EmbeddedFont);

		height = (Text == null || Text.length <= 0) ? 1 : textField.textHeight + 4;

		textField.multiline = false;
		textField.wordWrap = false;
		updateDefaultFormat();

		dirty = false;
	}

	/**
	 * Clean up memory.
	 */
	override public function destroy():Void
	{
		FlxG.removeChild(textField);
		super.destroy();
	}

	override public function stamp(Brush:FlxSprite, X:Int = 0, Y:Int = 0):Void
	{
		// This class doesn't support this operation
	}

	override public function pixelsOverlapPoint(point:FlxPoint, Mask:Int = 0xFF, ?Camera:FlxCamera):Bool
	{
		// This class doesn't support this operation
		return false;
	}

	override public function isSimpleRender(?camera:FlxCamera):Bool
	{
		// This class doesn't support this operation
		return true;
	}

	override function get_pixels():BitmapData
	{
		calcFrame(true);
		return graphic.bitmap;
	}

	override function set_pixels(Pixels:BitmapData):BitmapData
	{
		// This class doesn't support this operation
		return Pixels;
	}

	override function set_alpha(Alpha:Float):Float
	{
		alpha = FlxMath.bound(Alpha, 0, 1);
		textField.alpha = alpha;
		return Alpha;
	}

	override function set_height(Height:Float):Float
	{
		Height = super.set_height(Height);
		if (textField != null)
			textField.height = Height;
		return Height;
	}

	override function set_visible(Value:Bool):Bool
	{
		textField.visible = Value;
		return super.set_visible(Value);
	}

	override public function kill():Void
	{
		visible = false;
		super.kill();
	}

	override public function revive():Void
	{
		visible = true;
		super.revive();
	}

	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen
	 */
	@:access(flixel.FlxCamera)
	override public function draw():Void
	{
		textField.visible = (FlxG.camera.visible && FlxG.camera.exists && isOnScreen(FlxG.camera));

		if (!textField.visible)
			return;

		textField.x = x - offset.x;
		textField.y = y - offset.y;

		textField.scaleX = scale.x;
		textField.scaleY = scale.y;

		FlxG.camera.transformObject(textField);

		#if FLX_DEBUG
		FlxBasic.visibleCount++;
		#end
	}

	override function get_camera():FlxCamera
	{
		return FlxG.camera;
	}

	override function set_camera(Value:FlxCamera):FlxCamera
	{
		return FlxG.camera;
	}
}
