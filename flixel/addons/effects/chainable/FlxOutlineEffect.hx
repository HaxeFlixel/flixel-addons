package flixel.addons.effects.chainable;

import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * This creates an outline around the bitmapData. This is a modified version of FlxOutline by red__hara, with some code get from FlxText's borders.
 *
 * @author red__hara
 * @author adrianulima
 */
class FlxOutlineEffect implements IFlxEffect
{
	public var active:Bool = true;
	public var offset(default, null):FlxPoint = FlxPoint.get();

	/**
	 * Set this flag to true to force the effect to update during the apply() call.
	 * This effect is too heavy, and must be called just when the main shape of sprite changes.
	 */
	public var dirty:Bool = true;

	/**
	 * Which mode we're using for the effect
	 * @since 2.1.0
	 */
	public var mode:FlxOutlineMode;

	/**
	 * Color of the outline.
	 */
	public var color:FlxColor;

	/**
	 * Stroke thickness in pixels of outline.
	 */
	public var thickness:Int;

	/**
	 * Set alpha sensitivity to a number between 0 and 1.
	 */
	public var threshold:Int;

	/**
	 * How many iterations do use when drawing the outline. 0: only 1 iteration, 1: one iteration for every pixel in thickness
	 * A value of 1 will have the best quality for large border sizes, but might reduce performance.
	 * NOTE: If the thickness is 1, quality of 0 or 1 will have the exact same effect (and performance).
	 * @since 2.1.0
	 */
	public var quality:Float;

	/**
	 * The actual Flash BitmapData object representing the current effect state.
	 */
	var _pixels:BitmapData;

	/**
	 * The actual Flash BitmapData object representing the colored border.
	 */
	var _borderPixels:BitmapData;

	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	var _flashPoint:Point = new Point();

	var _matrix:Matrix = new Matrix();

	/**
	 * Creates an outline around the bitmapData with the specified color and thickness. To update, dirty need to be setted as true.
	 *
	 * @param	Mode		Which Mode you would like to use for the effect. FAST = Optimized using only 4 draw calls, NORMAL = Outline on all 8 sides, PIXEL_BY_PIXEL = Surround every pixel (can affect performance).
	 * @param	Color		Color of the outline.
	 * @param	Thickness	Outline thickness in pixels.
	 * @param	Quality 	Outline quality - # of iterations to use when drawing. 0:just 1, 1:equal number to Thickness. Not used with PIXEL_BY_PIXEL mode.
	 * @param	Threshold	Alpha sensitivity, only used with PIXEL_BY_PIXEL mode.
	 */
	public function new(?Mode:FlxOutlineMode, Color:FlxColor = FlxColor.WHITE, Thickness:Int = 1, Threshold:Int = 0, Quality:Float = 1)
	{
		mode = (Mode == null) ? FAST : Mode;
		color = Color;
		thickness = Thickness;
		threshold = Threshold;
		quality = Quality;
	}

	public function destroy():Void
	{
		_pixels = FlxDestroyUtil.dispose(_pixels);
		_borderPixels = FlxDestroyUtil.dispose(_borderPixels);

		_flashPoint = null;
		_matrix = null;
		offset = FlxDestroyUtil.put(offset);
	}

	public function update(elapsed:Float):Void {}

	public function apply(bitmapData:BitmapData):BitmapData
	{
		if (dirty)
		{
			var brush:Int = (thickness * 2);

			if (_pixels == null || _pixels.width < bitmapData.width + brush || _pixels.height < bitmapData.height + brush)
			{
				FlxDestroyUtil.dispose(_pixels);
				_pixels = new BitmapData(bitmapData.width + brush, bitmapData.height + brush, true, color);
			}
			else
			{
				_pixels.fillRect(_pixels.rect, color);
			}

			if (mode == PIXEL_BY_PIXEL)
			{
				drawPixelByPixel(bitmapData);
			}
			else
			{
				if (_borderPixels == null || _borderPixels.width < bitmapData.width || _borderPixels.height < bitmapData.height)
				{
					FlxDestroyUtil.dispose(_borderPixels);
					_borderPixels = new BitmapData(bitmapData.width, bitmapData.height, true, FlxColor.TRANSPARENT);
				}
				else
				{
					_borderPixels.fillRect(_borderPixels.rect, FlxColor.TRANSPARENT);
				}

				_flashPoint.setTo(0, 0);
				_borderPixels.copyPixels(_pixels, _pixels.rect, _flashPoint, bitmapData, null, true);
				_pixels.fillRect(_pixels.rect, FlxColor.TRANSPARENT);

				_matrix.identity();
				_matrix.translate(thickness, thickness);

				var iterations:Int = Std.int(Math.max(1, thickness * quality));
				switch (mode)
				{
					case NORMAL:
						drawNormal(iterations);

					case FAST:
						drawFast(iterations);

					case PIXEL_BY_PIXEL:
				}
			}

			dirty = false;
		}

		if (_pixels != null)
		{
			offset.set(-thickness, -thickness);

			_flashPoint.setTo(thickness, thickness);
			_pixels.copyPixels(bitmapData, bitmapData.rect, _flashPoint, null, null, true);

			FlxDestroyUtil.dispose(bitmapData);
			return _pixels.clone();
		}

		return bitmapData;
	}

	function drawPixelByPixel(bitmapData:BitmapData):Void
	{
		_pixels.fillRect(_pixels.rect, FlxColor.TRANSPARENT);

		for (y in 0...bitmapData.height)
		{
			for (x in 0...bitmapData.width)
			{
				var c:FlxColor = bitmapData.getPixel32(x, y);
				if (c.alpha > threshold)
				{
					surroundPixel(x, y, thickness * 2);
				}
			}
		}
	}

	function drawNormal(iterations:Int):Void
	{
		var delta:Float = thickness / iterations;
		var curDelta:Float = delta;
		for (i in 0...iterations)
		{
			drawBorder(-curDelta, -curDelta);
			drawBorder(curDelta, 0);
			drawBorder(curDelta, 0);
			drawBorder(0, curDelta);
			drawBorder(0, curDelta);
			drawBorder(-curDelta, 0);
			drawBorder(-curDelta, 0);
			drawBorder(0, -curDelta);

			_matrix.translate(curDelta, 0);
			curDelta += delta;
		}
	}

	function drawFast(iterations:Int):Void
	{
		var delta:Float = thickness / iterations;
		var curDelta:Float = delta;
		for (i in 0...iterations)
		{
			drawBorder(-curDelta, -curDelta);
			drawBorder(curDelta * 2, 0);
			drawBorder(0, curDelta * 2);
			drawBorder(-curDelta * 2, 0);

			_matrix.translate(curDelta, -curDelta);
			curDelta += delta;
		}
	}

	inline function drawBorder(x:Float, y:Float):Void
	{
		_matrix.translate(x, y);
		_pixels.draw(_borderPixels, _matrix);
	}

	function surroundPixel(x:Int, y:Int, brush:Float):BitmapData
	{
		_pixels.fillRect(new Rectangle(x, y, brush, brush), color);
		return _pixels;
	}
}

/** @since 2.1.0 */
enum FlxOutlineMode
{
	FAST;
	NORMAL;
	PIXEL_BY_PIXEL;
}
