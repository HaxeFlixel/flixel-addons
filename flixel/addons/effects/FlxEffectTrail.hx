package flixel.addons.effects;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;

/**
 * This creates a trail copying the bitmapData many times.
 * 
 * @author adrianulima
 */
class FlxEffectTrail implements IFlxEffect
{
	public var active:Bool = true;
	public var offsetDraw:Point;
	
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
	 * An array containing the 'length' last differences of positions passed in setPos()
	 */
	private var _recentPositions:Array<FlxPoint> = [];
	/**
	 * Current number of frames passed.
	 */
	private var _currentFrames:Int = 0;
	/**
	 * The actual Flash BitmapData object representing the current effect state.
	 */
	private var _pixels:BitmapData;
	
	/**
	 * Creates a trail effect. You need to call setPos() every frame to update the trail position.
	 * 
	 * @param	Length		The amount of trail images to create. 
	 * @param	Alpha		The alpha value for the first trailsprite.
	 * @param	Frames		How many frames wait until next updated.
	 */
	public function new(Length:Int = 10, Alpha:Float = 0.5, Frames:Int = 2) 
	{
		length = FlxMath.maxInt(1, Length);
		frames = Frames;
		alpha = Alpha;
		
		offsetDraw = new Point();
	}
	
	public function destroy():Void 
	{
		offsetDraw = null;
		
		_recentPositions = FlxDestroyUtil.putArray(_recentPositions);
		
		_pixels = FlxDestroyUtil.dispose(_pixels);
	}
	
	public function update(elapsed:Float):Void 
	{
		_currentFrames++;
	}
	
	public function apply(bitmapData:BitmapData):BitmapData 
	{
		if (_recentPositions.length >= 1)
		{
			var minX:Float = 0;
			var maxX:Float = 0;
			var minY:Float = 0;
			var maxY:Float = 0;
			
			for (i in 0..._recentPositions.length) 
			{
				minX = Math.min(_recentPositions[i].x - _recentPositions[_recentPositions.length - 1].x, Math.min(minX, 0));
				minY = Math.min(_recentPositions[i].y - _recentPositions[_recentPositions.length - 1].y, Math.min(minY, 0));
				maxX = Math.max(_recentPositions[i].x - _recentPositions[_recentPositions.length - 1].x, Math.max(maxX, 0));
				maxY = Math.max(_recentPositions[i].y - _recentPositions[_recentPositions.length - 1].y, Math.max(maxY, 0));
			}
			
			offsetDraw.x = minX;
			offsetDraw.y = minY;
			
			if (minX == 0 && minY == 0 && maxX == 0 && maxY == 0)
			{
				return bitmapData;
			}
			
			if (_pixels == null)
			{
				_pixels = new BitmapData(Std.int(maxX + bitmapData.width - minX), Std.int(maxY + bitmapData.height - minY), true, FlxColor.TRANSPARENT);
			}
			else
			{
				var w:Int = Std.int(Math.max(_pixels.width, maxX + bitmapData.width - minX));
				var h:Int = Std.int(Math.max(_pixels.height, maxY + bitmapData.height - minY));
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
				matrix.tx = _recentPositions[i].x - _recentPositions[_recentPositions.length - 1].x - offsetDraw.x;
				matrix.ty = _recentPositions[i].y - _recentPositions[_recentPositions.length - 1].y - offsetDraw.y;
				
				if (matrix.tx != 0 || matrix.ty != 0)
				{
					_pixels.draw(bitmapData, matrix, cTransform);
				}
			}
			
			matrix.tx = -offsetDraw.x;
			matrix.ty = -offsetDraw.y;
			
			_pixels.draw(bitmapData, matrix);
			_pixels.unlock();
			
			return _pixels;
		}
		
		return bitmapData;
	}
	
	/**
	 * This saves the last position of the target to draw trail images. Must be called every frame.
	 * 
	 * @param	x	The last X position of the trail target.
	 * @param	y	The last Y position of the trail target.
	 */
	public function setPos(x:Float, y:Float)
	{
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
			
			p.set(x, y);
			_recentPositions.push(p);
			
			_currentFrames = 0;
		}
	}
	
	public function set_length(Value:Int):Int 
	{
		Value = FlxMath.maxInt(1, Value);
		while (Value < _recentPositions.length)
		{
			_recentPositions.shift();
		}
		
		return length = Value;
	}
}