package flixel.addons.effects.chainable;

import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * This is a modified version of FlxGlitchSprite by Tim Hely
 *
 * @author Tim Hely / tims-world.com
 * @author adrianulima
 */
class FlxGlitchEffect implements IFlxEffect
{
	public var active:Bool = true;
	public var offset(default, null):FlxPoint = FlxPoint.get();

	/**
	 * How thick each glitch segment should be.
	 */
	public var size:Int = 1;

	/**
	 * Time, in seconds, between glitch updates
	 */
	public var delay:Float = 0.05;

	/**
	 * Which direction the glitch effect should be applied.
	 */
	public var direction:FlxGlitchDirection;

	/**
	 * How strong the glitch effect should be (how much it should move from the center)
	 */
	public var strength:Int = 2;

	/**
	 * Current time of the effect.
	 */
	var _time:Float = 0;

	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	var _flashPoint:Point = new Point();

	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	var _flashRect:Rectangle = new Rectangle();

	/**
	 * The actual Flash BitmapData object representing the current effect state.
	 */
	var _pixels:BitmapData;

	/**
	 * Creates a new FlxGlitchSprite, which applies a Glitch-distortion effect.
	 * This effect is non-destructive to the target's pixels, and can be used on animated FlxSprites.
	 *
	 * @param	Strength	How strong you want the effect.
	 * @param	Size		How 'thick' you want each piece of the glitch.
	 * @param	Delay		How long (in seconds) between each glitch update.
	 * @param	Direction	Which Direction you want the effect to be applied (HORIZONTAL or VERTICAL).
	 */
	public function new(Strength:Int = 4, Size:Int = 1, Delay:Float = 0.05, ?Direction:FlxGlitchDirection)
	{
		strength = Strength;
		size = Size;
		delay = Delay;
		direction = (Direction != null) ? Direction : HORIZONTAL;
	}

	public function destroy():Void
	{
		_flashPoint = null;
		_flashRect = null;

		offset = FlxDestroyUtil.put(offset);
		_pixels = FlxDestroyUtil.dispose(_pixels);
	}

	public function update(elapsed:Float):Void
	{
		if (_time > delay)
		{
			_time = 0;
		}
		else
		{
			_time += elapsed;
		}
	}

	public function apply(bitmapData:BitmapData):BitmapData
	{
		if (_time == 0)
		{
			_time = 0;

			var horizontalStrength = (direction == HORIZONTAL) ? strength : 0;
			var verticalStrength = (direction == VERTICAL) ? strength : 0;
			offset.set(-horizontalStrength, -verticalStrength);

			if (_pixels == null
				|| _pixels.width < bitmapData.width + horizontalStrength * 2
				|| _pixels.height < bitmapData.height + verticalStrength * 2)
			{
				FlxDestroyUtil.dispose(_pixels);
				_pixels = new BitmapData(bitmapData.width + horizontalStrength * 2, bitmapData.height + verticalStrength * 2, true, FlxColor.TRANSPARENT);
			}
			else
			{
				_pixels.fillRect(_pixels.rect, FlxColor.TRANSPARENT);
			}

			var p:Int = 0;
			if (direction == HORIZONTAL)
			{
				while (p < bitmapData.height)
				{
					_flashRect.setTo(0, p, bitmapData.width, size);
					if (_flashRect.bottom > bitmapData.height)
						_flashRect.bottom = bitmapData.height;
					_flashPoint.setTo(FlxG.random.int(-strength, strength) + strength, p);
					p += Std.int(_flashRect.height);
					_pixels.copyPixels(bitmapData, _flashRect, _flashPoint);
				}
			}
			else
			{
				while (p < bitmapData.width)
				{
					_flashRect.setTo(p, 0, size, bitmapData.height);
					if (_flashRect.right > bitmapData.width)
						_flashRect.right = bitmapData.width;
					_flashPoint.setTo(p, FlxG.random.int(-strength, strength) + strength);
					p += Std.int(_flashRect.width);
					_pixels.copyPixels(bitmapData, _flashRect, _flashPoint);
				}
			}
		}

		if (_pixels != null)
		{
			FlxDestroyUtil.dispose(bitmapData);
			return _pixels.clone();
		}

		return bitmapData;
	}
}

enum FlxGlitchDirection
{
	HORIZONTAL;
	VERTICAL;
}
