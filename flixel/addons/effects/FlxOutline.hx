package flixel.addons.effects;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

/**
 * Creates a filled outline around a FlxSprite.
 *
 * @author red__hara
 */
class FlxOutline extends FlxSprite
{
	/**
	 * FlxSprite to draw an outline around.
	 */
	public var target(default, null):FlxSprite;
	
	/**
	 * Color of the outline.
	 */
	public var outlineColor(default, set):FlxColor;
	
	/**
	 * Used for checking frame update.
	 */
	private var lastFrame:FlxFrame;
	
	/**
	 * Creates an outline around a specified sprite with the specified color.
	 *
	 * @param Target The FlxSprite to draw an outline around
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
	
	override public function update(elapsed:Float):Void
	{
		if (lastFrame != target.frame)
		{
			updateOutline();
		}
		super.update(elapsed);
	}
	
	private function updateOutline():Void
	{
		lastFrame = target.frame;
		
		var targetPixels:BitmapData = target.getFlxFrameBitmapData();
		graphic.bitmap.lock();
		graphic.bitmap.fillRect(graphic.bitmap.rect, FlxColor.TRANSPARENT);
		
		for (x in 0...target.frameWidth)
		{
			for (y in 0...target.frameHeight)
			{
				var pixel:FlxColor = targetPixels.getPixel32(x, y);
				if (pixel.alphaFloat > 0)
				{
					surroundPixel(x + 1, y + 1);
				}
			}
		}
		
		_flashPoint.setTo(1, 1);
		target.frame.paint(graphic.bitmap, _flashPoint, true);
		graphic.bitmap.unlock();
		dirty = true;
	}
	
	private function surroundPixel(targetX:Int, targetY:Int):Void
	{
		for (x in (targetX - 1)...(targetX + 2))
		{
			for (y in (targetY - 1)...(targetY + 2))
			{
				graphic.bitmap.setPixel32(x, y, outlineColor);
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
				updateOutline();
			}
		}
		
		return value;
	}
}