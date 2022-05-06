package flixel.addons.nape;

import flixel.addons.nape.FlxNapeSpace;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tile.FlxTilemap;
import flixel.util.FlxArrayUtil;
import flixel.tile.FlxBaseTilemap;
import flixel.system.FlxAssets;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Polygon;

/**
 * @author KeyMaster
 */
class FlxNapeTilemap extends FlxTilemap
{
	public var body:Body;

	var _binaryData:Array<Int>;

	public function new()
	{
		super();
		body = new Body(BodyType.STATIC);
		body.space = FlxNapeSpace.space;
	}

	override public function update(elapsed:Float):Void
	{
		x = body.position.x;
		y = body.position.y;
		super.update(elapsed);
	}

	override public function loadMapFromCSV(MapData:String, TileGraphic:FlxTilemapGraphicAsset, TileWidth:Int = 0, TileHeight:Int = 0,
			?AutoTile:FlxTilemapAutoTiling, StartingIndex:Int = 0, DrawIndex:Int = 1, CollideIndex:Int = 1):FlxTilemap
	{
		super.loadMapFromCSV(MapData, TileGraphic, TileWidth, TileHeight, AutoTile, StartingIndex, DrawIndex, CollideIndex);
		_binaryData = new Array<Int>();
		FlxArrayUtil.setLength(_binaryData, _data.length);
		return this;
	}

	override public function loadMapFromArray(MapData:Array<Int>, WidthInTiles:Int, HeightInTiles:Int, TileGraphic:FlxTilemapGraphicAsset, TileWidth:Int = 0,
			TileHeight:Int = 0, ?AutoTile:FlxTilemapAutoTiling, StartingIndex:Int = 0, DrawIndex:Int = 1, CollideIndex:Int = 1):FlxTilemap
	{
		super.loadMapFromArray(MapData, WidthInTiles, HeightInTiles, TileGraphic, TileWidth, TileHeight, AutoTile, StartingIndex, DrawIndex, CollideIndex);
		_binaryData = new Array<Int>();
		FlxArrayUtil.setLength(_binaryData, _data.length);
		return this;
	}

	override public function loadMapFrom2DArray(MapData:Array<Array<Int>>, TileGraphic:FlxTilemapGraphicAsset, TileWidth:Int = 0, TileHeight:Int = 0,
			?AutoTile:FlxTilemapAutoTiling, StartingIndex:Int = 0, DrawIndex:Int = 1, CollideIndex:Int = 1):FlxTilemap
	{
		super.loadMapFrom2DArray(MapData, TileGraphic, TileWidth, TileHeight, AutoTile, StartingIndex, DrawIndex, CollideIndex);
		_binaryData = new Array<Int>();
		FlxArrayUtil.setLength(_binaryData, _data.length);
		return this;
	}

	/**
	 * Adds a collision box for one tile at the specified position
	 * Using this many times will fragment the collider mesh, possibly impacting performance!
	 * If you are changing a lot of tiles, consider calling body.shapes.clear() and then setupCollideIndex or setupTileIndices
	 *
	 * @param	X		The X-Position of the tile
	 * @param	Y		The Y-Position of the tile
	 * @param	mat		The material for the collider. Defaults to default nape material
	 */
	public function addSolidTile(X:Int, Y:Int, ?mat:Material)
	{
		body.space = null;
		if (mat == null)
		{
			mat = new Material();
		}
		X *= tileWidth;
		Y *= tileHeight;
		var vertices = new Array<Vec2>();

		vertices.push(Vec2.get(X, Y));
		vertices.push(Vec2.get(X + tileWidth, Y));
		vertices.push(Vec2.get(X + tileWidth, Y + tileHeight));
		vertices.push(Vec2.get(X, Y + tileHeight));

		body.shapes.add(new Polygon(vertices, mat));

		body.space = FlxNapeSpace.space;
	}

	public function placeCustomPolygon(tileIndices:Array<Int>, vertices:Array<Vec2>, ?mat:Material)
	{
		body.space = null;
		var polygon:Polygon;
		for (index in tileIndices)
		{
			var coords:Array<FlxPoint> = getTileCoords(index, false);
			if (coords == null)
				continue;

			for (point in coords)
			{
				polygon = new Polygon(vertices, mat);
				polygon.translate(Vec2.get(point.x, point.y));
				body.shapes.add(polygon);
			}
		}

		body.space = FlxNapeSpace.space;
	}

	/**
	 * Builds the nape collider with all tiles indices greater or equal to CollideIndex
	 * as solid (like normally with FlxTilemap), and assigns the nape material
	 *
	 * @param	CollideIndex	All tiles with an index greater or equal to this will be solid
	 * @param	mat				The Nape physics material to use. Will use the default material if not specified
	 */
	public function setupCollideIndex(CollideIndex:Int = 1, ?mat:Material)
	{
		if (_data == null)
		{
			FlxG.log.error("loadMap has to be called first!");
			return;
		}
		var tileIndex = 0;
		// Iterate through the tilemap and convert it to a binary map, marking if a tile is solid (1) or not (0)
		for (y in 0...heightInTiles)
		{
			for (x in 0...widthInTiles)
			{
				tileIndex = x + (y * widthInTiles);
				_binaryData[tileIndex] = if (_data[tileIndex] >= CollideIndex) 1 else 0;
			}
		}
		constructCollider(mat);
	}

