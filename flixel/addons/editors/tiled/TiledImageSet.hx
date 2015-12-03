package flixel.addons.editors.tiled;

import haxe.xml.Fast;

/**
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledImageSet implements Dynamic<String>
{
	public function new()
	{
		keys = new Map<String, String>();
	}
	
	public inline function get(Key:String):String
	{
		return resolve(Key);
	}
	
	public inline function contains(Key:String):Bool
	{
		return keys.exists(Key);
	}
	
	public inline function resolve(Name:String):String
	{
		return keys.get(Name);
	}
	
	public inline function keysIterator():Iterator<String>
	{
		return keys.keys();
	}
	
	public function extend(Source:Fast)
	{
		var prop:Fast;
		
		for (img in Source.nodes.image)
		{
			keys.set("width", img.att.width);
			keys.set("height", img.att.height);
			keys.set("source", img.att.source);
		}
	}
	
	public var keys:Map<String, String>;
	
}