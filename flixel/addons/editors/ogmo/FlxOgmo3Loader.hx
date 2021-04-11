package flixel.addons.editors.ogmo;

import flixel.FlxG;
import flixel.addons.tile.FlxTileSpecial;
import flixel.addons.tile.FlxTilemapExt;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxTilemapGraphicAsset;
import flixel.tile.FlxTilemap;
import flixel.util.FlxArrayUtil;
import haxe.Json;
import openfl.Assets;

using StringTools;
using flixel.addons.editors.ogmo.FlxOgmo3Loader;

/**
 * @since 2.8.0
 */
class FlxOgmo3Loader
{
	var project:ProjectData;
	var level:LevelData;

	/**
	 * Creates a new instance of `FlxOgmo3Loader` and prepares the level and project data to be used in other methods
	 *
	 * @param	projectData	The path to your project data (`.ogmo`).
	 * @param	levelData	The path to your level data (`.json`).
	 */
	public function new(projectData:String, levelData:String)
	{
		project = Assets.getText(projectData).parseProjectJSON();
		level = Assets.getText(levelData).parseLevelJSON();
	}

	/**
	 * Get a custom value for the loaded level.
	 * Returns `null` if no value is present.
	 */
	public function getLevelValue(value:String):Dynamic
	{
		return Reflect.field(level, value);
	}

	/**
	 * Load a Tilemap.
	 * Collision with entities should be handled with the reference returned from this function.
	 *
	 * IMPORTANT: Tile layers must export using IDs, not Coords!
	 *
	 * @param	tileGraphic		A String or Class representing the location of the image asset for the tilemap.
	 * @param	tileLayer		The name of the layer the tilemap data is stored in Ogmo editor, usually `"tiles"` or `"stage"`.
	 * @param	tilemap			(optional) A tilemap to load tilemap data into. If not specified, new `FlxTilemap` instance is created.
	 * @return	A `FlxTilemap`, where you can collide your entities against.
	 */
	public function loadTilemap(tileGraphic:FlxTilemapGraphicAsset, tileLayer:String = "tiles", ?tilemap:FlxTilemap):FlxTilemap
	{
		if (tilemap == null)
			tilemap = new FlxTilemap();

		var layer = level.getTileLayer(tileLayer);
		var tileset = project.getTilesetData(layer.tileset);
		switch (layer.arrayMode)
		{
			case 0:
				tilemap.loadMapFromArray(layer.data, layer.gridCellsX, layer.gridCellsY, tileGraphic, tileset.tileWidth, tileset.tileHeight);
			case 1:
				tilemap.loadMapFrom2DArray(layer.data2D, tileGraphic, tileset.tileWidth, tileset.tileHeight);
		}
		return tilemap;
	}

	/**
	 * Load a `FlxTilemapExt`, which supports additional features such as flipped and rotated tiles.
	 * Collision with entities should be handled with the reference returned from this function.
	 *
	 * IMPORTANT: Tile layers must export using IDs, not Coords!
	 *
	 * @param	tileGraphic		A String or Class representing the location of the image asset for the tilemap.
	 * @param	tileLayer		The name of the layer the tilemap data is stored in Ogmo editor, usually `"tiles"` or `"stage"`.
	 * @param	tilemap			(optional) A tilemap to load tilemap data into. If not specified, new `FlxTilemapExt` instance is created.
	 * @return	A `FlxTilemapExt`, where you can collide your entities against.
	 * 
	 * @since 2.10.0
	 */
	public function loadTilemapExt(tileGraphic:FlxTilemapGraphicAsset, tileLayer:String = "tiles", ?tilemap:FlxTilemapExt):FlxTilemapExt
	{
		if (tilemap == null)
			tilemap = new FlxTilemapExt();

		var layer = level.getTileLayer(tileLayer);
		var tileset = project.getTilesetData(layer.tileset);
		switch (layer.arrayMode)
		{
			case 0:
				tilemap.loadMapFromArray(layer.data, layer.gridCellsX, layer.gridCellsY, tileGraphic, tileset.tileWidth, tileset.tileHeight);
				if (layer.tileFlags != null)
				{
					applyFlagsToTilemapExt(layer.tileFlags, tilemap);
				}

			case 1:
				tilemap.loadMapFrom2DArray(layer.data2D, tileGraphic, tileset.tileWidth, tileset.tileHeight);
				if (layer.tileFlags2D != null)
				{
					applyFlagsToTilemapExt(FlxArrayUtil.flatten2DArray(layer.tileFlags2D), tilemap);
				}
		}
		return tilemap;
	}

