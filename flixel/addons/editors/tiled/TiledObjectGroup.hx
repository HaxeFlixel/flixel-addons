package flixel.addons.editors.tiled;

import haxe.xml.Fast;

/**
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledObjectGroup
{
	public var map:TiledMap;
	public var name:String;
	public var color:Int;
	public var opacity:Float;
	public var visible:Bool;
	public var properties:TiledPropertySet;
	public var objects:Array<TiledObject>;
	
	public function new(Source:Fast, Parent:TiledMap)
	{
		properties = new TiledPropertySet();
		objects = new Array<TiledObject>();
		
		map = Parent;
		name = Source.att.name;
		visible = (Source.has.visible && Source.att.visible == "1") ? true : false;
		opacity = (Source.has.opacity) ? Std.parseFloat(Source.att.opacity) : 0;
		if (Source.has.color)
		{
			var hex = Source.att.color;
			hex = "0x" + hex.substring(1, hex.length); // replace # with 0x
			color = Std.parseInt(hex);
		}
		else
			color = 0;
		
		// load properties
		var node:Fast;
		
		for (node in Source.nodes.properties)
		{
			properties.extend(node);
		}
		
		// load objects
		for (node in Source.nodes.object)
		{
			objects.push(new TiledObject(node, this));
		}
	}
}
