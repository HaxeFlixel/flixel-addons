package flixel.addons.editors.tiled;

import openfl.geom.Rectangle;
import flixel.util.typeLimit.OneOfTwo;
import openfl.Assets;
import openfl.utils.ByteArray;
import haxe.io.Path;
import haxe.xml.Access;

/**
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledTileSet
{
	public var firstGID:Int;
	public var name:String;
	public var tileWidth:Int;
	public var tileHeight:Int;
	public var spacing:Int;
	public var margin:Int;
	public var imageSource:String;

	// Available only after image has been assigned:
	public var numTiles:Int;
	public var numRows:Int;
	public var numCols:Int;

	public var properties:TiledPropertySet;

	public var tileTypes:Array<String>;

	public var tileProbabilities:Array<Float>;

	public var tileProps:Array<TiledTilePropertySet>;

	public var tileImagesSources:Array<TiledImageTile>;

	public function new(data:FlxTiledTileAsset, rootPath:String = "")
	{
		var source:Access;
		numTiles = 0xFFFFFF;
		numRows = numCols = 1;

		// Use the correct data format
		if (data is Xml)
		{
			source = data;
		}
		else if ((data is ValidByteArray))
		{
			var bytes:ValidByteArray = cast data;
			source = new Access(Xml.parse(bytes.toString()));
			source = source.node.tileset;
		}
		else
		{
			throw "Unknown TMX tileset format";
		}

		firstGID = (source.has.firstgid) ? Std.parseInt(source.att.firstgid) : 1;

		if (source.has.source)
		{
			var sourcePath = Path.normalize(rootPath + source.att.source);
			if (Assets.exists(sourcePath))
			{
				source = new Access(Xml.parse(Assets.getText(sourcePath)));
				source = source.node.tileset;
			}
			else
			{
				throw 'Invalid TSX tileset path: $sourcePath';
			}
		}

		if (!source.has.source)
		{
			var node:Access;

			if (source.hasNode.image)
			{
				// single image
				node = source.node.image;
				imageSource = node.att.source;
			}
			else
			{
				// several images
				node = source.node.tile;
				imageSource = "";

				// read tiles images
				tileImagesSources = new Array<TiledImageTile>();

				for (node in source.nodes.tile)
				{
					if (!node.has.id)
					{
						continue;
					}

					var id:Int = Std.parseInt(node.att.id);
					tileImagesSources[id] = new TiledImageTile(node);
				}
			}

			name = source.att.name;

			var imgWidth = 0;
			if (node.has.width)
			{
				imgWidth = Std.parseInt(node.att.width);
			}
			var imgHeight = 0;
			if (node.has.height)
			{
				imgHeight = Std.parseInt(node.att.height);
			}

			if (source.has.tilewidth)
			{
				tileWidth = Std.parseInt(source.att.tilewidth);
			}
			if (source.has.tileheight)
			{
				tileHeight = Std.parseInt(source.att.tileheight);
			}
			if (source.has.spacing)
			{
				spacing = Std.parseInt(source.att.spacing);
			}
			if (source.has.margin)
			{
				margin = Std.parseInt(source.att.margin);
			}

			// read properties
			properties = new TiledPropertySet();
			for (prop in source.nodes.properties)
				properties.extend(prop);

			// read tiles properties, type, probability
			tileProps = new Array<TiledTilePropertySet>();
			tileTypes = new Array<String>();
			tileProbabilities = new Array<Float>();

			for (node in source.nodes.tile)
			{
				if (!node.has.id)
				{
					continue;
				}

				var id:Int = Std.parseInt(node.att.id);

				if (node.has.type)
				{
					var type:String = node.att.type;
					tileTypes[id] = type;
				}

				if (node.has.probability)
				{
					var probability = Std.parseFloat(node.att.probability);
					tileProbabilities[id] = probability;
				}

				tileProps[id] = new TiledTilePropertySet(id);
				tileProps[id].keys.set("id", Std.string(id));
				for (prop in node.nodes.properties)
				{
					tileProps[id].extend(prop);
				}
				if (node.hasNode.animation)
				{
					for (frame in node.node.animation.nodes.frame)
					{
						tileProps[id].addAnimationFrame(Std.parseInt(frame.att.tileid), Std.parseFloat(frame.att.duration));
					}
				}
				if (node.hasNode.objectgroup)
				{
					for (object in node.node.objectgroup.nodes.object)
					{
						var tiledObject:TiledObject = new TiledObject(object);
						tileProps[id].addTileObject(tiledObject);
					}
				}
			}

			if (tileWidth > 0 && tileHeight > 0)
			{
				numRows = Std.int(imgHeight / tileHeight);
				numCols = Std.int(imgWidth / tileWidth);
				numTiles = numRows * numCols;
			}
		}
		else
		{
			throw "TMX tileset misses source image or tiles";
		}
	}

	public inline function hasGid(Gid:Int):Bool
	{
		return (Gid >= firstGID) && Gid < (firstGID + numTiles);
	}

	public inline function fromGid(Gid:Int):Int
	{
		return Gid - (firstGID - 1);
	}

	public inline function toGid(ID:Int):Int
	{
		return firstGID + ID;
	}

	public function getPropertiesByGid(Gid:Int):TiledPropertySet
	{
		if (tileProps != null)
		{
			return tileProps[Gid - firstGID];
		}

		return null;
	}

	public inline function getProperties(ID:Int):TiledPropertySet
	{
		return tileProps[ID];
	}

	public function getImageSourceByGid(Gid:Int):TiledImageTile
	{
		if (tileImagesSources != null)
		{
			return tileImagesSources[Gid - firstGID];
		}

		return null;
	}

	public inline function getImageSource(ID:Int):TiledImageTile
	{
		return tileImagesSources[ID];
	}

	public inline function getRect(ID:Int):Rectangle
	{
		// TODO: consider spacing & margin
		return new Rectangle((ID % numCols) * tileWidth, (ID / numCols) * tileHeight);
	}
}

private typedef ValidByteArray = #if lime_legacy ByteArray #else ByteArrayData #end;
typedef FlxTiledTileAsset = OneOfTwo<Access, ValidByteArray>;
