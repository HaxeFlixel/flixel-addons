package flixel.addons.editors.tiled;

#if haxe4
import haxe.xml.Access;
#else
import haxe.xml.Fast as Access;
#end

/**
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledPropertySet #if (haxe_ver < 4) implements Dynamic<String> #end
{
	public var keys:Map<String, String>;
	
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
	
	public function extend(Source:Access)
	{
		for (prop in Source.nodes.property)
		{
			keys.set(prop.att.name, prop.att.value);
		}
	}
}