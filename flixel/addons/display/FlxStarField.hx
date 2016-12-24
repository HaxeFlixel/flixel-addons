/**
 * The logic in this module is largely ported from StarfieldFX.as by Richard Davey / photonstorm
 * @see https://github.com/photonstorm/Flixel-Power-Tools/blob/master/src/org/flixel/plugin/photonstorm/FX/StarfieldFX.as
 */
package flixel.addons.display;

import haxe.ds.Vector;
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
		starVelocityOffset = FlxPoint.get( -1, 0);
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
		for (s in 0..._starsX.length)
		{
			_starsX[s] += (starVelocityOffset.x * _starsSpeed[s]) * elapsed;
			_starsY[s] += (starVelocityOffset.y * _starsSpeed[s]) * elapsed;
			
			// wrap the star
			if (_starsX[s] > width)
			{
				_starsX[s] = 0;
			}
			else if (_starsX[s] < 0)
			{
				_starsX[s] = width;
			}
			
			if (_starsY[s] > height)
			{
				_starsY[s] = 0;
			}
			else if (_starsY[s] < 0)
			{
				_starsY[s] = height;
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
		for (s in 0..._starsX.length)
		{
			_starsD[s] *= 1.1;
			_starsX[s] = center.x + ((Math.cos(_starsR[s]) * _starsD[s]) * _starsSpeed[s]) * elapsed;
			_starsY[s] = center.y + ((Math.sin(_starsR[s]) * _starsD[s]) * _starsSpeed[s]) * elapsed;

			if ((_starsX[s] < 0) || (_starsX[s] > width) || (_starsY[s] < 0) || (_starsY[s] > height))
			{
				_starsD[s] = 1;
				_starsR[s] = FlxG.random.float() * Math.PI * 2;
				_starsX[s] = 0;
				_starsY[s] = 0;
				_starsSpeed[s] = FlxG.random.float(_minSpeed, _maxSpeed);
			}
		}
		
		super.update(elapsed);
	}
}

private class FlxStarField extends FlxSprite
{
	public var bgColor:Int = FlxColor.BLACK;

	private var _starsX:Vector<Float>;
	private var _starsY:Vector<Float>;
	private var _starsD:Vector<Float>;
	private var _starsR:Vector<Float>;
	private var _starsSpeed:Vector<Float>;

	private var _depthColors:Array<Int>;
	private var _minSpeed:Float;
	private var _maxSpeed:Float;
	
	public function new(X:Int, Y:Int, Width:Int, Height:Int, StarAmount:Int) 
	{
		super(X, Y);
		Width = (Width <= 0) ? FlxG.width : Width;
		Height = (Height <= 0) ? FlxG.height : Height;
		makeGraphic(Width, Height, bgColor, true);
		_starsX = new Vector(StarAmount);
		_starsY = new Vector(StarAmount);
		_starsD = new Vector(StarAmount);
		_starsR = new Vector(StarAmount);
		_starsSpeed = new Vector(StarAmount);

		for (i in 0...StarAmount)
		{
			_starsX[i] = FlxG.random.int(0, Width);
			_starsY[i] = FlxG.random.int(0, Height);
			_starsD[i] = 1;
			_starsR[i] = FlxG.random.float() * Math.PI * 2;
		}
	}
	
	override public function destroy():Void
	{
		_starsX = null;
		_starsY = null;
		_starsD = null;
		_starsR = null;
		_starsSpeed = null;
		_depthColors = null;
		super.destroy();
	}
	
	override public function draw():Void
	{
		pixels.lock();
		pixels.fillRect(_flashRect, bgColor);
		
		for (s in 0..._starsX.length)
		{
			var colorIndex:Int = Std.int(((_starsSpeed[s] - _minSpeed) / (_maxSpeed - _minSpeed)) * _depthColors.length);
			pixels.setPixel32(Std.int(_starsX[s]), Std.int(_starsY[s]), _depthColors[colorIndex]);
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
		
		for (s in 0..._starsX.length)
		{
			_starsSpeed[s] = FlxG.random.float(Min, Max);
		}
	}
}