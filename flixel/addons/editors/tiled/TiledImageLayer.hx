package flixel.addons.editors.tiled;

#if haxe4
import haxe.xml.Access;
#else
import haxe.xml.Fast as Access;
#end

class TiledImageLayer extends TiledLayer
{
	public var imagePath:String;

	public function new(source:Access, parent:TiledMap)
	{
		super(source, parent);
		type = IMAGE;
		imagePath = source.node.image.att.source;
	}
}
