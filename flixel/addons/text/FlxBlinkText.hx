package flixel.addons.text;
import flixel.FlxG;
import flixel.text.FlxText;

/**
 * Simple FlxText with blinking interval parameter
 * @author Masadow
 */
class FlxBlinkText extends FlxText
{
	
	/**
	 * Blink interval, in seconds
	 */
	public var blinkInterval : Float;
	/**
	 * If true, enable blinking
	 */
	public var blinking : Bool;

	/**
	 * Helper to know if the next draw call should draw something
	 */
	private var _internalBlinking : Bool;
	/**
	 * Helper to know elapsed time since last blinking state changed
	 */
	private var _time : Float;
	
	/**
	 * Creates a new <code>FlxText</code> object at the specified position.
	 * @param	X				The X position of the text.
	 * @param	Y				The Y position of the text.
	 * @param	Width			The width of the text object (height is determined automatically).
	 * @param	Text			The actual text you would like to display initially.
	 * @param	BlinkInterval	The actual blinking speed.
	 * @param	EmbeddedFont	Whether this text field uses embedded fonts or not
	 */
	public function new(X:Float, Y:Float, Width:Int, ?Text:String, BlinkInterval:Float = 1, size:Int = 8, EmbeddedFont:Bool = true)
	{
		super(X, Y, Width, Text, size, EmbeddedFont);
		
		blinkInterval = BlinkInterval;
		_time = 0;
		_internalBlinking = true;
		blinking = true;
	}

	override function update():Void
	{
		super.update();
		if (blinking && visible)
		{
			_time += FlxG.elapsed;
			while (_time > blinkInterval)
			{
				_time -= blinkInterval;
				_internalBlinking = !_internalBlinking;
			}
		}
	}
	
	override public function draw():Void 
	{
		//If blinking is enabled and we are currently in an invisble state, do not draw anything
		if (!blinking || _internalBlinking)
			super.draw();
	}
}