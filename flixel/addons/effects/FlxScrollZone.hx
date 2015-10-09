package flixel.addons.effects;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.util.FlxDestroyUtil;
import openfl.display.Sprite;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.utils.Dictionary;
import openfl.utils.Object;

/**
 * FlxScrollZone allows you to scroll the content of an FlxSprites bitmapData in any direction you like.
 * Based on code from Richard Davey / Photon Storm
 * @author Tim Hely / tims-world.com 
 */
class FlxScrollZone extends FlxBasic
{
	
	private static var _members:Dictionary = new Dictionary(true);
	private static var zeroPoint:Point = new Point;

	public function new() 
	{
		
	}
	
	/**
	 * Add an FlxSprite to the Scroll Manager, setting up one scrolling region. <br />
	 * To add extra scrolling regions on the same sprite use addZone()
	 * 
	 * @param	Source				The FlxSprite to apply the scroll to
	 * @param	Region				The region, specified as a Rectangle, of the FlxSprite that you wish to scroll
	 * @param	DistanceX			The distance in pixels you want to scroll on the X axis. Negative values scroll left. Positive scroll right. Floats allowed (0.5 would scroll at half speed)
	 * @param	DistanceY			The distance in pixels you want to scroll on the Y axis. Negative values scroll up. Positive scroll down. Floats allowed (0.5 would scroll at half speed)
	 * @param	OnlyScrollOnscreen	Only update this FlxSprite if visible onScreen (default true) Saves performance by not scrolling offscreen sprites, but this isn't always desirable
	 * @param	ClearRegion			Set to true if you want to clear the scrolling area of the FlxSprite with a 100% transparent fill before applying the scroll texture (default false)
	 * @see		createZone
	 */
	public static function add(Source:FlxSprite, Region:Rectangle, DistanceX:Float, DistanceY:Float, OnlyScrollOnScreen:Bool = true, ClearRegion:Bool = false):Void
	{
		if (members[Source])
		{
			throw "FlxSprite already exists in FlxScrollZone, use addZone to add a new scrolling region to an already added FlxSprite.";
			return;
		}
		
		var data:Object = new Object();
		data.source = Source;
		data.scrolling = true;
		data.onlyScrollOnScreen = OnlyScrollOnScreen;
		data.zones = new Array();
		members[Source] = data;
		createZone(Source, Region, DistanceX, DistanceY, ClearRegion)
		
	}
	
	/**
	 * Creates a new scrolling region to an FlxSprite already in the Scroll Manager (see add())<br />
	 * 
	 * @param	Source				The FlxSprite to apply the scroll to
	 * @param	Region				The region, specified as a Rectangle, of the FlxSprite that you wish to scroll
	 * @param	DistanceX			The distance in pixels you want to scroll on the X axis. Negative values scroll left. Positive scroll right. Floats allowed (0.5 would scroll at half speed)
	 * @param	DistanceY			The distance in pixels you want to scroll on the Y axis. Negative values scroll up. Positive scroll down. Floats allowed (0.5 would scroll at half speed)
	 * @param	ClearRegion			Set to true if you want to fill the scroll region of the FlxSprite with a 100% transparent fill before scrolling it (default false)
	 */
	public static function createZone(Source:FlxSprite, Region:Rectangle, DistanceX:Float, DistanceY:Float, ClearRegion:Bool = false):Void
	{
		var texture:BitmapData = new BitmapData(Region.width, Region.height, true, 0x0);
		texture.copyPixels(Source.framePixels, Region, zeroPoint, null, null, true);
		var data:Object = new Object();
		data.buffer = new Sprite();
		data.texture = texture;
		data.region = Region;
		data.clearRegion = ClearRegion;
		data.distanceX = DistanceX;
		data.distanceY = DistanceY;
		data.scrollMatrix = new Matrix();
		data.drawMatrix = new Matrix(1, 0, 0, 1, Region.x, Region.y);
		
		members[Source].zones.push(data);
	}
	
	/**
	 * Sets the draw Matrix for the given FlxSprite scroll zone<br />
	 * Warning: Modify this at your own risk!
	 * 
	 * @param	Source		The FlxSprite to set the draw matrix on
	 * @param	Matrix		The Matrix to use during the scroll update draw 
	 * @param	Zone		If the FlxSprite has more than 1 scrolling zone, use this to target which zone to apply the update to (default 0)
	 * @return	Matrix		The draw matrix used in the scroll update
	 */
	public static function updateDrawMatrix(Source:FlxSprite, NewMatrix:Matrix, Zone:Int = 0):Matrix
	{
		return members[Source].zones[Zone].drawMatrix = NewMatrix;
		
	}
	
