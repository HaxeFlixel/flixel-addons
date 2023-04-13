package flixel.addons.plugin;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxBasic;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;

// TODO: port "scroll sprite" plugin as well

/**
 * FlxScrollingText
 * -- Part of the Flixel Power Tools set
 * -- Works only FLX_BLIT_RENDER mode for now
 *
 * v1.0 First version released
 *
 * @version 1.0 - May 5th 2011
 * @link http://www.photonstorm.com
 * @author Richard Davey / Photon Storm
 * @co-author Ungar Djordje / ArtBIT (Haxe port)
 */
class FlxScrollingText extends FlxBasic
{
	static var members:Map<FlxSprite, ScrollingTextData> = new Map<FlxSprite, ScrollingTextData>();
	static var zeroPoint:Point = new Point(0, 0);

	/**
	 * Adds an FlxBitmapTextField to the Scrolling Text Manager and returns an FlxSprite which contains the text scroller in it.
	 * The FlxSprite will automatically update itself via this plugin, but can be treated as a normal FlxSprite in all other regards
	 * re: positioning, collision, rotation, etc.
	 *
	 * @param	bitmapText			A pre-prepared FlxBitmapTextField object (see the Test Suite examples for details on how this works)
	 * @param	region				A Rectangle that defines the size of the scrolling FlxSprite. The sprite will be placed at region.x/y and be region.width/height in size.
	 * @param	pixels				The number of pixels to scroll per step. For a smooth (but slow) scroll use low values. Keep the value proportional to the font width, so if the font width is 16 use a value like 1, 2, 4 or 8.
	 * @param	steps				How many steps should pass before the text is next scrolled? Default 0 means every step we scroll. Higher values slow things down.
	 * @param	text				The default text for your scrolling message. Can be changed in real-time via the addText method.
	 * @param	onlyScrollOnscreen	Only update the text scroller when this FlxSprite is visible on-screen? Default true.
	 * @param	loopOnWrap			When the scroller reaches the end of the given "text" should it wrap to the start? Default true. If false it will clear the screen then set itself to not update.
	 *
	 * @return	An FlxSprite of size region.width/height, positioned at region.x/y, that auto-updates its contents while this plugin runs
	 */
	public static function add(bitmapText:FlxBitmapText, region:Rectangle, pixels:Int = 1, steps:Int = 0, text:String = null, onlyScrollOnscreen:Bool = true,
			loopOnWrap:Bool = true):FlxSprite
	{
		var data:ScrollingTextData = new ScrollingTextData();

		//	Sanity checks
		if (pixels <= 0)
		{
			pixels = 1;
		}

		data.bitmapText = bitmapText;

		if ((text == "" || text == null) && (bitmapText.text == "" || bitmapText.text == null))
		{
			bitmapText.text = " ";
		}
		else if (text != "" && text != null)
		{
			bitmapText.text = text;
		}

		bitmapText.drawFrame(true);

		data.shiftRect = new Rectangle(0, 0, region.width, (region.height > bitmapText.frameHeight) ? bitmapText.frameHeight : region.height);
		data.x = 0;

		data.sprite = new FlxSprite(Std.int(region.x),
			Std.int(region.y)).makeGraphic(Std.int(region.width), Std.int(region.height), FlxColor.TRANSPARENT, true);

		data.step = steps;
		data.maxStep = steps;
		data.pixels = pixels;

		data.wrap = loopOnWrap;
		data.complete = false;
		data.scrolling = true;
		data.onScreenScroller = onlyScrollOnscreen;

		scroll(data);

		members.set(data.sprite, data);

		return data.sprite;
	}

	/**
	 * Adds or replaces the text in the given Text Scroller.
	 * Can be called while the scroller is still active.
	 *
	 * @param	source		The FlxSprite Text Scroller you wish to update (must have been added to FlxScrollingText via a call to add()
	 * @param	text		The text to add or update to the Scroller
	 * @param	overwrite	If true the given text will fully replace the previous scroller text. If false it will be appended to the end (default)
	 */
	public static function addText(source:FlxSprite, text:String, overwrite:Bool = false):Void
	{
		var data:ScrollingTextData = members.get(source);

		if (overwrite)
		{
			data.bitmapText.text = text;
		}
		else
		{
			data.bitmapText.text += text;
		}

		data.bitmapText.drawFrame(true);
	}

