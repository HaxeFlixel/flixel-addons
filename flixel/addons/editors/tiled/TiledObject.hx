package flixel.addons.editors.tiled;

import haxe.xml.Fast;
import flixel.util.FlxPoint;

/**
 * Last modified 10/3/2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledObject
{
	/**
	 * Use these to determine whether a sprite should be flipped, for example:
	 * 
	 * var flipped:Bool = cast (oject.gid & TiledObject.FLIPPED_HORIZONTALLY_FLAG);
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
	 */
	public var custom:TiledPropertySet;
	/** 
	 * Shared properties are tileset properties added on object tile
	 */ 
	public var shared:TiledPropertySet;
	/**
	 * Information on the group or "Layer" that contains this object
	 */
	public var group:TiledObjectGroup;
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
	
	public function new(Source:Fast, Parent:TiledObjectGroup)
	{
		xmlData = Source;
		group = Parent;
		name = (Source.has.name) ? Source.att.name : "[object]";
		type = (Source.has.type) ? Source.att.type : Parent.name;
		x = Std.parseInt(Source.att.x);
		y = Std.parseInt(Source.att.y);
		width = (Source.has.width) ? Std.parseInt(Source.att.width) : 0;
		height = (Source.has.height) ? Std.parseInt(Source.att.height) : 0;
		angle = (Source.has.rotation) ? Std.parseFloat(Source.att.rotation) : 0;
		// By default let's it be a rectangle object
		objectType = RECTANGLE;
		
		// resolve inheritence
		shared = null;
		gid = -1;
		
		// object with tile association?
		if (Source.has.gid && Source.att.gid.length != 0) 
		{
			gid = Std.parseInt(Source.att.gid);
			var set:TiledTileSet;
			
			for (set in group.map.tilesets)
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
		custom = new TiledPropertySet();
		
		for (node in Source.nodes.properties)
		{
			custom.extend(node);
		}
		
		// Let's see if it's another object
		if (Source.hasNode.ellipse) {
			objectType = ELLIPSE;
		} else if (Source.hasNode.polygon) {
			objectType = POLYGON;
			getPoints(Source.node.polygon);
		} else if (Source.hasNode.polyline) {
			objectType = POLYLINE;
			getPoints(Source.node.polyline);
		}
	}
	
	private function getPoints(Node:Fast):Void {
		points = new Array<FlxPoint>();
		
		var pointsStr:Array<String> = Node.att.points.split(" ");
		var pair:Array<String>;
		for (p in pointsStr) {
			pair = p.split(",");
			points.push(new FlxPoint(Std.parseFloat(pair[0]), Std.parseFloat(pair[1])));
		}
	}
	
	/**
	 * Property accessors
	 */
	public function get_flippedHorizontally():Bool
	{
		return cast (gid & FLIPPED_HORIZONTALLY_FLAG);
	}
	public function get_flippedVertically():Bool
	{
		return cast (gid & FLIPPED_VERTICALLY_FLAG);
	}
}
