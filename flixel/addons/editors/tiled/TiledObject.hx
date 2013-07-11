package flixel.addons.editors.tiled;

import haxe.xml.Fast;

/**
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledObject
{
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
		}
		
		// load properties
		var node:Xml;
		custom = new TiledPropertySet();
		
		for (node in Source.nodes.properties)
		{
			custom.extend(node);
		}
	}
}