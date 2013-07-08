/*******************************************************************************
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 ******************************************************************************/
package flixel.addons.tmx;

import haxe.xml.Fast;

class TmxObject
{
	public var group:TmxObjectGroup;
	public var xmlData:Fast;
	public var name:String;
	public var type:String;
	public var x:Int;
	public var y:Int;
	public var width:Int;
	public var height:Int;
	public var angle:Float; // in degrees
	public var gid:Int;
	public var custom:TmxPropertySet;
	public var shared:TmxPropertySet; // shared properties are tileset properties added on object tile
	
	public function new(source:Fast, parent:TmxObjectGroup)
	{
		xmlData = source;
		group = parent;
		name = (source.has.name) ? source.att.name : "[object]";
		type = (source.has.type) ? source.att.type : parent.name;
		x = Std.parseInt(source.att.x);
		y = Std.parseInt(source.att.y);
		width = (source.has.width) ? Std.parseInt(source.att.width) : 0;
		height = (source.has.height) ? Std.parseInt(source.att.height) : 0;
		angle = (source.has.rotation) ? Std.parseFloat(source.att.rotation) : 0;
		//resolve inheritence
		shared = null;
		gid = -1;
		if(source.has.gid && source.att.gid.length != 0) //object with tile association?
		{
			gid = Std.parseInt(source.att.gid);
			var set:TmxTileSet;
			for (set in group.map.tilesets)
			{
				shared = set.getPropertiesByGid(gid);
				if(shared != null)
					break;
			}
		}
		
		//load properties
		var node:Xml;
		custom = new TmxPropertySet();
		for (node in source.nodes.properties)
			custom.extend(node);
	}
}
