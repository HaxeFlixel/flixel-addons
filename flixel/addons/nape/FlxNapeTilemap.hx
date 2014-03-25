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

class FlxNapeTilemap extends FlxTilemap {
	public var body:Body;
	private var binaryData:Array<Int>;
	public function new() {
		super();
		body = new Body(BodyType.STATIC);
	}
	
	override public function loadMap(MapData:Dynamic, TileGraphic:Dynamic, TileWidth:Int = 0, TileHeight:Int = 0, AutoTile:Int = 0, StartingIndex:Int = 0, DrawIndex:Int = 1, CollideIndex:Int = 1):FlxTilemap 
	{
		super.loadMap(MapData, TileGraphic, TileWidth, TileHeight, AutoTile, StartingIndex, DrawIndex, CollideIndex);
		generateRectangles(CollideIndex, new Material());
		body.space = FlxNapeState.space;
		return this;
	}
	
	public function generateRectangles(collideIndex:Int = 1, mat:Material) {
		var tileIndex:Int = 0;
		var startRow:Int = -1;
		var endRow:Int = -1;
		binaryData = new Array<Int>();
		var rects:Array<Rectangle> = new Array<Rectangle>();
		for (y in 0...heightInTiles) {
			for (x in 0...widthInTiles) {
				tileIndex = x + (y * widthInTiles);
				binaryData.push(if (_data[tileIndex] >= collideIndex) 1 else 0);
			}
		}
		//Go through every column
		for (x in 0...widthInTiles) {
			for (y in 0...heightInTiles) {
				tileIndex = x + (y * widthInTiles);
				//Is that tile solid?
				if (binaryData[tileIndex] == 1) {
					if (startRow == -1) {
						startRow = y;
					}
					//Mark the tile as already read
					binaryData[tileIndex] = -1;
					
				}
				//Is the tile not solid?
				else if (binaryData[tileIndex] == 0 || binaryData[tileIndex] == -1){
					if (startRow != -1) {
						endRow = y - 1;
						rects.push(constructRectangle(x, startRow, endRow));
						startRow = -1;
						endRow = -1;
					}
				}
			}
			if (startRow != -1) {
				endRow = heightInTiles - 1;
				rects.push(constructRectangle(x, startRow, endRow));
				startRow = -1;
				endRow = -1;
			}
		}
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
	}
	
	public function constructRectangle(StartX:Int, StartY:Int, EndY:Int):Rectangle {
		//Increase StartX by one to skip the first column, we checked that one already
		StartX++;
		var rectFinished:Bool = false;
		var tileIndex:Int = 0;
		for (x in StartX...widthInTiles) {
			for (y in StartY...(EndY + 1)) {
				tileIndex = x + (y * widthInTiles);
				if (binaryData[tileIndex] == 0 || binaryData[tileIndex] == -1) {
					rectFinished = true;
				}
			}
			if (rectFinished) {
				for (u in StartX...x) {
					for (v in StartY...(EndY + 1)) {
						tileIndex = u + (v * widthInTiles);
						binaryData[tileIndex] = -1;
					}
				}
				//No StartX + 1 here because x should be x - 1, cancelles out | +1 to StartY since it's height
				return new Rectangle(StartX - 1, StartY, x - 1, EndY);
			}
		}
		for (u in StartX...widthInTiles) {
			for (v in StartY...(EndY + 1)) {
				tileIndex = u + (v * widthInTiles);
				binaryData[tileIndex] = -1;
			}
		}
		//StartX - 1 to balance out the ++ in the beginning | + 1 to StartY for the same reasons
		return new Rectangle(StartX - 1, StartY, widthInTiles - 1, EndY);
	}
}