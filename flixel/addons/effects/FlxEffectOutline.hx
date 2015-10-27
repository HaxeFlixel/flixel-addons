package flixel.addons.effects;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * This creates an outline around the bitmapData.
 * 
 * @author red__hara
 * @author adrianulima
 */
class FlxEffectOutline implements IFlxEffect
{
	public var active:Bool = true;
	public var offsetDraw:Point;
	
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
	
	private var _pixels:BitmapData;
	
	/**
	 * Creates an outline around the bitmapData with the specified color and thickness.
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
		
		offsetDraw = new Point();
	}
	
	public function destroy():Void 
	{
		offsetDraw = null;
		
		_pixels = FlxDestroyUtil.dispose(_pixels);
	}
	
	public function update(elapsed:Float):Void 
	{
	}
	
	public function apply(bitmapData:BitmapData):BitmapData 
	{
		if (dirty)
		{
			var brush = (thickness * 2) + 1;
			_pixels = new BitmapData(bitmapData.width + brush, bitmapData.height + brush, true, FlxColor.TRANSPARENT);
			
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
			
			return _pixels;
		}
		
		return bitmapData;
	}
	
	private function surroundPixel(x:Int, y:Int, brush:Float):BitmapData
	{
		_pixels.fillRect(new Rectangle(x, y, brush, brush), color);
		return _pixels;
	}
}