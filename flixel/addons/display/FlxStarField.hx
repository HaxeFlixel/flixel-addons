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

#if FLX_NO_COVERAGE_TEST
@:deprecated('FlxStarField2D was moved to flixel.addons.display.FlxStarField2D')
typedef FlxStarField2D = flixel.addons.display.FlxStarField2D;

@:deprecated('FlxStarField3D was moved to flixel.addons.display.FlxStarField3D')
typedef FlxStarField3D = flixel.addons.display.FlxStarField3D;
#end

class FlxStarField extends FlxSprite
{
	public var bgColor:Int = FlxColor.BLACK;

	var _stars:Array<FlxStar>;
	var _depthColors:Array<Int>;
	var _minSpeed:Float;
	var _maxSpeed:Float;

	public function new(x:Int, y:Int, width = 0, height = 0, starAmount:Int)
	{
		super(x, y);
		width = (width <= 0) ? FlxG.width : width;
		height = (height <= 0) ? FlxG.height : height;
		makeGraphic(width, height, bgColor, true);
		_stars = [];

		for (i in 0...starAmount)
		{
			var star = new FlxStar();
			star.index = i;
			star.x = FlxG.random.int(0, width);
			star.y = FlxG.random.int(0, height);
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

class FlxStar
{
	public var index:Int;
	public var x:Float;
	public var y:Float;
	public var d:Float;
	public var r:Float;
	public var speed:Float;

	public function new() {}
}
