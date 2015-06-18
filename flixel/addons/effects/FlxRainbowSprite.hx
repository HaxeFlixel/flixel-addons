package flixel.addons.effects;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

/**
 * This is a FlxSprite that copies a target FlxSprite and creates a color-cycling effect, using the target's graphic as a mask.
 * Usage: Create a new FlxSprite, as normal, and position it where you want. Create a new FlxRainbowSprite and pass it your target,
 * and add it to the state. 
 * @author Tim Hely / tims-world.com
 */
class FlxRainbowSprite extends FlxSprite
{
	/*
	 * The target FlxSprite that is used as the mask
	 */
	public var target(default, null):FlxSprite;
	
	/*
	 * How fast the hue should change each tick.
	 */
	public var changeSpeed:Float = 5;
	
	/*
	 * The current hue of the effect
	 */
	private var hue:Int = 0;
	
	/*
	 * A dummy sprite for the mask to be applied from
	 */
	private var swatch:BitmapData;
	
	/* 
	 * Used to adjust the hue using changeSpeed
	 */
	private var time:Float = 0;
	
	/**
	 * Creates a new FlxRainbowSprite
	 * @param	Target
	 * @param	StartHue
	 * @param	ChangeSpeed
	 */
	public function new(Target:FlxSprite, StartHue:Int = 0, ChangeSpeed:Float = 5) 
	{
		super();
		target = Target;
		changeSpeed = ChangeSpeed;
		hue = Std.int(FlxMath.bound(StartHue, 0, 360));
		init();
	}
	
	private function init():Void
	{
		var oldGraphic:FlxGraphic = graphic;
		target.drawFrame(true);
		setPosition(target.x, target.y);
		makeGraphic(Std.int(target.frameWidth), Std.int(target.frameHeight), FlxColor.TRANSPARENT, true);
		FlxG.bitmap.removeIfNoUse(oldGraphic);
		swatch = new BitmapData(Std.int(target.frameWidth), Std.int(target.frameHeight), false, FlxColor.fromHSB(hue, 1, 1));
		applyColor();
	}
	
	private function applyColor():Void
	{
		pixels.lock();
		pixels.fillRect(pixels.rect, FlxColor.TRANSPARENT);
		swatch.lock();
		swatch.fillRect(swatch.rect, FlxColor.fromHSB(hue, 1, 1));
		pixels.copyPixels(swatch, swatch.rect, _flashPointZero, target.pixels, _flashPointZero, true);		
		pixels.unlock();
		swatch.unlock();
		dirty = true;
	}
	
	override public function draw():Void 
	{
		applyColor();
		super.draw();
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		time += changeSpeed;
		hue=Std.int(time);
		if (hue > 360)
		{
			hue = 0;
			time-= 360;
		}
	}
	
	
}
