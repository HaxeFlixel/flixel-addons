package flixel.addons.editors.tiled;

typedef TileAnimationData = {
	var tileID:Int;
	var duration:Float;
}

class TiledTilePropertySet extends TiledPropertySet
{
	public var tileID:Int;
	public var animationFrames:Array<TileAnimationData>;

	public function new(tileID:Int)
	{
		super();
		this.tileID = tileID;
		animationFrames = new Array();
	}

	public function addAnimationFrame(tileID:Int, duration:Float):Void
	{
		animationFrames.push({ tileID: tileID, duration: duration });
	}
}
