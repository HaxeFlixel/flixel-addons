package flixel.addons.editors.tiled;

import flixel.util.FlxColor;
import openfl.Assets;
import haxe.xml.Fast;
import flixel.util.typeLimit.OneOfTwo;

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
	
	/**
	 * Use to get a tileset by name
	 */
	public var tilesets:Map<String, TiledTileSet>;
	/**
	 * Use for iterating over tilesets, and for merging tilesets (because order is important)
	 */
	public var tilesetArray:Array<TiledTileSet>;
	
	public var layers:Array<TiledLayer>;
	
	// Add a "noload" property to your Map Properties.
	// Add comma separated values of tilesets, layers, or object names.
	// These will not be loaded.
	private var noLoadHash:Map<String, Bool>;
	private var layerMap:Map<String, TiledLayer>;
	
	/**
	 * @param data Either a string or XML object containing the Tiled map data
	 */
	public function new(data:FlxTiledAsset)
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
		tilesetArray = new Array<TiledTileSet>();
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
				var ts:TiledTileSet = new TiledTileSet(node);
				tilesets.set(name, ts);
				tilesetArray.push(ts);
			}
		}
		
		layerMap = new Map<String, TiledLayer>();
		// Load tile and object layers
		for (el in source.elements)
		{	
			if (el.has.name && noLoadHash.exists(el.att.name)) continue;
			
			if (el.name.toLowerCase() == "layer")
			{
				var tileLayer = new TiledTileLayer(el, this);
				layers.push(tileLayer);
				layerMap.set(tileLayer.name, tileLayer);
			}
			else if (el.name.toLowerCase() == "objectgroup")
			{
				var objectLayer = new TiledObjectLayer(el, this);
				layers.push(objectLayer);
				layerMap.set(objectLayer.name, objectLayer);
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
	
	/**
	 * works only after TiledTileSet has been initialized with an image...
	 */
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

typedef FlxTiledAsset = OneOfTwo<String, Xml>;