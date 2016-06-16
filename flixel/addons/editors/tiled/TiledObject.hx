package flixel.addons.editors.tiled;

import haxe.xml.Fast;
import flixel.math.FlxPoint;

/**
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledObject
{
	/**
	 * Use these to determine whether a sprite should be flipped, for example:
	 * 
	 * var flipped:Bool = (oject.gid & TiledObject.FLIPPED_HORIZONTALLY_FLAG) > 0;
	 * sprite.facing = flipped ? FlxObject.LEFT : FlxObject.RIGHT;
	 */
	public static inline var FLIPPED_VERTICALLY_FLAG = 0x40000000;
	public static inline var FLIPPED_HORIZONTALLY_FLAG = 0x80000000;
	
	public static inline var RECTANGLE = 0;
	public static inline var ELLIPSE = 1;
	public static inline var POLYGON = 2;
	public static inline var POLYLINE = 3;
	public static inline var TILE = 4;
	
	public var x:Int;
	public var y:Int;
	public var width:Int;
	public var height:Int;
	public var name:String;
	public var type:String;
	public var xmlData:Fast;
	/** 
	 * In degrees
	 */
	public var angle:Float;
	/**
	 * Global identifier for this object
	 */
	public var gid:Int;
	/**
	 * Custom properties that users can set on this object
	 * If "type" is not defined, the parent layer's "defaultType" is used
	 */
	public var properties:TiledPropertySet;
	/** 
	 * Shared properties are tileset properties added on object tile
	 */ 
	public var shared:TiledPropertySet;
	/**
	 * Information on the layer that contains this object
	 */
	public var layer:TiledObjectLayer;
	/**
	 * The type of the object (RECTANGLE, ELLIPSE, POLYGON, POLYLINE, TILE)
	 */
	public var objectType(default, null):Int;
	/**
	 * Whether the object is flipped horizontally.
	 */
	public var flippedHorizontally(get, null):Bool;
	/**
	 * Whether the object is flipped vertically.
	 */
	public var flippedVertically(get, null):Bool;
	/**
	 * An array with points if the object is a POLYGON or POLYLINE
	 */
	public var points:Array<FlxPoint>;
	
	public function new(source:Fast, parent:TiledObjectLayer)
	{
		xmlData = source;
		layer = parent;
		name = (source.has.name) ? source.att.name : "";
		type = (source.has.type) ? source.att.type :
		        (parent.properties.contains("defaultType") ? parent.properties.get("defaultType") : "");
		x = Std.parseInt(source.att.x);
		y = Std.parseInt(source.att.y);
		width = (source.has.width) ? Std.parseInt(source.att.width) : 0;
		height = (source.has.height) ? Std.parseInt(source.att.height) : 0;
		angle = (source.has.rotation) ? Std.parseFloat(source.att.rotation) : 0;
		// By default let's it be a rectangle object
		objectType = RECTANGLE;
		
		// resolve inheritence
		shared = null;
		gid = -1;
		
		// object with tile association?
		if (source.has.gid && source.att.gid.length != 0) 
		{
			gid = Std.parseInt(source.att.gid);
			var set:TiledTileSet;
			
			for (set in layer.map.tilesets)
			{
				shared = set.getPropertiesByGid(gid);
				
				if (shared != null)
				{
					break;
				}
			}
			// If there is a gid it means that it's a tile object
			objectType = TILE;
		}
		
		// load properties
		var node:Xml;
		properties = new TiledPropertySet();
		
		for (node in source.nodes.properties)
		{
			properties.extend(node);
		}
		
		// Let's see if it's another object
		if (source.hasNode.ellipse)
		{
			objectType = ELLIPSE;
		}
		else if (source.hasNode.polygon)
		{
			objectType = POLYGON;
			getPoints(source.node.polygon);
		}
		else if (source.hasNode.polyline)
		{
			objectType = POLYLINE;
			getPoints(source.node.polyline);
		}
	}
	
	private function getPoints(node:Fast):Void
	{
		points = new Array<FlxPoint>();
		
		var pointsStr:Array<String> = node.att.points.split(" ");
		var pair:Array<String>;
		for (p in pointsStr)
		{
			pair = p.split(",");
			points.push(FlxPoint.get(Std.parseFloat(pair[0]), Std.parseFloat(pair[1])));
		}
	}

	private inline function get_flippedHorizontally():Bool
	{
		return (gid & FLIPPED_HORIZONTALLY_FLAG) > 0;
	}

	private inline function get_flippedVertically():Bool
	{
		return (gid & FLIPPED_VERTICALLY_FLAG) > 0;
	}
}
