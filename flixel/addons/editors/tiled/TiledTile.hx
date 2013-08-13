package flixel.addons.editors.tiled;

/*
 * Helper class to get the original tileset id of the tile and if the tile is
 * flipped and/or rotated
 */
class TiledTile
{
	public static var FLIPPED_HORIZONTAL_FLAG:Int = 0x80000000;
	public static var FLIPPED_VERTICAL_FLAG:Int = 0x40000000;
	public static var FLIPPED_DIAGONAL_FLAG:Int = 0x20000000;
	
	public static var ROTATE_0:Int = 0;
	public static var ROTATE_90:Int = 1;
	public static var ROTATE_270:Int = 2;
	
	/*
	 * The original ID as described in the mapData
	 */
	public var tileID:UInt;
	
	/*
	 * The ID of this tile in its tileset
	 */
	public var tilesetID(default, null):Int;
	
	/*
	 * Set the tile to flip horizontally
	 */
	public var isFlipHorizontally:Bool = false;
	/*
	 * Set the tile to flip vertically
	 */
	public var isFlipVertically:Bool = false;
	
	/*
	 * Set the rotation of the tile
	 */
	public var rotate:Int;
	
	public function new(OriginalId:UInt) {
		this.tileID = OriginalId;
		this.tilesetID = resolveTilesetID();
		this.rotate = ROTATE_0;
		resolveFlipAndRotation();
	}
	
	private function resolveFlipAndRotation():Void {
		var flipHorizontal:Bool = false;
		var flipVertical:Bool = false;
		if ((tileID & FLIPPED_HORIZONTAL_FLAG) != 0) {
			flipHorizontal = true;
		}
		if ((tileID & FLIPPED_VERTICAL_FLAG) != 0) {
			flipVertical = true;
		}
		
		if ((tileID & FLIPPED_DIAGONAL_FLAG) != 0) {
			if (flipHorizontal && flipVertical) {
				isFlipHorizontally = true;
				rotate = ROTATE_270;
			} else if (flipHorizontal) {
				rotate = ROTATE_90;
			} else if (flipVertical) {
				rotate = ROTATE_270;
			} else {
				isFlipVertically = true;
				rotate = ROTATE_270;
			}
		} else {
			isFlipHorizontally = flipHorizontal;
			isFlipVertically = flipVertical;
		}
		
	}
	
	private function resolveTilesetID():Int {
		return tileID & ~(FLIPPED_HORIZONTAL_FLAG |	FLIPPED_VERTICAL_FLAG |	FLIPPED_DIAGONAL_FLAG);
	}
	
}