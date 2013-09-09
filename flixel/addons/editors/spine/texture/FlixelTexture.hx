package flixel.addons.editors.spine.texture;

import openfl.Assets;
import flixel.FlxG;
import spinehx.atlas.Texture;
import flash.display.BitmapData;

class FlixelTexture implements Texture 
{
    public var bd:BitmapData;
	public var key:String;
	
    public function new(textureFile:String) 
	{
        var cached = FlxG.bitmap.add(textureFile);
		this.bd = cached.bitmap;
		this.key = cached.key;
    }
	
    public function getWidth():Int 
	{
        return bd.width;
    }
	
    public function getHeight():Int 
	{
        return bd.height;
    }
	
    public function dispose():Void 
	{ 
		FlxG.bitmap.remove(key);
		bd = null;
		key = null;
	}
	
    public function setWrap(uWrap, vWrap):Void {  }
	public function setFilter(minFilter, magFilter):Void {  }
}
