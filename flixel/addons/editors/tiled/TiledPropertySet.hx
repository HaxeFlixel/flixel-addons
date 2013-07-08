/*******************************************************************************
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 ******************************************************************************/
package flixel.addons.editors.tiled;

import haxe.xml.Fast;

class TiledPropertySet implements Dynamic<String>
{
	
	public function new()
	{
		keys = new Map<String, String>();
	}
	
	public inline function get(key:String):String 
	{
		return resolve(key);
	}
	public inline function contains(key:String):Bool
	{
		return keys.exists(key);
	}
	
	public inline function resolve(name:String):String
	{
		return keys.get(name);
	}
	
	public inline function keysIterator():Iterator<String>
	{
		return keys.keys();
	}
	
	public function extend(source:Fast)
	{
		var prop:Fast;
		for (prop in source.nodes.property)
		{
			keys.set(prop.att.name, prop.att.value);
		}
	}
	
	public var keys:Map<String, String>;
}