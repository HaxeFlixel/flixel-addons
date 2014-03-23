package flixel.addons.nape;

import flash.geom.Point;
import flixel.addons.nape.FlxNapeTilemap.CollideIndexIso;
import nape.geom.AABB;
import nape.geom.ConvexResult;
import nape.geom.GeomPoly;
import nape.geom.GeomPolyIterator;
import nape.geom.GeomPolyList;
import nape.geom.GeomVertexIterator;
import nape.geom.IsoFunction;
import nape.geom.MarchingSquares;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Polygon;
import nape.space.Space;
import flixel.tile.FlxTilemap;

/**
 * Adapter class to implement tile maps in nape.
 * @author Charles Wang
 * Port by KeyMaster (@KeyMaster_)
 */
class FlxNapeTilemap extends FlxTilemap {
	public var body:Body;
	
	public function new() {
		super();
		body = new Body(BodyType.STATIC);
		//TODO positioning stuff, override loadMap from FlxTilemap
	}
	
	//TODO What return type should this have?
	override public function loadMap(MapData:Dynamic, TileGraphic:Dynamic, TileWidth:Int = 0, TileHeight:Int = 0, AutoTile:Int = 0, StartingIndex:Int = 0, DrawIndex:Int = 1, CollideIndex:Int = 1):FlxTilemap
	{
		super.loadMap(MapData, TileGraphic, TileWidth, TileHeight, AutoTile, StartingIndex, DrawIndex, CollideIndex);
		setupCollideIndex(CollideIndex, new Material());
		body.space = FlxNapeState.space;
		return this;
	}

	/**
	 * Loads a tile map. Delegates to the underlying FlxTilemap. This method will only create the tilemap 
	 * in flixel. Call setupNapeTiles() after calling this method to port the tiles into a nape simulation.
	 * @param	MapData
	 * @param	TileGraphic
	 * @param	TileWidth
	 * @param	TileHeight
	 * @param	AutoTile
	 * @param	StartingIndex
	 * @param	DrawIndex
	 * @return
	 */
	/*
	public function loadMap(MapData:String, TileGraphic:Class, TileWidth:uint = 0, TileHeight:uint = 0, AutoTile:uint = FlxTilemap.OFF, StartingIndex:uint = 0, DrawIndex:uint = 1):FlxTilemap {
		return tileMap.loadMap(MapData, TileGraphic, TileWidth, TileHeight, AutoTile, StartingIndex, DrawIndex, uint.MAX_VALUE);
	}
	*/
	/**
	 * Replaces the body with a new collision mesh with all tile types greater or equal to the specified one set as solid
	 * @param	tileType		All tile types greater or equal to this are solid
	 * @param	mat				The physics material used for the physics body
	 */
	public function setupCollideIndex(tileType:Int, mat:Material) {
		body = new Body(BodyType.STATIC, body.position);
		var data:Array<Int> = getData();
		#if flash
		var iso:CollideIndexIso = new CollideIndexIso(tileType, _tileWidth, _tileHeight, widthInTiles, getData());
		
		//Something in the algorithm creates diagonals for bottom-right corners in tilemaps
		//You can somewhat counter this by making the cell size a fraction of the tile size 
		// but this comes with a substantial speed tradeoff (going towards seconds in processing times when usuing tileSize / 16)
		
		var polys:GeomPolyList = MarchingSquares.run(iso, new AABB(0, 0, width, height), Vec2.get(_tileWidth, _tileHeight), 4);
		
		#end
		
		
		var it:GeomPolyIterator = polys.iterator();
		while (it.hasNext()) {
			var poly:GeomPoly = it.next();
			var it2:GeomPolyIterator = poly.convexDecomposition().iterator();
			while (it2.hasNext()) {
				var convexPoly:GeomPoly = it2.next();
				var vIt:GeomVertexIterator = convexPoly.iterator();
				var vertices:Array<Vec2> = new Array<Vec2>();
				while (vIt.hasNext()) {
					vertices.push(vIt.next());
				}
				body.shapes.add(new Polygon(vertices, mat));
			}
		}
	}
	
	/**
	 * Creates shapes in the nape simulation that correspond to tiles within the tilemap. Used to enforce 
	 * tile collision in nape. Iterates through all tiles of a specified index type and creates a shape 
	 * for each one within the nape simulation at the appropriate coordinates.
	 * @param	tileType the index type of tile for which you want to create shapes.
	 * @param	space the nape simulation in which to create the shapes.
	 * @param	mat the material the new shapes will have.
	 * @param	body the body to which the new shapes will be added. If a body isn't specified a new 
	 * one of type BodyType.STATIC will be created.
	 * @return the body containing the new shapes.
	 */
	/*
	public function setupNapeTiles(tileType:uint, space:Space, mat:Material, body:Body = null):Body {
		if (body == null) body = new Body(BodyType.STATIC);
		var data:Array = tileMap.getData();
		var polys:GeomPolyList = MarchingSquares.run(function(x:Number, y:Number):Number {
			var tileX:int = (x / tileMap.tileWidth) as int;
			var tileY:int = (y / tileMap.tileHeight) as int;
			var i:int = tileY * tileMap.widthInTiles + tileX;
			if (i >= 0 && i < data.length) {
				if (data[i] == tileType) {
					return -1;
				}
			}
			return 1;
		}, new AABB(0, 0, tileMap.width, tileMap.height), Vec2.get(tileMap.tileWidth / 4, tileMap.tileHeight / 4), 4);
		var it:GeomPolyIterator = polys.iterator();
		while (it.hasNext()) {
			var poly:GeomPoly = it.next();
			var it2:GeomPolyIterator = poly.convex_decomposition().iterator();
			while (it2.hasNext()) {
				var convexPoly:GeomPoly = it2.next();
				var vIt:GeomVertexIterator = convexPoly.iterator();
				var vertices:Array = new Array();
				while (vIt.hasNext()) {
					vertices.push(vIt.next());
				}
				body.shapes.add(new Polygon(vertices, mat));
			}
		}
		return body;
	}
	*/
}

#if flash
class CollideIndexIso implements IsoFunction {
	public var tileWidth:Int;
	public var tileHeight:Int;
	public var data:Array<Int>;
	public var tileType:Int;
	public var widthInTiles:Int;
	var tileX:Int;
	var tileY:Int;
	var i:Int;
	public function new(TileType:Int, TileWidth:Int, TileHeight:Int, WidthInTiles:Int, Data:Array<Int>) {
		tileWidth = TileWidth;
		tileHeight = TileHeight;
		tileType = TileType;
		widthInTiles = WidthInTiles;
		data = Data;
	}
	public function iso(x:Float, y:Float):Float {
		tileX = Std.int((x / tileWidth));
		tileY = Std.int((y / tileHeight));
		i = tileY * widthInTiles + tileX;
		if (i >= 0 && i < data.length) {
			if (data[i] >= tileType) {
				return -1;
			}
		}
		return 1;
	}
}

#end