package flixel.addons.editors.tiled;

/*
 * Helper class to get the original tileset id of the tile and if the tile is
 * flipped and/or rotated
 */
class TiledTile
{
	public static inline var FLIPPED_HORIZONTAL:Int = 0x80000000;
	public static inline var FLIPPED_VERTICAL:Int = 0x40000000;
	public static inline var FLIPPED_DIAGONAL:Int = 0x20000000;

	public static inline var ROTATE_0:Int = 0;
	public static inline var ROTATE_90:Int = 1;
	public static inline var ROTATE_270:Int = 2;

	/**
	 * The original ID as described in the mapData
	 */
	public var tileID:Int;

	/**
	 * The ID of this tile in its tileset
	 */
	public var tilesetID(default, null):Int;

	/**
	 * Set the tile to flip horizontally
	 */
	public var isFlipHorizontally:Bool = false;

	/**
	 * Set the tile to flip vertically
	 */
	public var isFlipVertically:Bool = false;

	/**
	 * Set the rotation of the tile
	 */
	public var rotate:Int;

	public function new(OriginalId:Int)
	{
		tileID = OriginalId;
		tilesetID = resolveTilesetID();
		rotate = ROTATE_0;
		resolveFlipAndRotation();
	}

	function resolveFlipAndRotation():Void
	{
		var flipHorizontal:Bool = (tileID & FLIPPED_HORIZONTAL) != 0;
		var flipVertical:Bool = (tileID & FLIPPED_VERTICAL) != 0;

		if ((tileID & FLIPPED_DIAGONAL) != 0)
		{
			if (flipHorizontal && flipVertical)
			{
				isFlipHorizontally = true;
				rotate = ROTATE_270;
			}
			else if (flipHorizontal)
			{
				rotate = ROTATE_90;
			}
			else if (flipVertical)
			{
				rotate = ROTATE_270;
			}
			else
			{
				isFlipVertically = true;
				rotate = ROTATE_270;
			}
		}
		else
		{
			isFlipHorizontally = flipHorizontal;
			isFlipVertically = flipVertical;
		}
	}

	inline function resolveTilesetID():Int
	{
		return tileID & ~(FLIPPED_HORIZONTAL | FLIPPED_VERTICAL | FLIPPED_DIAGONAL);
	}
}
