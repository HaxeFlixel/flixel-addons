package flixel.addons.effects;

import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;

/**
 * ...
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
	private var _strength:Int = 20;
	
	/*
	 * The 'center' of our sprite (where the wave effect should start/end)
	 */
	public var center:Int;
	
	public function new(Target:FlxSprite, Mode:Int = 0, Strength:Int = 40, Center:Int = -1) 
	{
		super();
		_target = Target;
		strength = Strength;
		mode = Mode;
		if (Center < 0)
		{
			center = Std.int(_target.height * .33);
		}
		initPixels();
		dirty = true;
	}
	
	override public function draw():Void
	{
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

			pixels.copyPixels(_target.pixels, new Rectangle(0, oY, _target.width, 1), new Point(strength+off, oY));
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
		_time += FlxG.elapsed*4;
		
		resetFrameBitmapDatas();
		dirty = true;
		super.draw();
	}
	
	private function initPixels():Void
	{
		setPosition(_target.x -strength, _target.y);
		makeGraphic(Std.int(_target.width + (strength * 2)), Std.int(_target.height), 0x0, true);
		pixels.copyPixels(_target.pixels, _target.pixels.rect, new Point(strength, 0));
	}
	
	function get_strength():Int 
	{
		return _strength;
	}
	
	function set_strength(value:Int):Int 
	{
		_strength = value;
		initPixels();
		return _strength;
	}

	
	public var strength(get_strength, set_strength):Int;
	
}