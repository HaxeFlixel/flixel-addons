package flixel.addons.effects.chainable;

import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.geom.Point;

/**
 * This is a modified version of FlxRainbowSprite by Tim Hely
 *
 * @author Tim Hely / tims-world.com
 * @author adrianulima
 */
class FlxRainbowEffect implements IFlxEffect
{
	public var active:Bool = true;
	public var offset(default, null):FlxPoint;

	/**
	 * How fast the hue should change each tick.
	 */
	public var speed:Float = 5;

	/**
	 * Set alpha to a number between 0 and 1 to change the opacity of the effect.
	 */
	public var alpha:Float = 1;

	/**
	 * A number between 0 and 1, indicating how bright the color should be. 0 is black, 1 is full bright.
	 */
	public var brightness:Float = 1;

	/**
	 * The current hue of the effect
	 */
	var _hue:Int = 0;

	/**
	 * Used to adjust the hue using speed
	 */
	var _time:Float = 0;

	/**
	 * Internal, reused frequently during drawing and animating. Always contains (0,0).
	 */
	var _flashPoint:Point = new Point();

	/**
	 * The actual Flash BitmapData object representing the current effect state.
	 */
	var _pixels:BitmapData;

	/**
	 * Creates a new FlxEffectRainbow, which applies a color-cycling effect, using the target's bitmap as a mask.
	 *
	 * @param	Alpha		A number between 0 and 1 to change the opacity of the effect.
	 * @param	Brightness	A number between 0 and 1, indicating how bright the color should be.
	 * @param	Speed		How fast the hue should change each tick.
	 * @param	StartHue	The initial hue of the effect.
	 */
	public function new(Alpha:Float = 1, Brightness:Float = 1, Speed:Float = 5, StartHue:Int = 0)
	{
		alpha = Alpha;
		brightness = Brightness;
		speed = Speed;
		_time = _hue = Std.int(FlxMath.bound(StartHue, 0, 360));
	}

	public function destroy():Void
	{
		_flashPoint = null;

		_pixels = FlxDestroyUtil.dispose(_pixels);
	}

	public function update(elapsed:Float):Void
	{
		_time += speed;
		_hue = Std.int(_time);
		if (_hue > 360)
		{
			_hue = 0;
			_time -= 360;
		}
	}

	public function apply(bitmapData:BitmapData):BitmapData
	{
		if (_pixels == null || _pixels.width < bitmapData.width || _pixels.height < bitmapData.height)
		{
			FlxDestroyUtil.dispose(_pixels);
			_pixels = new BitmapData(bitmapData.width, bitmapData.height, true, FlxColor.fromHSB(_hue, 1, brightness, alpha));
		}
		else
		{
			_pixels.fillRect(_pixels.rect, FlxColor.fromHSB(_hue, 1, brightness, alpha));
		}

		bitmapData.copyPixels(_pixels, _pixels.rect, _flashPoint, bitmapData, null, true);

		return bitmapData;
	}
}
