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
	 * How strong the wave effect should be
	 */
	public var strength(default, set):Int;
	
	private var _targetOffset:Float = -999;
	
	private var _time:Float = 0;
	
	/**
	 * Creates a new FlxWaveSprite, which clones a target FlxSprite and applies a wave-distortion effect to the clone.
	 * 
	 * @param	Target		The target FlxSprite you want to clone.
	 * @param	Mode		Which Mode you would like to use for the effect. ALL = applies a constant distortion throughout the image, BOTTOM = makes the effect get stronger towards the bottom of the image, and TOP = the reverse of BOTTOM
	 * @param	Strength	How strong you want the effect
	 * @param	Center		The 'center' of the effect when using BOTTOM or TOP modes. Anything above(BOTTOM)/below(TOP) this point on the image will have no distortion effect.
	 * @param	Speed		How fast you want the effect to move. Higher values = faster.
	 */
	public function new(Target:FlxSprite, ?Mode:FlxWaveMode, Strength:Int = 20, Center:Int = -1, Speed:Float = 3) 
	{
		super();
		target = Target;
		strength = Strength;
		mode = (Mode == null) ? ALL : Mode;
		speed = Speed;
		if (Center < 0)
			center = Std.int(target.height * 0.5);
		initPixels();
		dirty = true;
	}
	
	override public function draw():Void 
	{
		drawFrame();
		super.draw();
	}
	
	override public function drawFrame(Force:Bool = false):Void 
	{
		if (target != null)
		{
			if (drawEffect())
				Force = true;
		}
		super.drawFrame(Force);
	}
	
	private function drawEffect():Bool
	{
			
		_time += FlxG.elapsed * speed;
		
		target.drawFrame(true);
		
		pixels.lock();
		pixels.fillRect(pixels.rect, FlxColor.TRANSPARENT);
		
		var offset:Float = 0;
		for (oY in 0...target.frameHeight)
		{
			var p:Float=0;
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
						p  = center - oY;
						offset = p * calculateOffset(p);
					}
			}
			
			_flashPoint.setTo(strength + offset, oY);
			_flashRect2.setTo(0, oY, target.frameWidth, 1);
			pixels.copyPixels(target.framePixels, _flashRect2, _flashPoint);
		}
		
		pixels.unlock();
		
		if (_targetOffset == -999)
		{
			_targetOffset = offset;
		}
		else
		{
			if (offset == _targetOffset)
				_time = 0;
		}
		dirty = true;
		return true;
	}
	
	private inline function calculateOffset(p:Float):Float
	{
		return (strength * BASE_STRENGTH) * BASE_STRENGTH * Math.sin((0.3 * p) + _time);
	}
	
	private function initPixels():Void
	{
		var oldGraphic:FlxGraphic = graphic;
		target.drawFrame(true);
		setPosition(target.x - strength, target.y);
		makeGraphic(Std.int(target.frameWidth + (strength * 2)), target.frameHeight, FlxColor.TRANSPARENT, true);
		_flashPoint.setTo(strength, 0);
		pixels.copyPixels(target.framePixels, target.framePixels.rect, _flashPoint);
		dirty = true;
		FlxG.bitmap.removeIfNoUse(oldGraphic);
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