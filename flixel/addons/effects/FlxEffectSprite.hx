package flixel.addons.effects;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.geom.Point;

/**
 * Use this class to chain bitmap effects to your target FlxSprite frame.
 * @author Adriano Lima
 */
class FlxEffectSprite extends FlxSprite
{
	/**
	 * Enables and disables the effects update loop.
	 */
	public var effectsEnabled:Bool = true;
	
	/**
	 * The target FlxSprite that is used to apply effects.
	 */
	public var target(default, null):FlxSprite;
	
	/**
	 * Effects applied to frames
	 */
	public var effects:Array<IFlxEffect>;
	
	/**
	 * Use to offset the drawing position of the bitmap.
	 */
	private var _effectOffset:FlxPoint;
	
	/**
	 * Creates a FlxEffectSprite at a specified position with a specified one-frame graphic. 
	 * If none is provided, a 16x16 image of the HaxeFlixel logo is used.
	 * 
	 * @param	X				The initial X position of the sprite.
	 * @param	Y				The initial Y position of the sprite.
	 * @param	SimpleGraphic	The graphic you want to display (OPTIONAL - for simple stuff only, do NOT use for animated images!).
	 */
	public function new(Target:FlxSprite, ?Effects:Array<IFlxEffect> = null)
	{
		super();
		
		target = Target;
		this.effects = (Effects != null) ? Effects : [];
		
		_effectOffset = FlxPoint.get();
	}
	
	/**
	 * WARNING: This will remove this sprite entirely. Use kill() if you want to disable it temporarily only and reset() it later to revive it.
	 * Used to clean up memory.
	 */
	override public function destroy():Void
	{
		for (effect in effects) 
		{
			effect.destroy();
		}
		
		effects = null;
		_effectOffset = FlxDestroyUtil.put(_point);
		
		super.destroy();
	}
	
	override public function getScreenPosition(?point:FlxPoint, ?Camera:FlxCamera):FlxPoint 
	{
		return super.getScreenPosition(point, Camera).addPoint(_effectOffset);
	}
	
	/**
	 * Core update loop
	 */
	override public function update(elapsed:Float):Void
	{
		if (effectsEnabled)
		{
			#if !FLX_RENDER_BLIT
			target.drawFrame(true);
			#end
			
			FlxDestroyUtil.dispose(pixels);
			
			pixels = target.framePixels.clone();
			_effectOffset.set(0, 0);
			
			if (pixels == null)
				return;
			
			pixels.lock();
			for (effect in effects) 
			{
				if (effect.active)
				{
					effect.update(elapsed);
					pixels = effect.apply(pixels);
					if (effect.offset != null)
					{
						_effectOffset.add(effect.offset.x, effect.offset.y);
					}
				}
			}
			pixels.unlock();
			
			_flashRect = pixels.rect;
		}
		
		super.update(elapsed);
	}
}