package flixel.addons.editors.tiled;

import haxe.xml.Fast;

/**
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledPropertySet implements Dynamic<String>
{
	public function new()
	{
		keys = new Map<String, String>();
	}
	
	inline public function get(Key:String):String 
	{
		return resolve(Key);
	}
	
	inline public function contains(Key:String):Bool
	{
		return keys.exists(Key);
	}
	
	inline public function resolve(Name:String):String
	{
		return keys.get(Name);
	}
	
	inline public function keysIterator():Iterator<String>
	{
		return keys.keys();
	}
	
	public function extend(Source:Fast)
	{
		var prop:Fast;
		
		for (prop in Source.nodes.property)
		{
			keys.set(prop.att.name, prop.att.value);
		}
	}
	
	public var keys:Map<String, String>;
}