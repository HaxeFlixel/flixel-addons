/*******************************************************************************
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 ******************************************************************************/
package flixel.addons.editors.tiled;

import haxe.xml.Fast;

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
	
	public function new(source:Fast, parent:TiledMap)
	{
		properties = new TiledPropertySet();
		objects = new Array<TiledObject>();
		
		map = parent;
		name = source.att.name;
		x = (source.has.x) ? Std.parseInt(source.att.x) : 0;
		y = (source.has.y) ? Std.parseInt(source.att.y) : 0;
		width = Std.parseInt(source.att.width);
		height = Std.parseInt(source.att.height);
		visible = (source.has.visible && source.att.visible == "1") ? true : false;
		opacity = (source.has.opacity) ? Std.parseFloat(source.att.opacity) : 0;
		
		//load properties
		var node:Fast;
		for (node in source.nodes.properties)
			properties.extend(node);
			
		//load objects
		for (node in source.nodes.object)
			objects.push(new TiledObject(node, this));
	}

}