	/**
	 * Loads a Map of `FlxPoint` arrays from a grid layer. For example:
	 *
	 * ```haxe
	 * var gridData = myOgmoData.loadGridMap('my grid layer');
	 * for (point in gridData['e'])
	 *     addSpawnPoint(point.x, point.y);
	 * ```
	 */
	public function loadGridMap(gridLayer:String = "grid"):Map<String, Array<FlxPoint>>
	{
		var gridLayer = level.getGridLayer(gridLayer);
		var out = new Map<String, Array<FlxPoint>>();
		switch (gridLayer.arrayMode)
		{
			case 0:
				for (i in 0...gridLayer.grid.length)
				{
					if (!out.exists(gridLayer.grid[i]))
						out.set(gridLayer.grid[i], []);
					out[gridLayer.grid[i]].push(FlxPoint.get((i % gridLayer.gridCellsX) * gridLayer.gridCellWidth,
						Math.floor(i / gridLayer.gridCellsX) * gridLayer.gridCellHeight));
				}
			case 1:
				for (j in 0...gridLayer.grid2D.length)
					for (i in 0...gridLayer.grid2D[j].length)
					{
						if (!out.exists(gridLayer.grid2D[j][i]))
							out.set(gridLayer.grid2D[j][i], []);
						out[gridLayer.grid2D[j][i]].push(FlxPoint.get(i * gridLayer.gridCellWidth, j * gridLayer.gridCellHeight));
					}
		}
		return out;
	}

	/**
	 * Parse every entity in the specified layer and call a function that will spawn game objects based on its entity data.
	 * Here's an example that reads the position of an object:
	 *
	 * ```haxe
	 * function loadEntity(entity:EntityData)
	 * {
	 *     switch (entity.name)
	 *     {
	 *         case "player":
	 *             player.x = entity.x;
	 *             player.y = entity.y;
	 *             player.custom_value = entity.values.custom_value;
	 *         default:
	 *             throw 'Unrecognized actor type ${entity.name}';
	 *     }
	 * }
	 * ```
	 *
	 * @param	entityLoadCallback		A function with the signature `(name:String, data:Xml):Void` and spawns entities based on their name.
	 * @param	entityLayer				The name of the layer the entities are stored in Ogmo editor. Usually `"entities"` or `"actors"`.
	 */
	public function loadEntities(entityLoadCallback:EntityData->Void, entityLayer:String = "entities"):Void
	{
		for (entity in level.getEntityLayer(entityLayer).entities)
			entityLoadCallback(entity);
	}

	/**
	 * Loads every decal in a decal layer into a FlxGroup.
	 *
	 * IMPORTANT: All decals must be included in one directory!
	 *
	 * @param decalLayer	The name of the layer the decals are stored in Ogmo editor. Usually `"decals"`.
	 * @param decalsPath	The path to the directory in which your decal assets are stored.
	 */
	public function loadDecals(decalLayer:String = 'decals', decalsPath:String):FlxGroup
	{
		if (!decalsPath.endsWith('/'))
			decalsPath += '/';
		var g = new FlxGroup();
		for (decal in level.getDecalLayer(decalLayer).decals)
		{
			var s = new FlxSprite(decal.x, decal.y, decalsPath + decal.texture);
			s.offset.set(s.width / 2, s.height / 2);
			if (decal.scaleX != null)
				s.scale.x = decal.scaleX;
			if (decal.scaleY != null)
				s.scale.y = decal.scaleY;
			if (decal.rotation != null)
				s.angle = project.anglesRadians ? FlxAngle.asDegrees(decal.rotation) : decal.rotation;
			g.add(s);
		}
		return g;
	}

