package flixel.addons.effects.chainable;

import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * This is a modified version of FlxWaveSprite by Tim Hely
 *
 * @author Tim Hely / tims-world.com
 * @author adrianulima
 */
class FlxWaveEffect implements IFlxEffect
{
	public var active:Bool = true;
	public var offset(default, null):FlxPoint = FlxPoint.get();

	/**
	 * Which mode we're using for the effect.
	 */
	public var mode:FlxWaveMode;

	/**
	 * How fast should the wave effect be (higher = faster).
	 */
	public var speed:Float;

	/**
	 * The 'center' of our sprite (where the wave effect should start/end). Ratio based on the bitmapData size.
	 */
	public var center:Float;

	/**
	 * Which direction the wave effect should be applied.
	 */
	public var direction:FlxWaveDirection;

	/**
	 * How long waves are.
	 */
	public var wavelength:Int;

	/**
	 * How strong the wave effect should be.
	 */
	public var strength:Int;

	/**
	 * The wave ratio to offset every odd line of the `BitmapData`. Must be a value between 0 and 1.
	 * @since 2.1.0
	 */
	public var interlaceOffset(default, set):Float;

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
	 * Creates a new FlxEffectWave, which applies a wave-distortion effect.
	 *
	 * @param	Mode			Which Mode you would like to use for the effect. ALL = applies a constant distortion throughout the image, END = makes the effect get stronger towards the bottom of the image, and START = the reverse of END.
	 * @param	Strength		How strong you want the effect.
	 * @param	Center			The 'center' of the effect when using END or START modes. Anything before(END)/after(START) this point on the image will have no distortion effect. Ratio based on the bitmapData size.
	 * @param	Speed			How fast you want the effect to move. Higher values = faster.
	 * @param	Wavelength		How long waves are.
	 * @param	Direction		Which Direction you want the effect to be applied (HORIZONTAL or VERTICAL).
	 * @param	InterlaceOffset	The wave ratio to offset every odd line of the bitmapData. Must be a value between 0 and 1;
	 */
	public function new(?Mode:FlxWaveMode, Strength:Int = 10, Center:Float = 0.5, Speed:Float = 3, Wavelength:Int = 5, ?Direction:FlxWaveDirection,
			InterlaceOffset:Float = 0)
	{
		strength = Strength;
		mode = (Mode == null) ? ALL : Mode;
		speed = Speed;
		wavelength = Wavelength;
		direction = (Direction != null) ? Direction : HORIZONTAL;
		center = Center;
		interlaceOffset = InterlaceOffset;
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
		_time += elapsed * speed;
	}

	public function apply(bitmapData:BitmapData):BitmapData
	{
		var horizontalStrength:Int = (direction == HORIZONTAL) ? strength : 0;
		var verticalStrength:Int = (direction == VERTICAL) ? strength : 0;
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

		var length = (direction == HORIZONTAL) ? bitmapData.height : bitmapData.width;
		var p:Int = 0;
		while (p < length)
		{
			var pixelOffset:Float = 0;
			var offsetP:Float = length * center;
			var size:Int = 1;
			switch (mode)
			{
				case ALL:
					offsetP = strength;

				case START:
					if (p <= offsetP)
					{
						offsetP = (1 - p / offsetP) * strength;
					}
					else
					{
						size = length - p;
						offsetP = 0;
					}

				case END:
					if (p >= offsetP)
					{
						offsetP = (1 - (1 - (p / length)) / (1 - center)) * strength;
					}
					else
					{
						size = Math.ceil(offsetP);
						offsetP = 0;
					}
			}

			pixelOffset = offsetP * calculateOffset(p, length);

			if (direction == HORIZONTAL)
			{
				_flashPoint.setTo(strength + pixelOffset, p);
				_flashRect.setTo(0, p, bitmapData.width, size);
			}
			else
			{
				_flashPoint.setTo(p, strength + pixelOffset);
				_flashRect.setTo(p, 0, size, bitmapData.height);
			}
			_pixels.copyPixels(bitmapData, _flashRect, _flashPoint);

			p += size;
		}
		FlxDestroyUtil.dispose(bitmapData);

		return _pixels.clone();
	}

	inline function calculateOffset(p:Float, length:Int):Float
	{
		var waveOffset:Float = 0;
		if (interlaceOffset != 0 && interlaceOffset != 1 && FlxMath.isOdd(p))
		{
			waveOffset = Math.PI * 2 * interlaceOffset;
		}

		return FlxMath.fastSin((p / wavelength) + _time + waveOffset);
	}

	function set_interlaceOffset(InterlaceOffset:Float):Float
	{
		return interlaceOffset = FlxMath.bound(InterlaceOffset, 0, 1);
	}
}

enum FlxWaveMode
{
	ALL;
	START;
	END;
}

enum FlxWaveDirection
{
	HORIZONTAL;
	VERTICAL;
}
