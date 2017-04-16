package flixel.addons.editors.tiled;

import haxe.Int64;
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
	 * var flipped:Bool = (object.gid & TiledObject.FLIPPED_HORIZONTALLY_FLAG) > 0;
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
	public var flippedHorizontally(default, null):Bool;
	/**
	 * Whether the object is flipped vertically.
	 */
	public var flippedVertically(default, null):Bool;
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
		
		// resolve inheritance
		shared = null;
		gid = -1;
		
		// object with tile association?
		if (source.has.gid && source.att.gid.length != 0)
		{
			var gid64 = parseString(source.att.gid);
			
			flippedHorizontally = (gid64 & FLIPPED_HORIZONTALLY_FLAG) > 0;
			flippedVertically = (gid64 & FLIPPED_VERTICALLY_FLAG) > 0;
			gid64 &= ~(FLIPPED_HORIZONTALLY_FLAG | FLIPPED_VERTICALLY_FLAG);
			gid = gid64.low;
			
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
			points.push(new FlxPoint(Std.parseFloat(pair[0]), Std.parseFloat(pair[1])));
		}
	}

	/**
	 * This is a copy of Haxe 3.4's `IntHelper.parseString()`.
	 * Copied for backwards-compatibility with Haxe 3.2.x.
	 */
	private function parseString(sParam:String):Int64
	{
		var base = Int64.ofInt(10);
		var current = Int64.ofInt(0);
		var multiplier = Int64.ofInt(1);
		var sIsNegative = false;

		var s = StringTools.trim(sParam);
		if (s.charAt(0) == "-")
		{
			sIsNegative = true;
			s = s.substring(1, s.length);
		}
		var len = s.length;

		for (i in 0...len)
		{
			var digitInt = s.charCodeAt(len - 1 - i) - '0'.code;

			if (digitInt < 0 || digitInt > 9)
				throw "NumberFormatError";

			var digit:Int64 = Int64.ofInt(digitInt);
			if (sIsNegative) {
				current = Int64.sub(current, Int64.mul(multiplier, digit));
				if (!Int64.isNeg(current))
					throw "NumberFormatError: Underflow";
			}
			else
			{
				current = Int64.add(current, Int64.mul(multiplier, digit));
				if (Int64.isNeg(current))
					throw "NumberFormatError: Overflow";
			}
			multiplier = Int64.mul(multiplier, base);
		}
		return current;
	}
}