	/**
	 * Parse OGMO Editor level .json text
	 */
	static function parseLevelJSON(json:String):LevelData
	{
		return cast Json.parse(json);
	}

	/**
	 * Parse OGMO Editor Project .ogmo text
	 */
	static function parseProjectJSON(json:String):ProjectData
	{
		return cast Json.parse(json);
	}

	/**
	 * Get Tile Layer data matching a given name
	 */
	static function getTileLayer(data:LevelData, name:String):TileLayer
	{
		for (layer in data.layers)
			if (layer.name == name)
				return cast layer;
		return null;
	}

	/**
	 * Get Grid Layer data matching a given name
	 */
	static function getGridLayer(data:LevelData, name:String):GridLayer
	{
		for (layer in data.layers)
			if (layer.name == name)
				return cast layer;
		return null;
	}

	/**
	 * Get Entity Layer data matching a given name
	 */
	static function getEntityLayer(data:LevelData, name:String):EntityLayer
	{
		for (layer in data.layers)
			if (layer.name == name)
				return cast layer;
		return null;
	}

	/**
	 * Get Decal Layer data matching a given name
	 */
	static function getDecalLayer(data:LevelData, name:String):DecalLayer
	{
		for (layer in data.layers)
			if (layer.name == name)
				return cast layer;
		return null;
	}

	/**
	 * Get matching Tileset data from a given name
	 */
	static function getTilesetData(data:ProjectData, name:String):ProjectTilesetData
	{
		for (tileset in data.tilesets)
			if (tileset.label == name)
				return tileset;
		return null;
	}

	/**
	 * Apply flags for flipping and rotating tiles to a FlxTilemapExt
	 */
	static function applyFlagsToTilemapExt(tileFlags:Array<Int>, tilemap:FlxTilemapExt)
	{
		var specialTiles = new Array<FlxTileSpecial>();

		for (i in 0...tileFlags.length)
		{
			var flag = tileFlags[i];
			var specialTile = new FlxTileSpecial(tilemap.getTileByIndex(i), false, false, 0);

			if (flag & 4 > 0)
				specialTile.flipX = true;
			if (flag & 2 > 0)
				specialTile.flipY = true;
			if (flag & 1 > 0)
			{
				if (specialTile.flipY)
				{
					specialTile.flipY = false;
					specialTile.rotate = FlxTileSpecial.ROTATE_270;
				}
				else
				{
					specialTile.flipX = !specialTile.flipX;
					specialTile.rotate = FlxTileSpecial.ROTATE_90;
				}
			}
			specialTiles.push(specialTile);
		}
		tilemap.setSpecialTiles(specialTiles);
	}
}

/**
 * Parsed .OGMO Project data
 */
typedef ProjectData =
{
	name:String,
	levelPaths:Array<String>,
	backgroundColor:String,
	gridColor:String,
	anglesRadians:Bool,
	directoryDepth:Int,
	levelDefaultSize:Point,
	levelMinSize:Point,
	levelMaxSize:Point,
	levelVaues:Array<Dynamic>,
	defaultExportMode:String,
	entityTags:Array<String>,
	layers:Array<ProjectLayerData>,
	entities:Array<ProjectEntityData>,
	tilesets:Array<ProjectTilesetData>,
}

/**
 * Project Layer
 */
typedef ProjectLayerData =
{
	definition:String,
	name:String,
	gridSize:Point,
	exportID:String,
	?requiredTags:Array<String>,
	?excludedTags:Array<String>,
	?exportMode:Int,
	?arrayMode:Int,
	?defaultTileset:String,
	?folder:String,
	?includeImageSequence:Bool,
	?scaleable:Bool,
	?rotatable:Bool,
	?values:Array<Dynamic>,
	?legend:Dynamic,
}

/**
 * Project Entity
 */
