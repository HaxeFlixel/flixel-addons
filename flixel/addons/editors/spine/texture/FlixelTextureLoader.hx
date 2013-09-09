package flixel.addons.editors.spine.texture;

import spinehx.atlas.Texture;
import spinehx.atlas.TextureLoader;

class FlixelTextureLoader implements TextureLoader
{
    public function new() {  }

    public function loadTexture(textureFile:String, format, useMipMaps):Texture 
	{
        return new FlixelTexture(textureFile);
    }
}
