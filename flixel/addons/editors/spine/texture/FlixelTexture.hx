package flixel.addons.editors.spine.texture;

import flash.display.BitmapData;
import flixel.FlxG;
import spinehaxe.atlas.Texture;

class FlixelTexture implements Texture 
{
	public var bd:BitmapData;
	public var key:String;
	
	public var width(get, never):Int;
	public var height(get, never):Int;
	
	public function new(textureFile:String) 
	{
		var graphic = FlxG.bitmap.add(textureFile);
		this.bd = graphic.bitmap;
		this.key = graphic.key;
	}
	
	public function get_width():Int 
	{
		return bd.width;
	}
	
	public function get_height():Int 
	{
		return bd.height;
	}
	
	public function dispose():Void 
	{ 
		FlxG.bitmap.removeByKey(key);
		bd = null;
		key = null;
	}
	
	public function setWrap(uWrap, vWrap):Void {}
	public function setFilter(minFilter, magFilter):Void {}
}
