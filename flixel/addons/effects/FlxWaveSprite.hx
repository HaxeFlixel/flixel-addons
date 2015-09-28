package flixel.addons.effects;

import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;

/**
 * This creates a FlxSprite which copies a target FlxSprite and applies a non-destructive wave-distortion effect.
 * Usage: Create a FlxSprite object, position it where you want (don't add it), and then create a new FlxWaveSprite, 
 * passing the Target object to it, and then add the FlxWaveSprite to your state/group.
 * @author Tim Hely / tims-world.com
 */
class FlxWaveSprite extends FlxSprite
{
	private static inline var BASE_STRENGTH:Float = 0.06;
	
	/**
	 * The target FlxSprite we're going to be using
	 */
	public var target(default, null):FlxSprite;
	
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
	public var center:Int;
	/**
	 * Which direction the wave effect should be applied.
	 */
	public var direction(default, set):FlxWaveDirection;
	/**
	 * How strong the wave effect should be
	 */
	public var strength(default, set):Int;
	
	private var _time:Float = 0;
	
	/**
	 * Creates a new FlxWaveSprite, which clones a target FlxSprite and applies a wave-distortion effect to the clone.
	 * 
	 * @param	Target		The target FlxSprite you want to clone.
	 * @param	Mode		Which Mode you would like to use for the effect. ALL = applies a constant distortion throughout the image, BOTTOM = makes the effect get stronger towards the bottom of the image, and TOP = the reverse of BOTTOM
	 * @param	Strength	How strong you want the effect
	 * @param	Center		The 'center' of the effect when using BOTTOM or TOP modes. Anything above(BOTTOM)/below(TOP) this point on the image will have no distortion effect.
	 * @param	Speed		How fast you want the effect to move. Higher values = faster.
	 * @param	Direction	Which Direction you want the effect to be applied (VERTICAL or HORIZONTAL)
	 */
	public function new(Target:FlxSprite, ?Mode:FlxWaveMode, Strength:Int = 20, Center:Int = -1, Speed:Float = 3, ?Direction:FlxWaveDirection) 
	{
		super();
		target = Target;
		strength = Strength;
		mode = (Mode == null) ? ALL : Mode;
		speed = Speed;
		direction = (Direction != null) ? Direction : VERTICAL;
		if (Center < 0)
			center = Std.int(((direction == VERTICAL) ? target.height : target.width) * 0.5);
		initPixels();
		dirty = true;
	}
	
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		_time += elapsed * speed;
	}
	
	override public function draw():Void
	{
		if (!visible || alpha == 0)
			return;
		
		pixels.lock();
		pixels.fillRect(pixels.rect, FlxColor.TRANSPARENT);
		
		var offset:Float = 0;
		var length = (direction == VERTICAL) ? target.frameHeight : target.frameWidth;
		for (oY in 0...length)
		{
			var p:Float = 0;
			switch (mode)
			{
				case ALL:
					offset = center * calculateOffset(oY);
					
				case BOTTOM:
					if (oY >= center)
					{
						p = oY - center;
						offset = p * calculateOffset(p);
					}
					
				case TOP:
					if (oY <= center)
					{
						p = center - oY;
						offset = p * calculateOffset(p);
					}
			}
			
			if (direction == VERTICAL)
			{
				_flashPoint.setTo(strength + offset, oY);
				_flashRect2.setTo(0, oY, target.frameWidth, 1);
			}
			else
			{
				_flashPoint.setTo(oY, strength + offset);
				_flashRect2.setTo(oY, 0, 1, target.frameHeight);
			}
			pixels.copyPixels(target.framePixels, _flashRect2, _flashPoint);
		}
		
		pixels.unlock();
		
		dirty = true;
		super.draw();
	}
	
	private inline function calculateOffset(p:Float):Float
	{
		return (strength * BASE_STRENGTH) * BASE_STRENGTH * Math.sin((0.3 * p) + _time);
	}
	
	private function initPixels():Void
	{
		var oldGraphic:FlxGraphic = graphic;
		
		var verticalStrength = (direction == VERTICAL) ? strength : 0;
		var horizontalStrength = (direction == HORIZONTAL) ? strength : 0;
		target.drawFrame(true);
		setPosition(target.x - verticalStrength, target.y - horizontalStrength);
		makeGraphic(
			Std.int(target.frameWidth + verticalStrength * 2),
			Std.int(target.frameHeight + horizontalStrength * 2),
			FlxColor.TRANSPARENT, true);
		_flashPoint.setTo(verticalStrength, horizontalStrength);
		
		pixels.copyPixels(target.framePixels, target.framePixels.rect, _flashPoint);
		dirty = true;
		FlxG.bitmap.removeIfNoUse(oldGraphic);
	}
	
	private function set_direction(Value:FlxWaveDirection):FlxWaveDirection
	{
		if (direction != Value)
		{
			direction = Value;
			initPixels();
		}
		return direction;
	}
	
	private function set_strength(value:Int):Int 
	{
		if (strength != value)
		{
			strength = value;
			initPixels();
		}
		return strength;
	}
}

enum FlxWaveMode
{
	ALL;
	TOP;
	BOTTOM;
}

enum FlxWaveDirection
{
	VERTICAL;
	HORIZONTAL;
}