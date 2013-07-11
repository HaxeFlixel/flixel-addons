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
	public var x:Int;
	public var y:Int;
	public var width:Int;
	public var height:Int;
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
		x = (Source.has.x) ? Std.parseInt(Source.att.x) : 0;
		y = (Source.has.y) ? Std.parseInt(Source.att.y) : 0;
		width = Std.parseInt(Source.att.width);
		height = Std.parseInt(Source.att.height);
		visible = (Source.has.visible && Source.att.visible == "1") ? true : false;
		opacity = (Source.has.opacity) ? Std.parseFloat(Source.att.opacity) : 0;
		
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