typedef ProjectEntityData =
{
	exportID:String,
	name:String,
	limit:Int,
	size:Point,
	origin:Point,
	originAnchored:Bool,
	shape:
	{
		label:String, points:Array<Point>
	},
	color:String,
	tileX:Bool,
	tileY:Bool,
	tileSize:Point,
	resizeableX:Bool,
	resizeableY:Bool,
	rotatable:Bool,
	rotationDegrees:Int,
	canFlipX:Bool,
	canFlipY:Bool,
	canSetColor:Bool,
	hasNodes:Bool,
	nodeLimit:Int,
	nodeDisplay:Int,
	nodeGhost:Bool,
	tags:Array<String>,
	values:Array<Dynamic>,
}

/**
 * Project Tileset
 */
typedef ProjectTilesetData =
{
	label:String,
	path:String,
	image:String,
	tileWidth:Int,
	tileHeight:Int,
	tileSeparationX:Int,
	tileSeparationY:Int,
}

/**
 * Parsed .JSON Level data
 */
typedef LevelData =
{
	width:Int,
	height:Int,
	offsetX:Int,
	offsetY:Int,
	layers:Array<LayerData>,
	?values:Dynamic,
}

/**
 * Level Layer data
 */
typedef LayerData =
{
	name:String,
	_eid:String,
	offsetX:Int,
	offsetY:Int,
	gridCellWidth:Int,
	gridCellHeight:Int,
	gridCellsX:Int,
	gridCellsY:Int,
	?entities:Array<EntityData>,
	?decals:Array<DecalData>,
	?tileset:String,
	?data:Array<Int>,
	?data2D:Array<Array<Int>>,
	?dataCSV:String,
	?exportMode:Int,
	?arrayMode:Int,
}

/**
 * Tile subset of LayerData
 */
typedef TileLayer =
{
	name:String,
	_eid:String,
	offsetX:Int,
	offsetY:Int,
	gridCellWidth:Int,
	gridCellHeight:Int,
	gridCellsX:Int,
	gridCellsY:Int,
	tileset:String,
	exportMode:Int,
	arrayMode:Int,
	?data:Array<Int>,
	?tileFlags:Array<Int>,
	?data2D:Array<Array<Int>>,
	?tileFlags2D:Array<Array<Int>>,
	?dataCSV:String,
	?dataCoords:Array<Array<Int>>,
	?dataCoords2D:Array<Array<Array<Int>>>,
}

/**
 * Grid subset of LayerData
 */
typedef GridLayer =
{
	name:String,
	_eid:String,
	offsetX:Int,
	offsetY:Int,
	gridCellWidth:Int,
	gridCellHeight:Int,
	gridCellsX:Int,
	gridCellsY:Int,
	arrayMode:Int,
	?grid:Array<String>,
	?grid2D:Array<Array<String>>,
}

/**
 * Entity subset of LayerData
 */
typedef EntityLayer =
{
	name:String,
	_eid:String,
	offsetX:Int,
	offsetY:Int,
	gridCellWidth:Int,
	gridCellHeight:Int,
	gridCellsX:Int,
	gridCellsY:Int,
	entities:Array<EntityData>,
}

/**
 * Individual Entity data
 */
typedef EntityData =
{
	name:String,
	id:Int,
	_eid:String,
	x:Int,
	y:Int,
	?width:Int,
	?height:Int,
	?originX:Int,
	?originY:Int,
	?rotation:Float,
	?flippedX:Bool,
	?flippedY:Bool,
	?nodes:Array<{x:Float, y:Float}>,
	?values:Dynamic,
}

/**
 * Decal subset of LayerData
 */
typedef DecalLayer =
{
	name:String,
	_eid:String,
	offsetX:Int,
	offsetY:Int,
	gridCellWidth:Int,
	gridCellHeight:Int,
	gridCellsX:Int,
	gridCellsY:Int,
	decals:Array<DecalData>,
}

/**
 * Individual Decal data
 */
typedef DecalData =
{
	x:Int,
	y:Int,
	texture:String,
	?scaleX:Float,
	?scaleY:Float,
	?rotation:Float,
}

typedef Point =
{
	x:Int,
	y:Int
}
