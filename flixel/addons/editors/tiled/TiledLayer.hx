package flixel.addons.editors.tiled;

import flash.utils.ByteArray;

#if haxe4
import haxe.xml.Access;
#else
import haxe.xml.Fast as Access;
#end

/**
 * Base class for Tiled object and tile layers
 * 
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledLayer
{
	public var type:TiledLayerType;
	public var map:TiledMap;
	public var name:String;
	public var opacity:Float;
	public var visible:Bool;
	public var properties:TiledPropertySet;
	/** @since 2.1.0 */
	public var offsetX:Float;
	/** @since 2.1.0 */
	public var offsetY:Float;

	function new(source:Access, parent:TiledMap)
	{
		properties = new TiledPropertySet();
		map = parent;
		name = source.att.name;
		visible = (source.has.visible && source.att.visible == "0") ? false : true;
		opacity = (source.has.opacity) ? Std.parseFloat(source.att.opacity) : 1.0;
		offsetX = (source.has.offsetx) ? Std.parseFloat(source.att.offsetx) : 0.0;
		offsetY = (source.has.offsety) ? Std.parseFloat(source.att.offsety) : 0.0;
		
		loadProperties(source);
	}

	function loadProperties(source:Access):Void
	{
		for (node in source.nodes.properties)
		{
			properties.extend(node);
		}
	}
}

enum TiledLayerType
{
	TILE;
	OBJECT;
	IMAGE;
	GROUP;
}