	static function scroll(data:ScrollingTextData):Void
	{
		//	Have we reached enough steps?
		if (data.maxStep > 0 && (data.step < data.maxStep))
		{
			data.step++;
			return;
		}
		else
		{
			//	It's time to render, so reset the step counter and lets go
			data.step = 0;
		}

		//	CLS
		var pixels:BitmapData = data.sprite.pixels;
		pixels.fillRect(pixels.rect, FlxColor.TRANSPARENT);

		//	Shift the current contents of the buffer along by "speed" pixels
		data.shiftRect.x = data.x;

		if (data.shiftRect.right > data.bitmapText.frameWidth)
		{
			var rw:Float = data.shiftRect.width;
			data.shiftRect.width = data.bitmapText.frameWidth - data.x;
			pixels.copyPixels(data.bitmapText.framePixels, data.shiftRect, zeroPoint, null, null, true);
			data.shiftRect.width = rw;
		}
		else
		{
			pixels.copyPixels(data.bitmapText.framePixels, data.shiftRect, zeroPoint, null, null, true);
		}

		if (data.wrap && data.shiftRect.right > data.bitmapText.frameWidth)
		{
			data.shiftRect.x = 0;
			zeroPoint.x = data.bitmapText.frameWidth - data.x;
			pixels.copyPixels(data.bitmapText.framePixels, data.shiftRect, zeroPoint, null, null, true);
			zeroPoint.x = 0;
		}

		//	Copy the side of the character
		if (data.complete == false)
		{
			//	Update
			data.x += data.pixels;

			if (data.x >= data.bitmapText.frameWidth)
			{
				//	At the end of the text
				if (data.wrap)
				{
					data.x = 0;
				}
				else
				{
					data.complete = true;
					data.scrolling = false;
				}

				if (data.complete == false)
				{
					data.x = 0;
				}
			}
		}

		data.sprite.pixels = pixels;
	}

	/**
	 * Removes all FlxSprites
	 * This is called automatically if the plugin is destroyed, but should be called manually by you if you change States
	 * as all the FlxSprites will be destroyed by Flixel otherwise
	 */
	public static function clear():Void
	{
		for (obj in members)
		{
			remove(obj.sprite);
		}
	}

	/**
	 * Starts scrolling on the given FlxSprite. If no FlxSprite is given it starts scrolling on all FlxSprites currently added.
	 * Scrolling is enabled by default, but this can be used to re-start it if you have stopped it via stopScrolling.
	 *
	 * @param	source	The FlxSprite to start scrolling on. If left as null it will start scrolling on all sprites.
	 */
	public static function startScrolling(source:FlxSprite = null):Void
	{
		if (source != null)
		{
			members.get(source).scrolling = true;
		}
		else
		{
			for (obj in members)
			{
				obj.scrolling = true;
			}
		}
	}

	/**
	 * Stops scrolling on the given FlxSprite. If no FlxSprite is given it stops scrolling on all FlxSprites currently added.
	 * Scrolling is enabled by default, but this can be used to stop it.
	 *
	 * @param	source	The FlxSprite to stop scrolling on. If left as null it will stop scrolling on all sprites.
	 */
	public static function stopScrolling(source:FlxSprite = null):Void
	{
		if (source != null)
		{
			members.get(source).scrolling = false;
		}
		else
		{
			for (obj in members)
			{
				obj.scrolling = false;
			}
		}
	}

	/**
	 * Checks to see if the given FlxSprite is a Scrolling Text, and is actively scrolling or not
	 * Note: If the text is set to only scroll when on-screen, but if off-screen when this is called, it will still return true.
	 *
	 * @param	source	The FlxSprite to check for scrolling on.
	 * @return	True if the FlxSprite was found and is scrolling, otherwise false
	 */
	public static function isScrolling(source:FlxSprite):Bool
	{
		if (members.get(source) != null)
		{
			return members.get(source).scrolling;
		}

		return false;
	}

	/**
	 * Removes an FlxSprite from the Text Scroller. Note that it doesn't restore the sprite bitmapData.
	 *
	 * @param	source	The FlxSprite to remove scrolling for.
	 * @return	True if the FlxSprite was removed, otherwise false.
	 */
	public static function remove(source:FlxSprite):Bool
	{
		if (members.exists(source))
		{
			var data = members.get(source);
			data.destroy();
			members.remove(source);
			return true;
		}

		return false;
	}

	override public function draw():Void
	{
		for (obj in members)
		{
			if (obj != null && (obj.onScreenScroller == true && obj.sprite.isOnScreen()) && obj.scrolling == true && obj.sprite.exists)
			{
				scroll(obj);
			}
		}
	}

	override public function destroy():Void
	{
		clear();
	}
}

class ScrollingTextData
{
	public var bitmapText:FlxBitmapText;
	public var shiftRect:Rectangle;
	public var x:Int;
	public var sprite:FlxSprite;
	public var step:Int;
	public var maxStep:Int;
	public var pixels:Int;
	public var wrap:Bool;
	public var complete:Bool;
	public var scrolling:Bool;
	public var onScreenScroller:Bool;

	public function new() {}

	public function destroy():Void
	{
		bitmapText = null;
		shiftRect = null;
		sprite = null;
	}
}
