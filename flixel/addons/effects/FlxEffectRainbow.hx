package flixel.addons.effects;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * This is a modified version of FlxRainbowSprite by Tim Hely
 * 
 * @author Tim Hely / tims-world.com
 * @author adrianulima
 */
class FlxEffectRainbow implements IFlxEffect
{
	public var active:Bool = true;
	public var offsetDraw:Point;
	
	/**
	 * How fast the hue should change each tick.
	 */
	public var speed:Float = 5;
	
	/**
	 * The current hue of the effect
	 */
	private var hue:Int = 0;
	
	/**
	 * Used to adjust the hue using speed
	 */
	private var time:Float = 0;
	
	/**
	 * Internal, reused frequently during drawing and animating. Always contains (0,0).
	 */
	private var _flashPointZero:Point;
	
	public function new(StartHue:Int = 0, Speed:Float = 5) 
	{
		speed = Speed;
		time = hue = Std.int(FlxMath.bound(StartHue, 0, 360));
		
		offsetDraw = new Point();
		_flashPointZero = new Point();
	}
	
	public function destroy():Void 
	{
		offsetDraw = null;
		_flashPointZero = null;
	}
	
	public function update(elapsed:Float):Void 
	{
		time += speed;
		hue = Std.int(time);
		if (hue > 360)
		{
			hue = 0;
			time -= 360;
		}
	}
	
	public function apply(bitmapData:BitmapData):BitmapData 
	{
		var swatch = new BitmapData(bitmapData.width, bitmapData.height, false, FlxColor.fromHSB(hue, 1, 1));
		
		bitmapData.copyPixels(swatch, swatch.rect, _flashPointZero, bitmapData, null, true);
		
		return bitmapData;
	}
}