/*******************************************************************************
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 ******************************************************************************/
package flixel.addons.tmx;

import openfl.Assets;
import haxe.xml.Fast;
#if cpp
import sys.io.File;
import sys.FileSystem;
#end

class TmxMap
{
	public var version      : String; 
	public var orientation  : String;
	
	public var width        : Int;
	public var height       : Int; 
	public var tileWidth    : Int; 
	public var tileHeight   : Int;
	
	public var fullWidth  	: Int;
	public var fullHeight 	: Int;
	
	public var properties   : TmxPropertySet;
	
	// Add a "noload" property to your Map Properties.
	// Add comma separated values of tilesets, layers, or object names.
	// These will not be loaded.
	private var noLoadHash  :Map<String, Bool>;
	
	// Use hash, we don't care about order
	public var tilesets     : Map<String, TmxTileSet>;
	// Use array to preserve load order
	public var layers       : Array<TmxLayer>;
	public var objectGroups : Array<TmxObjectGroup>;
	
	public function new(data: Dynamic)
	{
		properties = new TmxPropertySet();
		var source:Fast = null;
		var node:Fast = null;
		
		#if(LOAD_CONFIG_REAL_TIME && !neko)
		// Load the asset located in the assets foldier, not the copies within bin folder
		if (Std.is(data, String)) source = new Fast(Xml.parse(File.getContent("../../../../" + data)));
		#else
		if (Std.is(data, String)) source = new Fast(Xml.parse(Assets.getText(data)));
		#end
		else if (Std.is(data, Xml)) source = new Fast(data);
		else throw "Unknown TMX map format";
		
		source = source.node.map;
		
		//map header
		version = source.att.version;
		if (version == null) version = "unknown";
		
		orientation = source.att.orientation;
		if (orientation == null) orientation = "orthogonal";
		
		width = Std.parseInt(source.att.width);
		height = Std.parseInt(source.att.height);
		tileWidth = Std.parseInt(source.att.tilewidth);
		tileHeight = Std.parseInt(source.att.tileheight);
		// Calculate the entire size
		fullWidth = width * tileWidth;
		fullHeight = height * tileHeight;
		
		noLoadHash		= new Map<String, Bool>();
		tilesets 		= new Map<String, TmxTileSet>();
		layers 			= new Array<TmxLayer>();
		objectGroups 	= new Array<TmxObjectGroup>();
		
		//read properties
		for (node in source.nodes.properties)
			properties.extend(node);
		
		var noLoadStr = properties.get("noload");
		if (noLoadStr != null)
		{
			var regExp = ~/[,;|]/;
			var noLoadArr = regExp.split(noLoadStr);
			for (s in noLoadArr)
				noLoadHash.set(StringTools.trim(s), true);
		}
		
		//load tilesets
		var name:String;
		for (node in source.nodes.tileset)
		{
			name = node.att.name;
			if(!noLoadHash.exists(name))
				tilesets.set(name, new TmxTileSet(node));
		}
		
		//load layer
		for (node in source.nodes.layer)
		{
			name = node.att.name;
			if(!noLoadHash.exists(name))
				layers.push( new TmxLayer(node, this) );
		}
		
		//load object group
		for (node in source.nodes.objectgroup)
		{
			name = node.att.name;
			if(!noLoadHash.exists(name))
				objectGroups.push( new TmxObjectGroup(node, this) );
		}
	}
	
	public function getTileSet(name:String):TmxTileSet
	{
		return tilesets.get(name);
	}
	
	public function getLayer(name:String):TmxLayer
	{
		var i = layers.length;
		while (i > 0)
			if (layers[--i].name == name)
				return layers[i];
		return null;
	}
	
	public function getObjectGroup(name:String):TmxObjectGroup
	{
		var i = objectGroups.length;
		while (i > 0)
			if (objectGroups[--i].name == name)
				return objectGroups[i];
		return null;
	}
	
	//works only after TmxTileSet has been initialized with an image...
	public function getGidOwner(gid:Int):TmxTileSet
	{
		var last:TmxTileSet = null;
		var set:TmxTileSet;
		for (set in tilesets)
		{
			if(set.hasGid(gid))
				return set;
		}
		return null;
	}
}