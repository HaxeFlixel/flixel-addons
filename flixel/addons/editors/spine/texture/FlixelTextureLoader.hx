package flixel.addons.editors.spine.texture;

import flash.display.BitmapData;

import flixel.FlxG;

import spinehaxe.Exception.IllegalArgumentException;
import spinehaxe.atlas.Texture;
import spinehaxe.atlas.AtlasPage;
import spinehaxe.atlas.AtlasRegion;
import spinehaxe.atlas.TextureLoader;

class FlixelTextureLoader implements TextureLoader
{
    var prefix:String;

	public function new(prefix:String) 
    {
        this.prefix = prefix; 
    }

    public function loadPage (page:AtlasPage, path:String):Void 
    {
        var texture:FlixelTexture = loadTexture(path);
        page.rendererObject = texture;
        page.width = texture.width;
        page.height = texture.height;
	}

	public function loadRegion (region:AtlasRegion):Void
    {
	}

	public function unloadPage (page:AtlasPage):Void 
    {
        cast(page.rendererObject, FlixelTexture).dispose();
	}

	public function loadTexture(textureFile:String, ?format, ?useMipMaps):FlixelTexture
    {
        return new FlixelTexture(prefix + textureFile);
	}
	
}
