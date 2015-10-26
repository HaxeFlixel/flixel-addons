package flixel.addons.effects;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * This is a modified version of FlxWaveSprite by Tim Hely
 * 
 * @author Tim Hely / tims-world.com
 * @author adrianulima
 */
class FlxEffectWave implements IFlxEffect
{
	private static inline var BASE_STRENGTH:Float = 0.06;
	
	public var active:Bool = true;
	public var offsetDraw:Point;
	
	/**
	 * Which mode we're using for the effect
	 */
	public var mode:FlxWaveMode;
	/**
	 * How fast should the wave effect be (higher = faster)
	 */
	public var speed:Float;
	/**
	 * The 'center' of our sprite (where the wave effect should start/end)
	 */
	public var center:Float;
	/**
	 * Which direction the wave effect should be applied.
	 */
	public var direction(default, set):FlxWaveDirection;
	/**
	 * How long waves are
	 */
	public var wavelength:Int;
	/**
	 * How strong the wave effect should be
	 */
	public var strength(default, set):Int;
	
	private var _time:Float = 0;
	
	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	private var _flashPoint:Point;
	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	private var _flashRect:Rectangle;
	
	/**
	 * Creates a new FlxEffectWave, which applies a wave-distortion effect.
	 * 
	 * @param	Mode		Which Mode you would like to use for the effect. ALL = applies a constant distortion throughout the image, END = makes the effect get stronger towards the bottom of the image, and START = the reverse of END
	 * @param	Strength	How strong you want the effect
	 * @param	Center		The 'center' of the effect when using END or START modes. Anything before(END)/after(START) this point on the image will have no distortion effect.
	 * @param	Speed		How fast you want the effect to move. Higher values = faster.
	 * @param	Wavelength	How long waves are.
	 * @param	Direction	Which Direction you want the effect to be applied (HORIZONTAL or VERTICAL)
	 */
	public function new(?Mode:FlxWaveMode, Strength:Int = 20, Center:Int = -1, Speed:Float = 3, Wavelength:Int = 5, ?Direction:FlxWaveDirection) 
	{
		strength = Strength;
		mode = (Mode == null) ? ALL : Mode;
		speed = Speed;
		wavelength = Wavelength;
		direction = (Direction != null) ? Direction : HORIZONTAL;
		if (Center < 0)
			center = 0.5;
		
		offsetDraw = new Point();
		_flashPoint = new Point();
		_flashRect = new Rectangle();
	}
	
	public function destroy():Void 
	{
		offsetDraw = null;
		_flashPoint = null;
		_flashRect = null;
	}
	
	public function update(elapsed:Float):Void 
	{
		_time += elapsed * speed;
	}
	
	public function apply(bitmapData:BitmapData):BitmapData 
	{
		var horizontalStrength = (direction == HORIZONTAL) ? strength : 0;
		var verticalStrength = (direction == VERTICAL) ? strength : 0;
		offsetDraw.setTo( -horizontalStrength, -verticalStrength);
		
		var pixels:BitmapData = new BitmapData(Std.int(bitmapData.width + horizontalStrength * 2), Std.int(bitmapData.height + verticalStrength * 2), true, FlxColor.TRANSPARENT);
		
		var offset:Float = 0;
		var centerP = Std.int(((direction == HORIZONTAL) ? bitmapData.height : bitmapData.width) * 0.5);
		var length = (direction == HORIZONTAL) ? bitmapData.height : bitmapData.width;
		for (p in 0...length)
		{
			var offsetP:Float = centerP;
			switch (mode)
			{
				case ALL:
					offset = offsetP * calculateOffset(p);
					
				case END:
					if (p >= centerP)
					{
						offsetP = p - centerP;
						offset = offsetP * calculateOffset(offsetP);
					}
					
				case START:
					if (p <= centerP)
					{
						offsetP = centerP - p;
						offset = offsetP * calculateOffset(offsetP);
					}
			}
			
			if (direction == HORIZONTAL)
			{
				_flashPoint.setTo(strength + offset, p);
				_flashRect.setTo(0, p, bitmapData.width, 1);
			}
			else
			{
				_flashPoint.setTo(p, strength + offset);
				_flashRect.setTo(p, 0, 1, bitmapData.height);
			}
			pixels.copyPixels(bitmapData, _flashRect, _flashPoint);
		}
		
		return pixels;
	}
	
	private inline function calculateOffset(p:Float):Float
	{
		return (strength * BASE_STRENGTH) * BASE_STRENGTH * FlxMath.fastSin((p / wavelength) + _time);
	}
	
	private function set_direction(Value:FlxWaveDirection):FlxWaveDirection
	{
		if (direction != Value)
		{
			direction = Value;
		}
		return direction;
	}
	
	private function set_strength(value:Int):Int
	{
		if (strength != value)
		{
			strength = value;
		}
		return strength;
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