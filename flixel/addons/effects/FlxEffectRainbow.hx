package flixel.addons.effects;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Point;

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
	 * Set alpha to a number between 0 and 1 to change the opacity of the effect.
	 */
	private var alpha:Float = 1;
	
	/**
	 * A number between 0 and 1, indicating how bright the color should be. 0 is black, 1 is full bright.
	 */
	private var brightness:Float = 1;
	
	/**
	 * Used to adjust the hue using speed
	 */
	private var time:Float = 0;
	
	/**
	 * Internal, reused frequently during drawing and animating. Always contains (0,0).
	 */
	private var _flashPointZero:Point;
	
	/**
	 * Creates a new FlxEffectRainbow, which applies a color-cycling effect, using the target's bitmap as a mask.
	 * 
	 * @param	Alpha		A number between 0 and 1 to change the opacity of the effect.
	 * @param	Brightness	A number between 0 and 1, indicating how bright the color should be.
	 * @param	Speed		How fast the hue should change each tick.
	 * @param	StartHue	The initial hue of the effect.
	 */
	public function new(Alpha:Float = 1, Brightness:Float = 1, Speed:Float = 5, StartHue:Int = 0) 
	{
		alpha = Alpha;
		brightness = Brightness;
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
		var swatch = new BitmapData(bitmapData.width, bitmapData.height, true, FlxColor.fromHSB(hue, 1, brightness, alpha));
		
		bitmapData.copyPixels(swatch, swatch.rect, _flashPointZero, bitmapData, null, true);
		
		return bitmapData;
	}
}