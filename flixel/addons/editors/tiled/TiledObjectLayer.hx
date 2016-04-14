package flixel.addons.editors.tiled;

import flixel.addons.editors.tiled.TiledLayer.TiledLayerType;
import flixel.util.FlxColor;
import haxe.xml.Fast;

/**
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledObjectLayer extends TiledLayer
{
	public var objects:Array<TiledObject>;
	public var color:FlxColor;
	
	public function new(source:Fast, parent:TiledMap)
	{
		super(source, parent);
		type = TiledLayerType.OBJECT;
		objects = new Array<TiledObject>();
		color = source.has.color ? FlxColor.fromString(source.att.color) : FlxColor.TRANSPARENT;
		loadObjects(source);
	}
	
	private function loadObjects(source:Fast):Void
	{
		for (node in source.nodes.object)
		{
			objects.push(new TiledObject(node, this));
		}
	}
}
