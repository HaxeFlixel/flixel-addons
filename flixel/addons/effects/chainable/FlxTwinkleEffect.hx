package flixel.addons.effects.chainable;

import flixel.addons.effects.chainable.IFlxEffect;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.geom.Point;

/**
 * A twinkle effect. Handy for showing invincible state.
 * Mainly comes from FlxRainbowEffect.
 * 
 * @author Wu Yu
 */
class FlxTwinkleEffect implements IFlxEffect
{
	public var active:Bool = true;
	public var offset(default, null):FlxPoint;
	
	public var color:FlxColor;
	
	/**
	 * The interval of show/hide the color.
	 */
	public var interval:Float;
	
	private var _isShowing:Bool = true;
	/**
	 * Used to remember the time to show/hide
	 */
	private var _time:Float = 0;
	/**
	 * Internal, reused frequently during drawing and animating. Always contains (0,0).
	 */
	private var _flashPoint:Point = new Point();
	/**
	 * The actual Flash BitmapData object representing the current effect state.
	 */
	private var _pixels:BitmapData;
	
	public function new(Color:FlxColor = FlxColor.WHITE, Interval:Float = 0.05)
	{
		color = Color;
		interval = Interval;
	}
	
	public function destroy():Void 
	{
		_flashPoint = null;
		
		_pixels = FlxDestroyUtil.dispose(_pixels);
	}
	
	public function update(elapsed:Float):Void 
	{
		_time += elapsed;
		if (_time >= interval) {
			_time = 0;
			_isShowing = !_isShowing;
		}
	}
	
	public function apply(bitmapData:BitmapData):BitmapData 
	{
		var appliedColor:FlxColor = _isShowing ? color : FlxColor.TRANSPARENT;
		
		if (_pixels == null || _pixels.width < bitmapData.width || _pixels.height < bitmapData.height)
		{
			FlxDestroyUtil.dispose(_pixels);
			_pixels = new BitmapData(bitmapData.width, bitmapData.height, true, appliedColor);
		}
		else
		{
			_pixels.fillRect(_pixels.rect, appliedColor);
		}
		
		bitmapData.copyPixels(_pixels, _pixels.rect, _flashPoint, bitmapData, null, true);
		
		return bitmapData;
	}
}