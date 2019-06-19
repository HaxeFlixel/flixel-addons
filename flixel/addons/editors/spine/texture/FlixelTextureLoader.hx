package flixel.addons.editors.spine.texture;

import flixel.graphics.FlxGraphic;
import openfl.Assets;
import openfl.display.BitmapData;
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

	public function loadPage(page:AtlasPage, path:String):Void
	{
		var bitmapData:BitmapData = Assets.getBitmapData(prefix + path);
		if (bitmapData == null)
			throw("BitmapData not found with name: " + this.prefix + path);
		page.rendererObject = FlxG.bitmap.add(bitmapData);
		page.width = bitmapData.width;
		page.height = bitmapData.height;
	}

	public function loadRegion(region:AtlasRegion):Void {}

	public function unloadPage(page:AtlasPage):Void
	{
		FlxG.bitmap.remove(cast page.rendererObject);
	}
}
