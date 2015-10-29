package flixel.addons.effects;
import flixel.util.FlxAxes;
import openfl.display.BitmapData;
import openfl.geom.Point;

/**
 * This will shake the bitmapData.
 * 
 * @author adrianulima
 */
class FlxEffectShake implements IFlxEffect
{
	public var active:Bool = true;
	public var offsetDraw:Point;
	
	/**
	 * Value in pixels representing the maximum distance that the bitmapData can move while shaking.
	 */
	public var intensity:Float = 0;
	/**
	 * A function you want to run when the shake finishes.
	 */
	public var onComplete:Void->Void;
	/**
	 * On what axes to shake.
	 */
	public var axes:FlxAxes = XY;
	
	/**
	 * The length in seconds that the shaking effect should last.
	 */
	private var _duration:Float = 0;
	/**
	 * Current time of the effect.
	 */
	private var _time:Float = 0;
	
	/**
	 * A shake effect.
	 * 
	 * @param	Intensity	Value in pixels representing the maximum distance that the bitmapData can move while shaking.
	 * @param	Duration	The length in seconds that the shaking effect should last.
	 * @param	OnComplete	Optional completion callback function.
	 * @param	Axes		On what axes to shake. Default value is XY / both.
	 */
	public function new(Intensity:Float = 5, Duration:Float = 0.5, ?OnComplete:Void->Void, ?Axes:FlxAxes) 
	{
		reset(Intensity, Duration, OnComplete, Axes);
		
		offsetDraw = new Point();
	}
	
	public function destroy():Void 
	{
		offsetDraw = null;
		onComplete = null;
	}
	
	public function update(elapsed:Float):Void 
	{
		if (_time > 0)
		{
			_time -= elapsed;
			if (_time <= 0)
			{
				offsetDraw.setTo(0, 0);
				if (onComplete != null)
				{
					onComplete();
				}
			}
			else
			{
				if (axes != FlxAxes.Y)
				{
					offsetDraw.x = FlxG.random.float( -intensity, intensity);
				}
				if (axes != FlxAxes.X)
				{
					offsetDraw.y = FlxG.random.float( -intensity, intensity);
				}
			}
		}
	}
	
	public function apply(bitmapData:BitmapData):BitmapData 
	{
		return bitmapData;
	}
	
	/**
	 * Reset and start the effect with the same parameters.
	 * 
	 * @param	Force	Force the effect to reset.
	 */
	public function start(Force:Bool = false):Void
	{
		if (!Force && _time > 0)
		{
			return;
		}
		
		reset(intensity, _duration, onComplete, axes);
	}
	
	/**
	 * Reset the effect, need to set the parameters again. To use the same parameters call method start().
	 * 
	 * @param	Intensity	Value in pixels representing the maximum distance that the bitmapData can move while shaking.
	 * @param	Duration	The length in seconds that the shaking effect should last.
	 * @param	OnComplete	Optional completion callback function.
	 * @param	Axes		On what axes to shake. Default value is XY / both.
	 */
	public function reset(Intensity:Float = 5, Duration:Float = 0.5, ?OnComplete:Void->Void, ?Axes:FlxAxes) 
	{
		if (Axes == null)
			Axes = XY;
		
		intensity = Intensity;
		_duration = Duration;
		_time = Duration;
		onComplete = OnComplete;
		axes = Axes;
	}
}