package flixel.addons.effects;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

/**
 * Class for creating filled outline around FlxSprite.
 *
 * @author red__hara
 */
class FlxBadOutline extends FlxSprite
{
	/**
	 * FlxSprite to draw outline around.
	 */
	public var target(default, null):FlxSprite;
	
	/**
	 * Color of outline.
	 */
	public var outlineColor(default, set):FlxColor;
	
	/**
	 * Used for checking frame update.
	 */
	private var lastFrame:FlxFrame;
	
	/**
	 * Creates a BadOutline around specified sprite with specified color.
	 *
	 * @param Target The FlxSprite to draw outline around
	 * @param Color Color of outline.
	 */
	public function new(Target:FlxSprite, Color:FlxColor = FlxColor.WHITE)
	{
		super();
		target = Target;
		makeGraphic(target.frameWidth + 2, target.frameHeight + 2, 0);
		x = target.x;
		y = target.y;
		offset.copyFrom(target.offset).add(1, 1);
		scrollFactor.copyFrom(target.scrollFactor);
		outlineColor = Color;
	}
	
	override public function destroy():Void 
	{
		target = null;
		lastFrame = null;
		super.destroy();
	}
	
	/**
	 * Main update method.
	 */
	override public function update(elapsed:Float):Void
	{
		if (lastFrame != target.frame)
		{
			updateFrame();
		}
		super.update(elapsed);
	}
	
	/**
	 * Updates outline.
	 */
	private function updateFrame():Void
	{
		lastFrame = target.frame;
		var i:Int = 0;
		var j:Int = 0;
		
		var targetPixels:BitmapData = target.getFlxFrameBitmapData();
		graphic.bitmap.lock();
		graphic.bitmap.fillRect(graphic.bitmap.rect, FlxColor.TRANSPARENT);
		
		while (i < target.frameWidth)
		{
			j = 0;
			while (j < target.frameHeight)
			{
				if (targetPixels.getPixel32(i, j) & 0xff000000 != 0)
				{
					surround(i + 1, j + 1);
				}
				j++;
			}
			i++;
		}
		
		_flashPoint.setTo(1, 1);
		target.frame.paint(graphic.bitmap, _flashPoint, true);
		graphic.bitmap.unlock();
		dirty = true;
	}
	
	/**
	 * Surrounds selected pixel with outline color.
	 */
	private function surround(I:Int, J:Int):Void
	{
		for (i in (I - 1)...(I + 2))
		{
			for (j in (J - 1)...(J + 2))
			{
				graphic.bitmap.setPixel32(i, j, outlineColor);
			}
		}
	}
	
	private function set_outlineColor(value:FlxColor):FlxColor
	{
		if (value != outlineColor)
		{
			outlineColor = value;
			if (graphic != null)
			{
				updateFrame();
			}
		}
		
		return value;
	}
}