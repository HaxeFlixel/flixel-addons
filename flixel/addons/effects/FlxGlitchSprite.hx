package flixel.addons.effects;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxRandom;

/**
 * This creates a FlxSprite which copies a target FlxSprite and applies a non-destructive wave-distortion effect.
 * Usage: Create a FlxSprite object, position it where you want (don't add it), and then create a new FlxGlitchSprite, 
 * passing the Target object to it, and then add the sprite to your state/group.
 * Based, in part, from PhotonStorm's GlitchFX Class in Flixel Power Tools.
 * @author Tim Hely / tims-world.com
 */
class FlxGlitchSprite extends FlxSprite
{
	/**
	 * How thick each glitch segment should be.
	 */
	public var size:Int = 1;
	/**
	 * Time, in seconds, between glitch updates
	 */
	public var delay:Float = 0.05;
	/**
	 * The target FlxSprite that the glitch effect copies from.
	 */
	public var target:FlxSprite;
	/**
	 * Which direction the glitch effect should be applied.
	 */
	public var direction(default, set):FlxGlitchDirection;
	/**
	 * How strong the glitch effect should be (how much it should move from the center)
	 */
	public var strength(default, set):Int = 2;
	
	private var _time:Float = 0;
	
	/**
	 * Creates a new FlxGlitchSprite, which clones a target FlxSprite and applies a Glitch-distortion effect to the clone.
	 * This effect is non-destructive to the target's pixels, and can be used on animated FlxSprites.
	 * 
	 * @param	Target		The target FlxSprite you want to clone.
	 * @param	Strength	How strong you want the effect
	 * @param	Size		How 'thick' you want each piece of the glitch
	 * @param	Delay		How long (in seconds) between each glitch update
	 * @param	Direction	Which Direction you want the effect to be applied (HORIZONTAL or VERTICAL)
	 */
	public function new(Target:FlxSprite, Strength:Int = 4, Size:Int = 1, Delay:Float = 0.05, ?Direction:FlxGlitchDirection) 
	{
		super();
		target = Target;
		strength = Strength;
		size = Size;
		if (Direction != null)
			direction = Direction;
		else
			direction = HORIZONTAL;
		initPixels();
	}
	
	override public function draw():Void
	{
		if (alpha == 0 || target == null)
			return;
			
		if (_time > delay)
		{
			_time = 0;
			pixels.lock();
			pixels.fillRect(pixels.rect, FlxColor.TRANSPARENT);
			var p:Int = 0;
			if (direction == HORIZONTAL)
			{
				
				while (p < target.frameHeight) 
				{
					_flashRect2.setTo(0, p, target.frameWidth, size);
					if (_flashRect2.bottom > target.frameHeight)
						_flashRect2.bottom = target.frameHeight;
					_flashPoint.setTo(FlxRandom.intRanged( -strength, strength) + strength, p);
					p += Std.int(_flashRect2.height);
					pixels.copyPixels(target.framePixels, _flashRect2, _flashPoint);
				}
			}
			else
			{
				while (p < target.frameWidth) 
				{
					_flashRect2.setTo(p, 0, size, target.frameHeight);
					if (_flashRect2.right > target.frameWidth)
						_flashRect2.right = target.frameWidth;
					_flashPoint.setTo(p, FlxRandom.intRanged( -strength, strength) + strength);
					p += Std.int(_flashRect2.width);
					pixels.copyPixels(target.framePixels, _flashRect2, _flashPoint);
				}
			}
			
			resetFrameBitmapDatas();
			pixels.unlock();
			dirty = true;
		}
		else
			_time += FlxG.elapsed;
		super.draw();
	}
	
	private function initPixels():Void
	{
		target.drawFrame();	
		setPosition(target.x - (direction == HORIZONTAL ? strength : 0), target.y - (direction == VERTICAL ? strength : 0));
		makeGraphic(Std.int(target.frameWidth + (direction == HORIZONTAL ? strength * 2 : 0)), Std.int(target.frameHeight + (direction == VERTICAL ? strength * 2 : 0 )), FlxColor.TRANSPARENT, true);
		_flashPoint.setTo((direction == HORIZONTAL ? strength : 0), (direction == VERTICAL ? strength : 0));
		pixels.copyPixels(target.pixels, target.pixels.rect, _flashPoint); 
		dirty = true;
	}
	
	private function set_direction(Value:FlxGlitchDirection):FlxGlitchDirection
	{
		if (direction != Value)
		{
			direction = Value;
			initPixels();
		}
		return direction;
	}
	
	private function set_strength(Value:Int):Int
	{
		if (strength != Value)
		{
			strength = Value;
			initPixels();
		}
		return strength;
	}
}

enum FlxGlitchDirection
{
	HORIZONTAL;
	VERTICAL;
}