	/**
	 * Returns the draw Matrix for the given FlxSprite scroll zone
	 * 
	 * @param	Source		The FlxSprite to get the draw matrix from
	 * @param	Zone		If the FlxSprite has more than 1 scrolling zone, use this to target which zone to apply the update to (default 0)
	 * @return	Matrix		The draw matrix used in the scroll update
	 */
	public static function getDrawMatrix(Source:FlxSprite, Zone:int = 0):Matrix
	{
		return members[Source].zones[Zone].drawMatrix;
	}
	
	/**
	 * Removes an FlxSprite and all of its scrolling zones. Note that it doesn't restore the sprite bitmapData.
	 * 
	 * @param	Source	The FlxSprite to remove all scrolling zones for.
	 * @return	Bool	true if the FlxSprite was removed, otherwise false.
	 */
	public static function remove(Source:FlxSprite):Bool
	{
		if (members[Source])
		{
			members[Source] = null;
			
			return true;
		}
		
		return false;
	}
	
	/**
	 * Removes all FlxSprites, and all of their scrolling zones.<br />
	 * This is called automatically if the plugin is ever destroyed.
	 */
	public static function clear():Void
	{
		for (obj in members)
		{
			members[obj.source] = null;
		}
	}
	
	/**
	 * Update the distance in pixels to scroll on the X axis.
	 * 
	 * @param	Source		The FlxSprite to apply the scroll to
	 * @param	DistanceX	The distance in pixels you want to scroll on the X axis. Negative values scroll left. Positive scroll right. Floats allowed (0.5 would scroll at half speed)
	 * @param	Zone		If the FlxSprite has more than 1 scrolling zone, use this to target which zone to apply the update to (default 0)
	 */
	public static function updateX(Source:FlxSprite, DistanceX:Float, Zone:Int = 0):Void
	{
		members[Source].zones[Zone].distanceX = DistanceX;
	}
	
	/**
	 * Update the distance in pixels to scroll on the Y axis.
	 * 
	 * @param	Source		The FlxSprite to apply the scroll to
	 * @param	DistanceY	The distance in pixels you want to scroll on the Y axis. Negative values scroll up. Positive scroll down. Floats allowed (0.5 would scroll at half speed)
	 * @param	Zone		If the FlxSprite has more than 1 scrolling zone, use this to target which zone to apply the update to (default 0)
	 */
	public static function updateY(Source:FlxSprite, DistanceY:Float, Zone:Int = 0):Void
	{
		members[Source].zones[Zone].distanceY = DistanceY;
	}
	
	/**
	 * Starts scrolling on the given FlxSprite. If no FlxSprite is given it starts scrolling on all FlxSprites currently added.<br />
	 * Scrolling is enabled by default, but this can be used to re-start it if you have stopped it via stopScrolling.<br />
	 * 
	 * @param	Source	The FlxSprite to start scrolling on. If left as null it will start scrolling on all sprites.
	 */
	public static function startScrolling(Source:FlxSprite = null):Void
	{
		if (Source)
		{
			members[Source].scrolling = true;
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
	 * Stops scrolling on the given FlxSprite. If no FlxSprite is given it stops scrolling on all FlxSprites currently added.<br />
	 * Scrolling is enabled by default, but this can be used to stop it.<br />
	 * 
	 * @param	Source	The FlxSprite to stop scrolling on. If left as null it will stop scrolling on all sprites.
	 */
	public static function stopScrolling(Source:FlxSprite = null):Void
	{
		if (Source)
		{
			members[Source].scrolling = false;
		}
		else
		{
			for (obj in members)
			{
				obj.scrolling = false;
			}
		}
	}
	
	override public function draw():Void
	{
		for (obj in members)
		{
			if ((obj.onlyScrollOnscreen == true && obj.source.isOnScreen()) && obj.scrolling == true && obj.source.exists)
			{
				scroll(obj);
			}
		}
	}
	
	private function scroll(data:Object):Void
	{
		//	Loop through the scroll zones defined in this object
		for (zone in data.zones)
		{
			zone.scrollMatrix.tx += zone.distanceX;
			zone.scrollMatrix.ty += zone.distanceY;
			
			zone.buffer.graphics.clear();
			zone.buffer.graphics.beginBitmapFill(zone.texture, zone.scrollMatrix, true, false);
			zone.buffer.graphics.drawRect(0, 0, zone.region.width, zone.region.height);
			zone.buffer.graphics.endFill();
			
			if (zone.clearRegion)
			{
				data.source.pixels.fillRect(zone.region, 0x0);
			}
			
			data.source.pixels.draw(zone.buffer, zone.drawMatrix);
		}
		
		data.source.dirty = true;
	}
	
	override public function destroy():Void
	{
		clear();
	}
	
	
	
}