package flixel.addons.editors.tiled;

import flixel.util.FlxPoint;
import haxe.xml.Fast;

/**
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledObject
{
	public static inline var RECTANGLE = 0;
	public static inline var ELLIPSE = 1;
	public static inline var POLYGON = 2;
	public static inline var POLYLINE = 3;
	public static inline var TILE = 4;
	
	public var group:TiledObjectGroup;
	public var xmlData:Fast;
	public var name:String;
	public var type:String;
	public var x:Int;
	public var y:Int;
	public var width:Int;
	public var height:Int;
	/** 
	 * In degrees
	 */ 
	public var angle:Float; 
	public var gid:Int;
	public var custom:TiledPropertySet;
	/** 
	 * Shared properties are tileset properties added on object tile
	 */ 
	public var shared:TiledPropertySet; 
	
	/**
	 * The type of the object (RECTANGLE, ELLIPSE, POLYGON, POLYLINE, TILE)
	 */
	public var objectType(default, null):Int;
	
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
}
