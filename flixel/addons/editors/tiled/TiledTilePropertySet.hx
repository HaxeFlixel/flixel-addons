package flixel.addons.editors.tiled;

import flixel.addons.editors.tiled.TiledObject;

/** @since 2.2.0 */
typedef TileAnimationData =
{
	var tileID:Int;
	var duration:Float;
}

/** @since 2.2.0 */
class TiledTilePropertySet extends TiledPropertySet
{
	public var tileID:Int;
	public var animationFrames:Array<TileAnimationData>;

	/** @since 2.8.0 */
	public var tileObjects:Array<TiledObject>;

	public function new(tileID:Int)
	{
		super();
		this.tileID = tileID;
		animationFrames = new Array();
		tileObjects = new Array();
	}

	public function addAnimationFrame(tileID:Int, duration:Float):Void
	{
		animationFrames.push({tileID: tileID, duration: duration});
	}

	/** @since 2.8.0 */
	public function addTileObject(tileObject:TiledObject):Void
	{
		tileObjects.push(tileObject);
	}
}
