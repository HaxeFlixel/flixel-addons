package flixel.addons.effects;

import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.geom.Point;

/**
 * This gradually fills the bitmapData with a color.
 * 
 * @author adrianulima
 */
class FlxEffectFade implements IFlxEffect
{
	public var active:Bool = true;
	public var offset:Point;
	
	/**
	 * Color of the fade.
	 */
	private var color:FlxColor = FlxColor.BLACK;
	/**
	 * A function you want to run when the fade finishes.
	 */
	public var onComplete:Void->Void = null;
	
	/**
	 * Set alpha to a number between 0 and 1 to change the opacity of the effect.
	 */
	private var _alpha:Float = 0;
	/**
	 * How long in seconds it takes for the fade to finish.
	 */
	private var _duration:Float = 0;
	/**
	 * IN fades from a color, OUT fades to it.
	 */
	private var _fadeMode:FlxFadeMode;
	/**
	 * The actual Flash BitmapData object representing the current effect state.
	 */
	private var _pixels:BitmapData;
	
	/**
	 * The bitmapData is gradually filled with this color.
	 * 
	 * @param	Color		The color you want to use.
	 * @param	Duration	How long in seconds it takes for the fade to finish.
	 * @param   FadeMode	IN fades from a color, OUT fades to it.
	 * @param	OnComplete	Optional completion callback function.
	 */
	public function new(Color:FlxColor = FlxColor.BLACK, Duration:Float = 1, ?FadeMode:FlxFadeMode, ?OnComplete:Void->Void) 
	{
		reset(Color, Duration, FadeMode, OnComplete);
	}
	
	public function destroy():Void 
	{
		onComplete = null;
		
		_pixels = FlxDestroyUtil.dispose(_pixels);
	}
	
	public function update(elapsed:Float):Void 
	{
		if (_alpha > 0.0 && _alpha < 1.0)
		{
			if (_fadeMode == IN)
			{
				_alpha -= elapsed /_duration;
				if (_alpha <= 0.0)
				{
					_alpha = 0.0;
					if (onComplete != null)
					{
						onComplete();
					}
				}
			}
			else
			{
				_alpha += elapsed / _duration;
				if (_alpha >= 1.0)
				{
					_alpha = 1.0;
					if (onComplete != null)
					{
						onComplete();
					}
				}
			}
		}
	}
	
	public function apply(bitmapData:BitmapData):BitmapData 
	{
		if (_alpha > 0.0)
		{
			color.alpha = Std.int(_alpha * 255);
			
			if (_pixels == null || _pixels.width < bitmapData.width || _pixels.height < bitmapData.height)
			{
				_pixels = new BitmapData(bitmapData.width, bitmapData.height, true, color);
			}
			else
			{
				_pixels.fillRect(bitmapData.rect, color);
			}
			
			bitmapData.copyPixels(_pixels, bitmapData.rect, new Point(), bitmapData, null, true);
		}
		
		return bitmapData;
	}
	
	/**
	 * Reset and start the effect with the same parameters.
	 * 
	 * @param	Force	Force the effect to reset.
	 */
	public function start(Force:Bool = false):Void
	{
		if (!Force && _alpha > 0.0 && _alpha < 1.0)
		{
			return;
		}
		
		reset(color, _duration, _fadeMode, onComplete);
	}
	
	/**
	 * Reset the effect, need to set the parameters again. To use the same parameters call method start().
	 * 
	 * @param	Color		The color you want to use.
	 * @param	Duration	How long it takes for the fade to finish.
	 * @param   FadeMode	IN fades from a color, OUT fades to it.
	 * @param	OnComplete	Optional completion callback function.
	 */
	public function reset(Color:FlxColor = FlxColor.BLACK, Duration:Float = 1, ?FadeMode:FlxFadeMode, ?OnComplete:Void->Void) 
	{
		color = Color;
		_duration = Math.max(Duration, 0.000001);
		_fadeMode = (FadeMode != null) ? FadeMode : OUT;
		onComplete = OnComplete;
		
		_alpha = (FadeMode == IN) ? 0.999999 : 0.000001;
	}
}

enum FlxFadeMode
{
	IN;
	OUT;
}