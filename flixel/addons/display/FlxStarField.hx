/**
 * The logic in this module is largely ported from StarfieldFX.as by Richard Davey / photonstorm
 * @see https://github.com/photonstorm/Flixel-Power-Tools/blob/master/src/org/flixel/plugin/photonstorm/FX/StarfieldFX.as
 */

package flixel.addons.display;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxGradient;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;

class FlxStarField2D extends FlxStarField
{
	public var starVelocityOffset(default, null):FlxPoint;

	public function new(X:Int = 0, Y:Int = 0, Width:Int = 0, Height:Int = 0, StarAmount:Int = 300)
	{
		super(X, Y, Width, Height, StarAmount);
		starVelocityOffset = FlxPoint.get(-1, 0);
		setStarDepthColors(5, 0xff585858, 0xffF4F4F4);
		setStarSpeed(100, 400);
	}

	override public function destroy():Void
	{
		starVelocityOffset = FlxDestroyUtil.put(starVelocityOffset);
		super.destroy();
	}

	override public function update(elapsed:Float):Void
	{
		for (star in _stars)
		{
			star.x += (starVelocityOffset.x * star.speed) * elapsed;
			star.y += (starVelocityOffset.y * star.speed) * elapsed;

			// wrap the star
			if (star.x > width)
			{
				star.x = 0;
			}
			else if (star.x < 0)
			{
				star.x = width;
			}

			if (star.y > height)
			{
				star.y = 0;
			}
			else if (star.y < 0)
			{
				star.y = height;
			}
		}

		super.update(elapsed);
	}
}

class FlxStarField3D extends FlxStarField
{
	public var center(default, null):FlxPoint;

	public function new(X:Int = 0, Y:Int = 0, Width:Int = 0, Height:Int = 0, StarAmount:Int = 300)
	{
		super(X, Y, Width, Height, StarAmount);
		center = FlxPoint.get(width / 2, height / 2);
		setStarDepthColors(300, 0xff292929, 0xffffffff);
		setStarSpeed(0, 200);
	}

	override public function destroy():Void
	{
		center = FlxDestroyUtil.put(center);
		super.destroy();
	}

	override public function update(elapsed:Float):Void
	{
		for (star in _stars)
		{
			star.d *= 1.1;
			star.x = center.x + ((Math.cos(star.r) * star.d) * star.speed) * elapsed;
			star.y = center.y + ((Math.sin(star.r) * star.d) * star.speed) * elapsed;

			if ((star.x < 0) || (star.x > width) || (star.y < 0) || (star.y > height))
			{
				star.d = 1;
				star.r = FlxG.random.float() * Math.PI * 2;
				star.x = 0;
				star.y = 0;
				star.speed = FlxG.random.float(_minSpeed, _maxSpeed);

				_stars[star.index] = star;
			}
		}

		super.update(elapsed);
	}
}

private class FlxStarField extends FlxSprite
{
	public var bgColor:Int = FlxColor.BLACK;

	var _stars:Array<FlxStar>;
	var _depthColors:Array<Int>;
	var _minSpeed:Float;
	var _maxSpeed:Float;

	public function new(X:Int, Y:Int, Width:Int, Height:Int, StarAmount:Int)
	{
		super(X, Y);
		Width = (Width <= 0) ? FlxG.width : Width;
		Height = (Height <= 0) ? FlxG.height : Height;
		makeGraphic(Width, Height, bgColor, true);
		_stars = [];

		for (i in 0...StarAmount)
		{
			var star = new FlxStar();
			star.index = i;
			star.x = FlxG.random.int(0, Width);
			star.y = FlxG.random.int(0, Height);
			star.d = 1;
			star.r = FlxG.random.float() * Math.PI * 2;
			_stars.push(star);
		}
	}

	override public function destroy():Void
	{
		for (star in _stars)
		{
			star = null;
		}
		_stars = null;
		_depthColors = null;
		super.destroy();
	}

	override public function draw():Void
	{
		pixels.lock();
		pixels.fillRect(_flashRect, bgColor);

		for (star in _stars)
		{
			var colorIndex:Int = Std.int(((star.speed - _minSpeed) / (_maxSpeed - _minSpeed)) * _depthColors.length);
			pixels.setPixel32(Std.int(star.x), Std.int(star.y), _depthColors[colorIndex]);
		}

		pixels.unlock();
		framePixels = pixels;
		dirty = false;
		super.draw();
	}

	/**
	 * Change the number of layers (depth) and colors used for each layer of the starfield.
	 *
	 * @param	Depth			Number of depths (for a 2D starfield the default is 5)
	 * @param	LowestColor		The color given to the slowest stars, typically the darker colour
	 * @param	HighestColor	The color given to the fastest stars, typically the brighter colour
	 */
	public inline function setStarDepthColors(Depth:Int, LowestColor:Int = 0xff85858, HighestColor:Int = 0xffF4F4F4):Void
	{
		_depthColors = FlxGradient.createGradientArray(1, Depth, [LowestColor, HighestColor]);
	}

	public function setStarSpeed(Min:Int, Max:Int):Void
	{
		_minSpeed = Min;
		_maxSpeed = Max;

		for (star in _stars)
		{
			star.speed = FlxG.random.float(Min, Max);
		}
	}
}

private class FlxStar
{
	public var index:Int;
	public var x:Float;
	public var y:Float;
	public var d:Float;
	public var r:Float;
	public var speed:Float;

	public function new() {}
}
