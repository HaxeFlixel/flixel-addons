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
	
	public var thickness(default, set):Int;
	
	/**
	 * Used for checking frame update.
	 */
	private var lastFrame:FlxFrame;
	
	/**
	 * Creates an outline around a specified sprite with the specified color.
	 *
	 * @param Target The FlxSprite to draw an outline around
	 * @param Color Color of the outline
	 * @param Thickness Outline thickness in pixels
	 */
	public function new(Target:FlxSprite, Color:FlxColor = FlxColor.WHITE, Thickness:Int = 1)
	{
		super();
		target = Target;
		outlineColor = Color;
		thickness = Thickness;
		
		x = target.x;
		y = target.y;
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
					surroundPixel(x + thickness, y + thickness);
				}
			}
		}
		
		_flashPoint.setTo(thickness, thickness);
		target.frame.paint(graphic.bitmap, _flashPoint, true);
		graphic.bitmap.unlock();
		dirty = true;
	}
	
	private function surroundPixel(targetX:Int, targetY:Int):Void
	{
		for (x in (targetX - thickness)...(targetX + thickness * 2))
		{
			for (y in (targetY - thickness)...(targetY + thickness * 2))
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
	
	private function set_thickness(value:Int):Int
	{
		if (value != thickness)
		{
			thickness = value;
			makeGraphic(target.frameWidth + thickness * 2,
				target.frameHeight + thickness * 2, 0);
			offset.copyFrom(target.offset).add(thickness, thickness);
			updateOutline();
		}
		
		return value;
	}
}