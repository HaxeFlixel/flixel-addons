package flixel.addons.editors.tiled;

import haxe.xml.Access;

class TiledImageLayer extends TiledLayer
{
	public var imagePath:String;

	/** Tiled version >= 0.15 uses offsetX */
	public var x:Int;

	/** Tiled version >= 0.15 uses offsetY */
	public var y:Int;

	public function new(source:Access, parent:TiledMap)
	{
		super(source, parent);
		type = IMAGE;
		imagePath = source.node.image.att.source;

		x = (source.has.x) ? Std.parseInt(source.att.x) : 0;
		y = (source.has.y) ? Std.parseInt(source.att.y) : 0;
	}
}
