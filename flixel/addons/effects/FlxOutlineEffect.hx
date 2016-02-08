package flixel.addons.effects;

import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * This creates an outline around the bitmapData. This is a modified version of FlxOutline by red__hara
 * 
 * @author red__hara
 * @author adrianulima
 */
class FlxOutlineEffect implements IFlxEffect
{
	public var active:Bool = true;
	public var offset:FlxPoint;
	
	/**
	 * Set this flag to true to force the effect to update during the apply() call.
	 * This effect is too heavy, and must be called just when the main shape of sprite changes.
	 */
	public var dirty:Bool = true;
	/**
	 * Color of the outline.
	 */
	public var color:FlxColor;
	/**
	 * Stroke thickness in pixels of outline.
	 */
	public var thickness:Int;
	/**
	 * Set alpha sensativity to a number between 0 and 1.
	 */
	public var threshold:Int;
	
	/**
	 * The actual Flash BitmapData object representing the current effect state.
	 */
	private var _pixels:BitmapData;
	
	/**
	 * Creates an outline around the bitmapData with the specified color and thickness. To update, dirty need to be setted as true.
	 *
	 * @param Color		Color of the outline.
	 * @param Thickness	Outline thickness in pixels.
	 * @param Threshold	Alpha sensativity.
	 */
	public function new(Color:FlxColor = FlxColor.WHITE, Thickness:Int = 1, Threshold:Int = 0) 
	{
		color = Color;
		thickness = Thickness;
		threshold = Threshold;
	}
	
	public function destroy():Void 
	{
		_pixels = FlxDestroyUtil.dispose(_pixels);
	}
	
	public function update(elapsed:Float):Void {}
	
	public function apply(bitmapData:BitmapData):BitmapData 
	{
		if (dirty)
		{
			var brush = (thickness * 2) + 1;
			
			if (_pixels == null || _pixels.width < bitmapData.width + brush || _pixels.height < bitmapData.height + brush)
			{
				_pixels = new BitmapData(bitmapData.width + brush, bitmapData.height + brush, true, FlxColor.TRANSPARENT);
			}
			else
			{
				_pixels.fillRect(_pixels.rect, FlxColor.TRANSPARENT);
			}
			
			for (y in 0...bitmapData.height)
			{
				for (x in 0...bitmapData.width)
				{
					var c:FlxColor = bitmapData.getPixel32(x, y);
					if (c.alpha > threshold)
					{
						surroundPixel(x, y, brush);
					}
				}
			}
			
			dirty = false;
		}
		
		if (_pixels != null)
		{
			_pixels.copyPixels(bitmapData, bitmapData.rect, new Point(thickness, thickness), null, null, true);
			return _pixels.clone();
		}
		
		return bitmapData;
	}
	
	private function surroundPixel(x:Int, y:Int, brush:Float):BitmapData
	{
		_pixels.fillRect(new Rectangle(x, y, brush, brush), color);
		return _pixels;
	}
}