	/**
	 * Builds the nape collider with all indices in the array as solid, assigning the material
	 *
	 * @param	tileIndices		An array of all tile indices that should be solid
	 * @param	mat				The nape physics material applied to the collider. Defaults to nape default material
	 */
	public function setupTileIndices(tileIndices:Array<Int>, ?mat:Material)
	{
		if (_data == null)
		{
			FlxG.log.error("loadMap has to be called first!");
			return;
		}
		var tileIndex = 0;
		for (y in 0...heightInTiles)
		{
			for (x in 0...widthInTiles)
			{
				tileIndex = x + (y * widthInTiles);
				_binaryData[tileIndex] = if (Lambda.has(tileIndices, _data[tileIndex])) 1 else 0;
			}
		}
		constructCollider(mat);
	}

	#if FLX_DEBUG
	override public function drawDebug():Void
	{
		if (!FlxNapeSpace.drawDebug)
			super.drawDebug();
	}
	#end

	function constructCollider(?mat:Material)
	{
		if (mat == null)
		{
			mat = new Material();
		}
		var tileIndex = 0;
		var startRow = -1;
		var endRow = -1;
		var rects = new Array<FlxRect>();

		// Go over every column, then scan along them
		for (x in 0...widthInTiles)
		{
			for (y in 0...heightInTiles)
			{
				tileIndex = x + (y * widthInTiles);
				// Is that tile solid?
				if (_binaryData[tileIndex] == 1)
				{
					// Mark the beginning of a new rectangle
					if (startRow == -1)
						startRow = y;

					// Mark the tile as already read
					_binaryData[tileIndex] = -1;
				}
				// Is the tile not solid or already read
				else if (_binaryData[tileIndex] == 0 || _binaryData[tileIndex] == -1)
				{
					// If we marked the beginning a rectangle, end it and process it
					if (startRow != -1)
					{
						endRow = y - 1;
						rects.push(constructRectangle(x, startRow, endRow));
						startRow = -1;
						endRow = -1;
					}
				}
			}
			// If we reached the last line and marked the beginning of a rectangle, end it and process it
			if (startRow != -1)
			{
				endRow = heightInTiles - 1;
				rects.push(constructRectangle(x, startRow, endRow));
				startRow = -1;
				endRow = -1;
			}
		}

		body.space = null;
		// Convert the rectangles to nape polygons
		var vertices:Array<Vec2>;
		for (rect in rects)
		{
			vertices = new Array<Vec2>();
			rect.x *= tileWidth;
			rect.y *= tileHeight;
			rect.width++;
			rect.width *= tileWidth;
			rect.height++;
			rect.height *= tileHeight;

			vertices.push(Vec2.get(rect.x, rect.y));
			vertices.push(Vec2.get(rect.width, rect.y));
			vertices.push(Vec2.get(rect.width, rect.height));
			vertices.push(Vec2.get(rect.x, rect.height));
			body.shapes.add(new Polygon(vertices, mat));
			rect.put();
		}

		body.space = FlxNapeSpace.space;
	}

	/**
	 * Scans along x in the rows between StartY to EndY for the biggest rectangle covering solid tiles in the binary data
	 *
	 * @param	StartX	The column in which the rectangle starts
	 * @param	StartY	The row in which the rectangle starts
	 * @param	EndY	The row in which the rectangle ends
	 * @return			The rectangle covering solid tiles. CAUTION: Width is used as bottom-right x coordinate, height is used as bottom-right y coordinate
	 */
	function constructRectangle(StartX:Int, StartY:Int, EndY:Int):FlxRect
	{
		// Increase StartX by one to skip the first column, we checked that one already
		StartX++;
		var rectFinished = false;
		var tileIndex = 0;
		// go along the columns from StartX onwards, then scan along those columns in the range of StartY to EndY
		for (x in StartX...widthInTiles)
		{
			for (y in StartY...(EndY + 1))
			{
				tileIndex = x + (y * widthInTiles);
				// If the range includes a non-solid tile or a tile already read, the rectangle is finished
				if (_binaryData[tileIndex] == 0 || _binaryData[tileIndex] == -1)
				{
					rectFinished = true;
					break;
				}
			}
			if (rectFinished)
			{
				// If the rectangle is finished, fill the area covered with -1 (tiles have been read)
				for (u in StartX...x)
				{
					for (v in StartY...(EndY + 1))
					{
						tileIndex = u + (v * widthInTiles);
						_binaryData[tileIndex] = -1;
					}
				}
				// StartX - 1 to counteract the increment in the beginning
				// Slight misuse of Rectangle here, width and height are used as x/y of the bottom right corner
				return FlxRect.get(StartX - 1, StartY, x - 1, EndY);
			}
		}
		// We reached the end of the map without finding a non-solid/alread-read tile, finalize the rectangle with the map's right border as the endX
		for (u in StartX...widthInTiles)
		{
			for (v in StartY...(EndY + 1))
			{
				tileIndex = u + (v * widthInTiles);
				_binaryData[tileIndex] = -1;
			}
		}
		return FlxRect.get(StartX - 1, StartY, widthInTiles - 1, EndY);
	}
}
