package flixel.addons.editors.tiled;

import haxe.xml.Access;

/**
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledImageTile
{
	public var id:String;
	public var width:Float;
	public var height:Float;
	public var source:String;

	public function new(Source:Access)
	{
		for (img in Source.nodes.image)
		{
			width = Std.parseFloat(img.att.width);
			height = Std.parseFloat(img.att.height);
			source = img.att.source;
		}
	}
}
