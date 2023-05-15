package flixel.addons.editors.tiled;

import flixel.addons.editors.tiled.TiledLayer.TiledLayerType;
import flixel.util.FlxColor;
import haxe.xml.Access;

/**
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledGroupLayer extends TiledLayer
{
	public var layers:Array<TiledLayer> = [];

	var layerMap:Map<String, TiledLayer> = new Map<String, TiledLayer>();

	public function new(source:Access, parent:TiledMap, noLoadHash:Map<String, Bool>)
	{
		super(source, parent);
		type = TiledLayerType.GROUP;
		loadLayers(source, parent, noLoadHash);
	}

	function loadLayers(source:Access, parent:TiledMap, noLoadHash:Map<String, Bool>):Void
	{
		for (el in source.elements)
		{
			if (el.has.name && noLoadHash.exists(el.att.name))
				continue;

			var layer:TiledLayer = switch (el.name.toLowerCase())
			{
				case "group": new TiledGroupLayer(el, parent, noLoadHash);
				case "layer": new TiledTileLayer(el, parent);
				case "objectgroup": new TiledObjectLayer(el, parent);
				case "imagelayer": new TiledImageLayer(el, parent);
				case _: null;
			}

			if (layer != null)
			{
				layers.push(layer);
				layerMap.set(layer.name, layer);
			}
		}
	}

	public function getLayer(name:String):TiledLayer
	{
		return layerMap.get(name);
	}
}
