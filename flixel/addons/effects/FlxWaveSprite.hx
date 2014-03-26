package flixel.addons.effects;

import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;

/**
 * This creates a FlxSprite which copies a target FlxSprite and applies a non-destructive wave-distortion effect.
 * Usage: Create a FlxSprite object, position it where you want (don't add it), and then create a new FlxWaveSprite, 
 * passing the Target object to it, and then add the FlxWaveSprite to your state/group.
 * @author Tim Hely / tims-world.com
 */
class FlxWaveSprite extends FlxSprite
{

	private static inline var baseStr:Float = 0.06;
	
	static public inline var MODE_ALL:Int = 0; // the entire sprite should be wavy
	static public inline var MODE_BOTTOM:Int = 1; // the bottom half should be wavy
	static public inline var MODE_TOP:Int = 2; // the top half should be wavy

	/*
	 * Which mode we're using for the effect
	 */
	public var mode:Int = 0;
	
	/*
	 * The target FlxSprite we're going to be using
	 */
	private var _target:FlxSprite;
	
	private var _time:Float = 0;
	private var _targetOff:Float = -999;
	
	/*
	 * How strong the wave effect should be
	 */
	public var strength(default, set_strength):Int = 20;
	
	/*
	 * How fast should the wave effect be (higher = faster)
	 */
	public var speed:Float = 4;
	
	/*
	 * The 'center' of our sprite (where the wave effect should start/end)
	 */
	public var center:Int;
	
	/**
	 * Creates a new FlxWaveSprite, which clones a target FlxSprite and applies a wave-distortion effect to the clone.
	 * 
	 * @param	Target		The target FlxSprite you want to clone.
	 * @param	Mode		Which Mode you would like to use for the effect. ALL = applies a constant distortion throughout the image, BOTTOM = makes the effect get stronger towards the bottom of the image, and TOP = the reverse of BOTTOM
	 * @param	Strength	How strong you want the effect
	 * @param	Center		The 'center' of the effect when using BOTTOM or TOP modes. Anything above(BOTTOM)/below(TOP) this point on the image will have no distortion effect.
	 * @param	Speed		How fast you want the effect to move. Higher values = faster.
	 */
	public function new(Target:FlxSprite, Mode:Int = 0, Strength:Int = 40, Center:Int = -1, Speed:Float = 3) 
	{
		super();
		_target = Target;
		strength = Strength;
		mode = Mode;
		speed = Speed;
		if (Center < 0)
		{
			center = Std.int(_target.height * .33);
		}
		initPixels();
		dirty = true;
	}
	
	override public function draw():Void
	{
		if (!visible || alpha == 0)
			return;
		pixels.fillRect(pixels.rect, 0x0);
		var off:Float = 0;
		for (oY in 0...Std.int(_target.height))
		{
			var p:Float=0;
			switch(mode)
			{
				case MODE_ALL:
					p = oY;
					off = (center*(strength*baseStr)) * baseStr * Math.sin((.3 * (p)) + _time);
				case MODE_BOTTOM:
					if (oY < center)
					{
						off = 0;
					}
					else
					{
						p = oY - center;
						off = ((p) * (strength*baseStr)) * baseStr * Math.sin((.3 * (p)) + _time);
					}
				case MODE_TOP:
					if (oY > center)
					{
						off = 0;
					}
					else
					{
						p  = center - oY;
						off = ((p) * (strength*baseStr)) * baseStr * Math.sin((.3 * (p)) + _time);
					}
					
			}
			_flashPoint.setTo(strength + off, oY);
			_flashRect2.setTo(0, oY, _target.width, 1);
			pixels.copyPixels(_target.pixels, _flashRect2, _flashPoint);
		}
		if (_targetOff == -999)
		{
			_targetOff = off;
		}
		else
		{
			if (off == _targetOff)
				_time = 0;
		}
		_time += FlxG.elapsed*speed;
		
		resetFrameBitmapDatas();
		dirty = true;
		super.draw();
	}
	
	private function initPixels():Void
	{
		setPosition(_target.x -strength, _target.y);
		makeGraphic(Std.int(_target.width + (strength * 2)), Std.int(_target.height), 0x0, true);
		_flashPoint.setTo(strength, 0);
		pixels.copyPixels(_target.pixels, _target.pixels.rect, _flashPoint);
	}
	
	private function set_strength(value:Int):Int 
	{
		strength = value;
		initPixels();
		return strength;
	}
	
}