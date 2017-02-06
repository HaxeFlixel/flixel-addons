package flixel.addons.editors.tiled;

/** @since 2.2.0 */
typedef TileAnimationData = {
	var tileID:Int;
	var duration:Float;
}

/** @since 2.2.0 */
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
