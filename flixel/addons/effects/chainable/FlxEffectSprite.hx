package flixel.addons.effects.chainable;

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
 * @author adrianulima
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
	 * Whether to call target's FlxSprite#updateAnimation() every FlxEffectSprite#update(). Set this false if the target is also added to state.
	 */
	public var updateTargetAnimation:Bool = true;

	/**
	 * Effects applied to frames
	 */
	public var effects:Array<IFlxEffect>;

	/**
	 * Use to offset the drawing position of the bitmap.
	 */
	var _effectOffset:FlxPoint;

	/**
	 * Creates a FlxEffectSprite for a specific FlxSprite.
	 *
	 * @param	Target		The target FlxSprite that is used to apply effects.
	 * @param	Effects		Effects to be applied to frames.
	 */
	public function new(Target:FlxSprite, ?Effects:Array<IFlxEffect>)
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
		effects = FlxDestroyUtil.destroyArray(effects);
		_effectOffset = FlxDestroyUtil.put(_effectOffset);
		target = null;

		super.destroy();
	}

	/**
	 * Call this function to figure out the on-screen position of the object.
	 *
	 * @param	point		Takes a FlxPoint object and assigns the post-scrolled X and Y values of this object to it.
	 * @param	Camera		Specify which game camera you want.  If null getScreenPosition() will just grab the first global camera.
	 * @return	The Point you passed in, or a new Point if you didn't pass one, containing the screen X and Y position of this object.
	 */
	override public function getScreenPosition(?point:FlxPoint, ?Camera:FlxCamera):FlxPoint
	{
		return super.getScreenPosition(point, Camera).addPoint(_effectOffset);
	}

	override public function draw():Void
	{
		if (target.dirty)
		{
			target.drawFrame();
		}

		if (target.framePixels == null)
			return super.draw();

		if (pixels != null && pixels.width == target.framePixels.width && pixels.height == target.framePixels.height)
		{
			pixels.fillRect(pixels.rect, FlxColor.TRANSPARENT);
			pixels.draw(target.framePixels);
		}
		else
		{
			FlxDestroyUtil.dispose(pixels);
			pixels = target.framePixels.clone();
		}

		_effectOffset.set(0, 0);

		if (effectsEnabled)
		{
			pixels.lock();
			for (effect in effects)
			{
				if (effect.active)
				{
					pixels = effect.apply(pixels);
					if (effect.offset != null)
					{
						_effectOffset.addPoint(effect.offset);
					}
				}
			}
			pixels.unlock();
			_flashRect = pixels.rect;
		}

		super.draw();
	}

	/**
	 * Core update loop, and updates each active effect.
	 */
	override public function update(elapsed:Float):Void
	{
		if (updateTargetAnimation && target.animation.numFrames > 1)
		{
			target.updateAnimation(elapsed);
		}

		if (effectsEnabled)
		{
			for (effect in effects)
			{
				if (effect.active)
				{
					effect.update(elapsed);
				}
			}
		}

		super.update(elapsed);
	}
}
