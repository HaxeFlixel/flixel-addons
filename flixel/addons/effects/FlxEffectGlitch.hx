package flixel.addons.effects;
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
class FlxEffectGlitch implements IFlxEffect
{
	public var active:Bool = true;
	public var offsetDraw:Point;
	
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
	public var direction(default, set):FlxGlitchDirection;
	/**
	 * How strong the glitch effect should be (how much it should move from the center)
	 */
	public var strength(default, set):Int = 2;
	
	private var _time:Float = 0;
	
	private var _pixels:BitmapData;
	
	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	private var _flashPoint:Point;
	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	private var _flashRect:Rectangle;
	
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
		
		offsetDraw = new Point();
		_flashPoint = new Point();
		_flashRect = new Rectangle();
	}
	
	public function destroy():Void 
	{
		offsetDraw = null;
		_flashPoint = null;
		_flashRect = null;
		
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
			offsetDraw.setTo( -horizontalStrength, -verticalStrength);
			
			_pixels = new BitmapData(bitmapData.width + horizontalStrength * 2, bitmapData.height + verticalStrength * 2, true, FlxColor.TRANSPARENT);
			
			var p:Int = 0;
			if (direction == HORIZONTAL)
			{
				while (p < bitmapData.height) 
				{
					_flashRect.setTo(0, p, bitmapData.width, size);
					if (_flashRect.bottom > bitmapData.height)
						_flashRect.bottom = bitmapData.height;
					_flashPoint.setTo(FlxG.random.int( -strength, strength) + strength, p);
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
					_flashPoint.setTo(p, FlxG.random.int( -strength, strength) + strength);
					p += Std.int(_flashRect.width);
					_pixels.copyPixels(bitmapData, _flashRect, _flashPoint);
				}
			}
		}
		
		if (_pixels != null)
			return _pixels;
			
		return bitmapData;
	}
	
	private function set_direction(Value:FlxGlitchDirection):FlxGlitchDirection
	{
		if (direction != Value)
		{
			direction = Value;
		}
		return direction;
	}
	
	private function set_strength(Value:Int):Int
	{
		if (strength != Value)
		{
			strength = Value;
		}
		return strength;
	}
}

enum FlxGlitchDirection
{
	HORIZONTAL;
	VERTICAL;
}