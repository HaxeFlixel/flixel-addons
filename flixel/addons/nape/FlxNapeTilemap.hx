package ;
import nape.phys.Material;
import nape.shape.Polygon;
import flash.geom.Rectangle;
import flixel.addons.nape.FlxNapeState;
import flixel.tile.FlxTilemap;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.util.Debug;

/**
 * @author Tilman Schmidt
 */
class FlxNapeTilemap extends FlxTilemap {
	public var body:Body;
	private var _binaryData:Array<Int>;
	public function new() {
		super();
		body = new Body(BodyType.STATIC);
	}
	/**
	 * Builds the nape collider with all tiles indices greater or equal to CollideIndex as solid (like in FlxTilemap), and assigns the nape material
	 * @param	CollideIndex	All tiles with an index greater or equal to this will be solid
	 * @param	?mat			The Nape physics material to use. Will use the default material if not specified
	 */
	public function setupCollideIndex(CollideIndex:Int = 1, ?mat:Material) {
		if (mat == null) {
			mat = new Material();
		}
		var tileIndex:Int = 0;
		var startRow:Int = -1;
		var endRow:Int = -1;
		_binaryData = new Array<Int>();
		var rects:Array<Rectangle> = new Array<Rectangle>();
		
		//Iterate through the tilemap and convert it to a binary map, marking if a tile is solid (1) or not (0)
		for (y in 0...heightInTiles) {
			for (x in 0...widthInTiles) {
				tileIndex = x + (y * widthInTiles);
				_binaryData.push(if (_data[tileIndex] >= CollideIndex) 1 else 0);
			}
		}
		//Go over every column, then scan along them
		for (x in 0...widthInTiles) {
			for (y in 0...heightInTiles) {
				tileIndex = x + (y * widthInTiles);
				//Is that tile solid?
				if (_binaryData[tileIndex] == 1) {
					//Mark the beginning of a new rectangle
					if (startRow == -1) {
						startRow = y;
					}
					//Mark the tile as already read
					_binaryData[tileIndex] = -1;
					
				}
				//Is the tile not solid or already read
				else if (_binaryData[tileIndex] == 0 || _binaryData[tileIndex] == -1) {
					//If we marked the beginning a rectangle, end it and process it
					if (startRow != -1) {
						endRow = y - 1;
						rects.push(constructRectangle(x, startRow, endRow));
						startRow = -1;
						endRow = -1;
					}
				}
			}
			//If we reached the last line and marked the beginning of a rectangle, end it and process it
			if (startRow != -1) {
				endRow = heightInTiles - 1;
				rects.push(constructRectangle(x, startRow, endRow));
				startRow = -1;
				endRow = -1;
			}
		}
		//Convert the rectangles to nape polygons
		var vertices:Array<Vec2>;
		for (rect in rects) {
			vertices = new Array<Vec2>();
			rect.x *= _tileWidth;
			rect.y *= _tileHeight;
			rect.width++;
			rect.width *= _tileWidth;
			rect.height++;
			rect.height *= _tileHeight;
			vertices.push(Vec2.get(rect.x, rect.y));
			vertices.push(Vec2.get(rect.width, rect.y));
			vertices.push(Vec2.get(rect.width, rect.height));
			vertices.push(Vec2.get(rect.x, rect.height));
			body.shapes.add(new Polygon(vertices, mat));
		}
		
		if (body.space == null) {
			body.space = FlxNapeState.space;
		}
	}
	
	public function setupTileIndices(tileIndices:Array<Int>, ?mat:Material) {
		if (mat == null) {
			mat = new Material();
		}
	}
	/**
	 * Scans along x in the rows between StartY to EndY for the biggest rectangle covering solid tiles in the binary data
	 * @param	StartX	The column in which the rectangle starts
	 * @param	StartY	The row in which the rectangle starts
	 * @param	EndY	The row in which the rectangle ends
	 * @return			The rectangle covering solid tiles. CAUTION: Width is used as bottom-right x coordinate, height is used as bottom-right y coordinate
	 */
	function constructRectangle(StartX:Int, StartY:Int, EndY:Int):Rectangle {
		//Increase StartX by one to skip the first column, we checked that one already
		StartX++;
		var rectFinished:Bool = false;
		var tileIndex:Int = 0;
		//go along the columns from StartX onwards, then scan along those columns in the range of StartY to EndY
		for (x in StartX...widthInTiles) {
			for (y in StartY...(EndY + 1)) {
				tileIndex = x + (y * widthInTiles);
				//If the range includes a non-solid tile or a tile already read, the rectangle is finished
				if (_binaryData[tileIndex] == 0 || _binaryData[tileIndex] == -1) {
					rectFinished = true;
				}
			}
			if (rectFinished) {
				//If the rectangle is finished, fill the area covered with -1 (tiles have been read)
				for (u in StartX...x) {
					for (v in StartY...(EndY + 1)) {
						tileIndex = u + (v * widthInTiles);
						_binaryData[tileIndex] = -1;
					}
				}
				//StartX - 1 to counteract the increment in the beginning
				//Slight misuse of Rectangle here, width and height are used as x/y of the bottom right corner
				return new Rectangle(StartX - 1, StartY, x - 1, EndY);
			}
		}
		//We reached the end of the map without finding a non-solid/alread-read tile, finalize the rectangle with the map's right border as the endX
		for (u in StartX...widthInTiles) {
			for (v in StartY...(EndY + 1)) {
				tileIndex = u + (v * widthInTiles);
				_binaryData[tileIndex] = -1;
			}
		}
		
		return new Rectangle(StartX - 1, StartY, widthInTiles - 1, EndY);
	}
	
}