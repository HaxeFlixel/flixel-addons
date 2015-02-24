package flixel.addons.effects;

import flixel.FlxSprite;
import flixel.system.layer.frames.FlxFrame;

/**
 * Class for creating filled outline around FlxSprite.
 *
 * @author red__hara 
 */
class BadOutline extends FlxSprite
{
	/**
	 * FlxSprite to draw outline around.
	 */
	public var target:FlxSprite;
	/**
	 * Color of outline.
	 */
	public var outlineColor:Int;
	/**
	 * Used for checking frame update.
	 */
	public var lastFrame:FlxFrame;
	/**
	 * Creates a BadOutline around specified sprite with specified color.
	 * 
	 * @param	Target	The FlxSprite to draw outline around
	 * @param	Color	Color of outline.
	 */
	public function new(Target:FlxSprite, ?Color:Int=0xffffffff)
	{
		super();
		target = Target;
		outlineColor = Color;
		makeGraphic(target.frameWidth + 2, target.frameHeight + 2, 0);
		updateFrame();
		allowCollisions = 0;
	}

	/**
	 * Main update method.
	 */

	override public function update():Void
	{
		x = target.x;
		y = target.y;
		offset.x = target.offset.x + 1;
		offset.y = target.offset.y + 1;
		scrollFactor.x = target.scrollFactor.x;

		if (lastFrame != target.frame)
		{
			updateFrame();
		}
	}

	/**
	 * Updates outline.
	 */

	private function updateFrame():Void
	{
		lastFrame = target.frame;

		var i:Int = 0;
		var j:Int = 0;

		cachedGraphics.bitmap.lock();

		while (i < frameWidth)
		{
			j = 0;
			while (j < frameHeight) 
			{
				cachedGraphics.bitmap.setPixel32(i, j, 0);
				j++;
			}
			i++;
		}

		i = 0;
		j = 0;
		while (i < target.frame.getBitmap().width)
		{
			j = 0;
			while (j < target.frame.getBitmap().height)
			{
				if (target.frame.getBitmap().getPixel32(i, j) & 0xff000000 != 0)
				{
					surround(i + 1, j + 1);
				}
				j++;
			}
			i++;
		}

		cachedGraphics.bitmap.unlock();
		updateFrameData();
	}

	/**
	 * Surrounds selected pixel with outline color.
	 */

	private function surround(I:Int, J:Int):Void
	{
		for (i in I-1...I+2)
		{
			for (j in J-1...J+2)
			{
				cachedGraphics.bitmap.setPixel32(i, j, outlineColor);
			}
		}
	}
}
