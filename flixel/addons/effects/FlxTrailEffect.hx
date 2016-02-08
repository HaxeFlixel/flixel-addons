package flixel.addons.effects;

import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
using flixel.util.FlxArrayUtil;

/**
 * This creates a trail copying the bitmapData many times.
 * 
 * @author adrianulima
 */
class FlxTrailEffect implements IFlxEffect
{
	public var active:Bool = true;
	public var offset:Point;
	
	/**
	 * The target FlxEffectSprite that to apply the trail.
	 */
	public var target(default, null):FlxEffectSprite;
	
	/**
	 * The amount of trail images to create. 
	 */
	public var length(default, set):Int;
	/**
	 * The alpha value for the first trail.
	 */
	public var alpha:Float;
	/**
	 * Number of frames to wait until next updated.
	 */
	public var frames:Int;
	/**
	 * Whether to cache current pixels bitmapData of the target for every trail position.
	 */
	public var cachePixels(default, set):Bool;
	
	/**
	 * An array containing the 'length' last differences of the target positions.
	 */
	private var _recentPositions:Array<FlxPoint> = [];
	/**
	 * An array containing the 'length' last pixels bitmapData of the target. Only used if cachePixels is enabled.
	 */
	private var _recentPixels:Array<BitmapData> = [];
	/**
	 * Current number of frames passed.
	 */
	private var _currentFrames:Int = 0;
	/**
	 * The actual Flash BitmapData object representing the current effect state.
	 */
	private var _pixels:BitmapData;
	
	/**
	 * Creates a trail effect.
	 * 
	 * @param	Length			The amount of trail images to create. 
	 * @param	Alpha			The alpha value for the first trailsprite.
	 * @param	Frames			How many frames wait until next updated.
	 * @param	CachePixels		Whether to cache current pixels bitmapData of the target for every trail position. Disable if target never update graphics.
	 */
	public function new(Target:FlxEffectSprite, Length:Int = 10, Alpha:Float = 0.5, Frames:Int = 2, CachePixels:Bool = true) 
	{
		target = Target;
		length = FlxMath.maxInt(1, Length);
		frames = Frames;
		alpha = Alpha;
		cachePixels = CachePixels;
		
		offset = new Point();
	}
	
	public function destroy():Void 
	{
		offset = null;
		
		disposeCachedPixels();
		_recentPixels = null;
		_recentPositions = FlxDestroyUtil.putArray(_recentPositions);
		
		_pixels = FlxDestroyUtil.dispose(_pixels);
	}
	
	public function update(elapsed:Float):Void 
	{
		_currentFrames++;
		
		if (_currentFrames >= frames)
		{
			var p:FlxPoint = null;
			if (_recentPositions.length >= length)
			{
				p = _recentPositions.shift();
			}
			else
			{
				p = FlxPoint.get();
			}
			p.set(target.x, target.y);
			_recentPositions.push(p);
			
			if (cachePixels)
			{
				if (_recentPixels.length >= length)
				{
					FlxDestroyUtil.dispose(_recentPixels.shift());
				}
				_recentPixels.push(target.pixels.clone());
			}
			
			_currentFrames = 0;
		}
	}
	
	public function apply(bitmapData:BitmapData):BitmapData 
	{
		if (_recentPositions.length >= 1)
		{
			var minX:Float = 0;
			var maxX:Float = 0;
			var minY:Float = 0;
			var maxY:Float = 0;
			
			var ww:Int = bitmapData.width;
			var hh:Int = bitmapData.height;
			
			for (i in 0..._recentPositions.length) 
			{
				if (cachePixels)
				{
					ww = _recentPixels[i].width;
					hh = _recentPixels[i].height;
				}
				
				minX = Math.min(_recentPositions[i].x -_recentPositions.last().x, Math.min(minX, 0));
				minY = Math.min(_recentPositions[i].y -_recentPositions.last().y, Math.min(minY, 0));
				maxX = Math.max(_recentPositions[i].x -_recentPositions.last().x + ww, Math.max(maxX, 0));
				maxY = Math.max(_recentPositions[i].y -_recentPositions.last().y + hh, Math.max(maxY, 0));
			}
			
			offset.x = minX;
			offset.y = minY;
			
			if (!cachePixels && minX == 0 && minY == 0 && maxX == 0 && maxY == 0)
			{
				return bitmapData;
			}
			
			if (_pixels == null)
			{
				_pixels = new BitmapData(Std.int(maxX - minX), Std.int(maxY - minY), true, FlxColor.TRANSPARENT);
			}
			else
			{
				var w:Int = Std.int(Math.max(_pixels.width, maxX - minX));
				var h:Int = Std.int(Math.max(_pixels.height, maxY - minY));
				if (_pixels.width < w || _pixels.height < h)
				{
					_pixels = new BitmapData(w, h, true, FlxColor.TRANSPARENT);
				}
				else
				{
					_pixels.fillRect(_pixels.rect, FlxColor.TRANSPARENT);
				}
			}
			
			var alphaDiff:Float = alpha / _recentPositions.length;
			var matrix = new Matrix();
			var cTransform = new ColorTransform();
			
			_pixels.lock();
			for (i in 0..._recentPositions.length) 
			{
				cTransform.alphaMultiplier = alphaDiff * i;
				matrix.tx = _recentPositions[i].x -_recentPositions.last().x - offset.x;
				matrix.ty = _recentPositions[i].y -_recentPositions.last().y - offset.y;
				
				if (cachePixels || matrix.tx != 0 || matrix.ty != 0)
				{
					if (cachePixels && _recentPixels.length > i)
					{
						_pixels.draw(_recentPixels[i], matrix, cTransform);
					}
					else
					{
						_pixels.draw(bitmapData, matrix, cTransform);
					}
				}
			}
			
			matrix.tx = -offset.x;
			matrix.ty = -offset.y;
			
			_pixels.draw(bitmapData, matrix);
			_pixels.unlock();
			
			return _pixels.clone();
		}
		
		return bitmapData;
	}
	
	private function disposeCachedPixels() 
	{
		while(_recentPixels.length > 0) 
		{
			FlxDestroyUtil.dispose(_recentPixels.shift());
		}
	}
	
	public function set_length(Value:Int):Int 
	{
		Value = FlxMath.maxInt(1, Value);
		while (Value < _recentPositions.length)
		{
			_recentPositions.shift();
			if (_recentPixels.length > _recentPositions.length)
			{
				_recentPixels.shift();
			}
		}
		
		return length = Value;
	}
	
	public function set_cachePixels(Value:Bool):Bool 
	{
		if (!Value)
		{
			disposeCachedPixels();
		}
		return cachePixels = Value;
	}
}