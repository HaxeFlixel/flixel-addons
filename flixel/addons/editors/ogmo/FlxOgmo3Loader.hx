package flixel.addons.editors.ogmo;

import flixel.math.FlxPoint;
import flixel.group.FlxGroup;
import flixel.FlxG;
import flixel.tile.FlxTilemap;
import flixel.math.FlxRect;
import flixel.math.FlxAngle;
import openfl.Assets;
import haxe.Json;

using flixel.addons.editors.ogmo.FlxOgmo3Loader;
using Math;
using Reflect;

class FlxOgmo3Loader
{
	var project:ProjectData;
	var level:LevelData;

	/**
	 * Creates a new instance of `FlxOgmoLoader` and prepares the XML level data to be loaded.
	 * This object can either be contained or ovewritten.
	 *
	 * IMPORTANT:
	 *  * Tile layers must have the Export Mode set to `"CSV"`.
	 *  * First tile in spritesheet must be blank or debug. It will never get drawn so don't place them in Ogmo!
	 *    (This is needed to support many other editors that use index `0` as empty)
	 *
	 * @param	LevelData	A String or Class representing the location of xml level data.
	 */
	public function new(ProjectData:String, LevelData:String)
	{
		project = Assets.getText(ProjectData).parseProjectJSON();
		level = Assets.getText(LevelData).parseLevelJSON();
	}

	/**
	 * Get a custom value for the loaded level.
	 * Returns `null` if no value is present.
	 */
	public function getLevelValue(Value:String):Dynamic
	{
		return level.field(Value);
	}

	/**
	 * Load a Tilemap. Tile layers must have the Export Mode set to `"CSV"`.
	 * Collision with entities should be handled with the reference returned from this function. Here's a tip:
	 *
	 * IMPORTANT: Tile layers must export using IDs, not Coords!
	 *
	 * @param	TileGraphic		A String or Class representing the location of the image asset for the tilemap.
	 * @param	TileWidth		The width of each individual tile.
	 * @param	TileHeight		The height of each individual tile.
	 * @param	TileLayer		The name of the layer the tilemap data is stored in Ogmo editor, usually `"tiles"` or `"stage"`.
	 * @return	A FlxTilemap, where you can collide your entities against.
	 */
	public function loadTilemap(TileGraphic:Dynamic, TileLayer:String = "tiles"):FlxTilemap
	{
		var tilemap = new FlxTilemap();
		var layer = level.getTileLayer(TileLayer);
		var tileset = project.getTilesetData(layer.tileset);
		switch (layer.arrayMode)
		{
			case 0:
				tilemap.loadMapFromArray(layer.data, layer.gridCellsX, layer.gridCellsY, TileGraphic, tileset.tileWidth, tileset.tileHeight);
			case 1:
				tilemap.loadMapFrom2DArray(layer.data2D, TileGraphic, tileset.tileWidth, tileset.tileHeight);
		}
		return tilemap;
	}

	/**
	 * Loads a Map of FlxPoint arrays from a grid layer. For example:
	 *
	 * ```haxe
	 * var gridData = myOgmoData.loadGridMap('my grid layer');
	 * for (point in gridData['e']) addSpawnPoint(point.x, point.y);
	 * ```
	 */
	public function loadGridMap(GridLayer:String = "grid"):Map<String, Array<FlxPoint>>
	{
		var gridLayer = level.getGridLayer(GridLayer);
		var out:Map<String, Array<FlxPoint>> = new Map();
		switch gridLayer.arrayMode
		{
			case 0:
				for (i in 0...gridLayer.grid.length)
				{
					if (!out.exists(gridLayer.grid[i]))
						out.set(gridLayer.grid[i], []);
					out[gridLayer.grid[i]].push(FlxPoint.get((i % gridLayer.gridCellsX) * gridLayer.gridCellWidth,
						(i / gridLayer.gridCellsX).floor() * gridLayer.gridCellHeight));
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
	 *   switch (entity.name)
	 *   {
	 *     case "player":
	 *       player.x = entity.x;
	 *       player.y = entity.y;
	 *       player.custom_value = entity.values.custom_value;
	 *     default:
	 *       throw 'Unrecognized actor type ${entity.name}';
	 *   }
	 * }
	 * ```
	 *
	 * @param	EntityLoadCallback		A function with the signature `(name:String, data:Xml):Void` and spawns entities based on their name.
	 * @param	EntityLayer				The name of the layer the entities are stored in Ogmo editor. Usually `"entities"` or `"actors"`.
	 */
	public function loadEntities(EntityLoadCallback:EntityData->Void, EntityLayer:String = "entities"):Void
	{
		for (entity in level.getEntityLayer(EntityLayer).entities)
			EntityLoadCallback(entity);
	}

	/**
	 * Loads every decal in a decal layer into a FlxGroup.
	 *
	 * IMPORTANT: All decals must be included in one directory!
	 *
	 * @param DecalLayer	The name of the layer the decals are stored in Ogmo editor. Usually `"decals"`.
	 * @param decalsPath 	The path to the directory in which your decal assets are stored.
	 */
	public function loadDecals(DecalLayer:String = 'decals', decalsPath:String):FlxGroup
	{
		if (!StringTools.endsWith('/'))
			decalsPath += '/';
		var g = new FlxGroup();
		for (decal in level.getDecalLayer(DecalLayer).decals)
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
	levelDefaultSize:
	{
			x:Int, y:Int
	},
	levelMinSize:
	{
			x:Int, y:Int
	},
	levelMaxSize:
	{
			x:Int, y:Int
	},
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
	gridSize:
	{
			x:Int, y:Int
	},
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
	size:
	{
			x:Int, y:Int
	},
	origin:
	{
			x:Int, y:Int
	},
	originAnchored:Bool,
	shape:
	{
			label:String, points:Array<{x:Int, y:Int}>
	},
	color:String,
	tileX:Bool,
	tileY:Bool,
	tileSize:
	{
			x:Int, y:Int
	},
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
	?data2D:Array<Array<Int>>,
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
