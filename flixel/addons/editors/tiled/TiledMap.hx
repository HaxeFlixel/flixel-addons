package flixel.addons.editors.tiled;

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
	
	public var width:Int;
	public var height:Int; 
	public var tileWidth:Int; 
	public var tileHeight:Int;
	
	public var fullWidth:Int;
	public var fullHeight:Int;
	
	public var properties:TiledPropertySet;
	
	// Add a "noload" property to your Map Properties.
	// Add comma separated values of tilesets, layers, or object names.
	// These will not be loaded.
	private var noLoadHash:Map<String, Bool>;
	
	// Use hash, we don't care about order
	public var tilesets: Map<String, TiledTileSet>;
	// Use array to preserve load order
	public var layers:Array<TiledLayer>;
	public var objectGroups:Array<TiledObjectGroup>;
	
	public function new(Data:Dynamic)
	{
		properties = new TiledPropertySet();
		var source:Fast = null;
		var node:Fast = null;
		
		#if (LOAD_CONFIG_REAL_TIME && !neko)
		// Load the asset located in the assets foldier, not the copies within bin folder
		if (Std.is(Data, String)) 
		{
			source = new Fast(Xml.parse(File.getContent("../../../../" + Data)));
		}
		#else
		if (Std.is(Data, String)) 
		{
			source = new Fast(Xml.parse(Assets.getText(Data)));
		}
		#end
		else if (Std.is(Data, Xml)) 
		{
			source = new Fast(Data);
		}
		else 
		{
			throw "Unknown TMX map format";
		}
		
		source = source.node.map;
		
		// map header
		version = source.att.version;
		
		if (version == null) 
		{
			version = "unknown";
		}
		
		orientation = source.att.orientation;
		
		if (orientation == null) 
		{
			orientation = "orthogonal";
		}
		
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
		objectGroups = new Array<TiledObjectGroup>();
		
		// read properties
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
		
		// load tilesets
		var name:String;
		for (node in source.nodes.tileset)
		{
			name = node.att.name;
			
			if (!noLoadHash.exists(name))
			{
				tilesets.set(name, new TiledTileSet(node));
			}
		}
		
		// load layer
		for (node in source.nodes.layer)
		{
			name = node.att.name;
			
			if (!noLoadHash.exists(name))
			{
				layers.push( new TiledLayer(node, this) );
			}
		}
		
		// load object group
		for (node in source.nodes.objectgroup)
		{
			name = node.att.name;
			
			if(!noLoadHash.exists(name))
			{
				objectGroups.push( new TiledObjectGroup(node, this) );
			}
		}
	}
	
	public function getTileSet(Name:String):TiledTileSet
	{
		return tilesets.get(Name);
	}
	
	public function getLayer(Name:String):TiledLayer
	{
		var i = layers.length;
		
		while (i > 0)
		{
			if (layers[--i].name == Name)
			{
				return layers[i];
			}
		}
		
		return null;
	}
	
	public function getObjectGroup(Name:String):TiledObjectGroup
	{
		var i = objectGroups.length;
		
		while (i > 0)
		{
			if (objectGroups[--i].name == Name)
			{
				return objectGroups[i];
			}
		}
		
		return null;
	}
	
	// works only after TiledTileSet has been initialized with an image...
	public function getGidOwner(Gid:Int):TiledTileSet
	{
		var last:TiledTileSet = null;
		var set:TiledTileSet;
		
		for (set in tilesets)
		{
			if (set.hasGid(Gid))
			{
				return set;
			}
		}
		
		return null;
	}
}