package flixel.addons.editors.tiled;

import haxe.xml.Fast;

class TiledImageLayer extends TiledLayer
{
	public var imagePath:String;
	public var x:Int;
	public var y:Int;

	public function new(source:Fast, parent:TiledMap)
	{
		super(source, parent);
		type = IMAGE;
		imagePath = source.node.image.att.source;
		x = (source.has.x) ? Std.parseInt(source.att.x) : 0;
		y = (source.has.y) ? Std.parseInt(source.att.y) : 0;
	}
}
