package flixel.addons.editors.tiled;

import flixel.util.FlxColor;
import openfl.Assets;
import haxe.xml.Fast;

#if cpp
import sys.io.File;
import sys.FileSystem;
#end

/**
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledMap
{
	public var version:String; 
	public var orientation:String;
	
	public var backgroundColor:FlxColor;
	
	public var width:Int;
	public var height:Int; 
	public var tileWidth:Int; 
	public var tileHeight:Int;
	
	public var fullWidth:Int;
	public var fullHeight:Int;
	
	public var properties:TiledPropertySet;
	
	public var tilesets: Map<String, TiledTileSet>;
	
	public var layers:Array<TiledLayer>;
	
	// Add a "noload" property to your Map Properties.
	// Add comma separated values of tilesets, layers, or object names.
	// These will not be loaded.
	private var noLoadHash:Map<String, Bool>;
	private var layerMap:Map<String, TiledLayer>;
	
	public function new(data:Dynamic)
	{
		properties = new TiledPropertySet();
		var source:Fast = null;
		var node:Fast = null;
		
		if (Std.is(data, String)) 
		{
			source = new Fast(Xml.parse(Assets.getText(data)));
		}
		else if (Std.is(data, Xml)) 
		{
			source = new Fast(data);
		}
		else 
		{
			throw "Unknown TMX map format";
		}
		
		source = source.node.map;
		version = (source.att.version != null) ? source.att.version : "unknown";
		orientation = (source.att.orientation != null) ? source.att.orientation : "orthogonal";
		backgroundColor = source.has.backgroundcolor && source.att.backgroundcolor != null ?
			FlxColor.fromString(source.att.backgroundcolor) : FlxColor.TRANSPARENT;
		
		width = Std.parseInt(source.att.width);
		height = Std.parseInt(source.att.height);
		tileWidth = Std.parseInt(source.att.tilewidth);
		tileHeight = Std.parseInt(source.att.tileheight);
		
		// Calculate the entire size
		fullWidth = width * tileWidth;
		fullHeight = height * tileHeight;
		
		noLoadHash = new Map<String, Bool>();
		tilesets = new Map<String, TiledTileSet>();
		layers = new Array<TiledLayer>();
		
		// Load properties
		for (node in source.nodes.properties)
		{
			properties.extend(node);
		}
		
		var noLoadStr = properties.get("noload");
		
		if (noLoadStr != null)
		{
			var regExp = ~/[,;|]/;
			var noLoadArr = regExp.split(noLoadStr);
			
			for (s in noLoadArr)
			{
				noLoadHash.set(StringTools.trim(s), true);
			}
		}
		
		// Load tilesets
		var name:String;
		for (node in source.nodes.tileset)
		{
			name = node.att.name;
			
			if (!noLoadHash.exists(name))
			{
				tilesets.set(name, new TiledTileSet(node));
			}
		}
		
		// Load tile and object layers
		for (el in source.elements)
		{
			if (noLoadHash.exists(el.att.name)) continue;
			if (el.name.toLowerCase() == "layer")
			{
				layers.push(new TiledTileLayer(el, this));
			}
			else if (el.name.toLowerCase() == "objectgroup")
			{
				layers.push(new TiledObjectLayer(el, this));
			}
		}
	}
	
	public function getTileSet(name:String):TiledTileSet
	{
		return tilesets.get(name);
	}
	
	public function getLayer(name:String):TiledLayer
	{	
		return layerMap.get(name);
	}
	
	// works only after TiledTileSet has been initialized with an image...
	public function getGidOwner(gid:Int):TiledTileSet
	{
		var last:TiledTileSet = null;
		var set:TiledTileSet;
		
		for (set in tilesets)
		{
			if (set.hasGid(gid))
			{
				return set;
			}
		}
		
		return null;
	}
}