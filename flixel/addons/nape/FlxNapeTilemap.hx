package flixel.addons.nape;

import flash.geom.Point;
import nape.geom.AABB;
import nape.geom.GeomPoly;
import nape.geom.GeomPolyIterator;
import nape.geom.GeomPolyList;
import nape.geom.GeomVertexIterator;
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
 */
class FlxNapeTilemap extends FlxTilemap {
	public var body:Body;
	
	public function new() {
		super();
		body = new Body(BodyType.STATIC);
		//TODO positioning stuff, override loadMap from FlxTilemap
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
	public function loadMap(MapData:String, TileGraphic:Class, TileWidth:uint = 0, TileHeight:uint = 0, AutoTile:uint = FlxTilemap.OFF, StartingIndex:uint = 0, DrawIndex:uint = 1):FlxTilemap {
		return tileMap.loadMap(MapData, TileGraphic, TileWidth, TileHeight, AutoTile, StartingIndex, DrawIndex, uint.MAX_VALUE);
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
}