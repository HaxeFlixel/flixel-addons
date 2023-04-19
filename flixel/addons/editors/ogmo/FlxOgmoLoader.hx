package flixel.addons.editors.ogmo;

import flixel.FlxG;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxTilemapGraphicAsset;
import flixel.tile.FlxTilemap;
import haxe.xml.Parser;
import openfl.Assets;
import haxe.xml.Access;

/**
 * This is for loading maps made with OGMO Editor 2. For loading maps made with OGMO Editor 3, use `FlxOgmo3Loader`
 */
class FlxOgmoLoader
{
	public var width:Int;
	public var height:Int;

	// Helper variables to read level data
	var _xml:Xml;
	var _fastXml:Access;

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
	public function new(LevelData:Dynamic)
	{
		// Load xml file
		var str:String = "";

		// Passed embedded resource?
		if ((LevelData is Class))
		{
			str = Type.createInstance(LevelData, []);
		}
		// Passed path to resource?
		else if ((LevelData is String))
		{
			str = Assets.getText(LevelData);
		}

		_xml = Parser.parse(str);
		_fastXml = new Access(_xml.firstElement());

		width = Std.parseInt(_fastXml.att.width);
		height = Std.parseInt(_fastXml.att.height);
	}

	/**
	 * Load a Tilemap. Tile layers must have the Export Mode set to `"CSV"`.
	 * Collision with entities should be handled with the reference returned from this function. Here's a tip:
	 *
	 * IMPORTANT: Always collide the map with objects, not the other way around.
	 * This prevents odd collision errors (collision separation code off by 1 px):
	 *
	 * ```haxe
	 * FlxG.collide(map, obj, notifyCallback);
	 * ```
	 *
	 * @param	TileGraphic		A String or Class representing the location of the image asset for the tilemap.
	 * @param	TileWidth		The width of each individual tile.
	 * @param	TileHeight		The height of each individual tile.
	 * @param	TileLayer		The name of the layer the tilemap data is stored in Ogmo editor, usually `"tiles"` or `"stage"`.
	 * @param	tilemap			(optional) A tilemap to load tilemap data into. If not specified, new `FlxTilemap` instance is created.
	 * @return	A FlxTilemap, where you can collide your entities against.
	 */
	public function loadTilemap(TileGraphic:FlxTilemapGraphicAsset, TileWidth:Int = 16, TileHeight:Int = 16, TileLayer:String = "tiles",
			?tilemap:FlxTilemap):FlxTilemap
	{
		if (tilemap == null)
			tilemap = new FlxTilemap();

		tilemap.loadMapFromCSV(_fastXml.node.resolve(TileLayer).innerData, TileGraphic, TileWidth, TileHeight);
		return tilemap;
	}

	/**
	 * Parse every entity in the specified layer and call a function that will spawn game objects based on their name.
	 * Optional data can be read from the xml object, here's an example that reads the position of an object:
	 *
	 * ```haxe
	 * public function loadEntity(type:String, data:Xml):Void
	 * {
	 *     switch (type.toLowerCase())
	 *     {
	 *         case "player":
	 *             player.x = Std.parseFloat(data.get("x"));
	 *             player.y = Std.parseFloat(data.get("y"));
	 *         default:
	 *             throw 'Unrecognized actor type $type';
	 *     }
	 * }
	 * ```
	 *
	 * @param	EntityLoadCallback		A function with the signature `(name:String, data:Xml):Void` and spawns entities based on their name.
	 * @param	EntityLayer				The name of the layer the entities are stored in Ogmo editor. Usually `"entities"` or `"actors"`.
	 */
	public function loadEntities(EntityLoadCallback:String->Xml->Void, EntityLayer:String = "entities"):Void
	{
		var actors = _fastXml.node.resolve(EntityLayer);

		// Iterate over actors
		for (a in actors.elements)
		{
			EntityLoadCallback(a.name, a.x);
		}
	}

	/**
	 * Parse every 'rect' in the specified layer and call a function to do something based on each rectangle.
	 * Useful for setting up zones or regions in your game that can be filled in procedurally.
	 *
	 * @param	RectLoadCallback	A function that takes in the Rectangle object and returns Void.
	 * @param	RectLayer			The name of the layer which contains 'rect' objects.
	 */
	public function loadRectangles(RectLoadCallback:FlxRect->Void, RectLayer:String = "rectangles"):Void
	{
		var rects = _fastXml.node.resolve(RectLayer);

		for (r in rects.elements)
		{
			RectLoadCallback(FlxRect.get(Std.parseInt(r.x.get("x")), Std.parseInt(r.x.get("y")), Std.parseInt(r.x.get("w")), Std.parseInt(r.x.get("h"))));
		}
	}

	/**
	 * Allows for loading of level properties specified in Ogmo editor.
	 * Useful for getting properties without having to manually edit the FlxOgmoLoader
	 * Returns a String that will need to be parsed
	 *
	 * @param name A string that corresponds to the property to be accessed
	 */
	public inline function getProperty(name:String):String
	{
		return _fastXml.att.resolve(name);
	}
}
