package flixel.addons.editors.tiled;

import flash.utils.ByteArray;
import flash.utils.Endian;
import haxe.xml.Fast;

/**
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledLayer
{
	public var map:TiledMap;
	public var name:String;
	public var x:Int;
	public var y:Int;
	public var width:Int;
	public var height:Int;
	public var opacity:Float;
	public var visible:Bool;
	public var properties:TiledPropertySet;
	
	public var tiles:Array<TiledTile>;
	
	inline static private var BASE64_CHARS:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
	
	private var _xmlData:Fast;
	
	public function new(Source:Fast, Parent:TiledMap)
	{
		properties = new TiledPropertySet();
		map = Parent;
		name = Source.att.name;
		x = (Source.has.x) ? Std.parseInt(Source.att.x) : 0;
		y = (Source.has.y) ? Std.parseInt(Source.att.y) : 0;
		width = Std.parseInt(Source.att.width); 
		height = Std.parseInt(Source.att.height); 
		visible = (Source.has.visible && Source.att.visible == "1") ? true : false;
		opacity = (Source.has.opacity) ? Std.parseFloat(Source.att.opacity) : 1.0;
		tiles = new Array<TiledTile>();
		
		// load properties
		var node:Fast;
		
		for (node in Source.nodes.properties)
		{
			properties.extend(node);
		}
		
		// load tile GIDs
		_xmlData = Source.node.data;
		
		if (_xmlData == null)
		{
			throw "Error loading TiledLayer level data";
		}
	}
	
	private function getByteArrayData():ByteArray
	{
		var result:ByteArray = null;
		
		if (_xmlData.att.encoding == "base64")
		{
			var chunk:String = _xmlData.innerData;
			var compressed:Bool = false;
			
			result = base64ToByteArray(chunk);
			result.endian = Endian.LITTLE_ENDIAN;
			
			if (_xmlData.has.compression)
			{
				switch(_xmlData.att.compression)
				{
					case "zlib":
						compressed = true;
					default:
						throw "TiledLayer - data compression type not supported!";
				}
			}
			
			if (compressed)
			{
				#if (js && !format)
				throw "HTML5 doesn't support compressed data! Use Base64 (uncompressed) when you save the map or install the library 'format' and use it";
				#else
				result.uncompress();
				#end
			}
		}
		// Compressed or uncompressed, the endian must be little endian
		result.endian = Endian.LITTLE_ENDIAN;
		return result;
	}
	
	private static function base64ToByteArray(data:String):ByteArray
	{
		var output:ByteArray = new ByteArray();
		
		// initialize lookup table
		var lookup:Array<Int> = new Array<Int>();
		var c:Int;
		
		for (c in 0...BASE64_CHARS.length)
		{
			lookup[BASE64_CHARS.charCodeAt(c)] = c;
		}
		
		var i:Int = 0;
		
		while (i < data.length - 3)
		{
			// Ignore whitespace
			if (data.charAt(i) == " " || data.charAt(i) == "\n" || data.charAt(i) == "\r")
			{
				i++; continue;
			}
			
			// read 4 bytes and look them up in the table
			var a0:Int = lookup[data.charCodeAt(i)];
			var a1:Int = lookup[data.charCodeAt(i + 1)];
			var a2:Int = lookup[data.charCodeAt(i + 2)];
			var a3:Int = lookup[data.charCodeAt(i + 3)];
			
			// convert to and write 3 bytes
			if (a1 < 64)
			{
				output.writeByte((a0 << 2) + ((a1 & 0x30) >> 4));
			}
			if (a2 < 64)
			{
				output.writeByte(((a1 & 0x0f) << 4) + ((a2 & 0x3c) >> 2));
			}
			if (a3 < 64)
			{
				output.writeByte(((a2 & 0x03) << 6) + a3);
			}
			
			i += 4;
		}
		
		// Rewind & return decoded data
		output.position = 0;
		
		return output;
	}
	
	private function resolveTile(GlobalTileID:UInt):Int
	{
		var tile:TiledTile = new TiledTile(GlobalTileID);
		
		var tilesetID:Int = tile.tilesetID;
		for (tileset in map.tilesets)
		{
			if (tileset.hasGid(tilesetID))
			{
				tiles.push(tile);
				// return tileset.fromGid(tilesetID);
				return tilesetID;
			}
		}
		tiles.push(null);
		return 0;
	}
	
	/**
	 * Function that tries to resolve the tiles gid in the csv data.
	 * TODO: It fails because I can't find a function to parse an unsigned int from a string :(
	 * @param	csvData		The csv string to resolve
	 * @return	The csv string resolved
	 */
	private function resolveCsvTiles(csvData:String):String
	{
		var buffer:StringBuf = new StringBuf();
		var rows:Array<String> = csvData.split("\n");
		var values:Array<String>;
		for(row in rows) {
			values = row.split(",");
			var i:UInt;
			for (v in values) {
				if ( v == "") {
					continue;
				}
				i = Std.parseInt(v);
				buffer.add(resolveTile(i) + ",");
			}
			buffer.add("\n");
		}
		
		var result:String = buffer.toString();
		buffer = null;
		return result;
	}
	
	public var csvData(get, null):String;
	
	private function get_csvData():String 
	{
		if (csvData == null)
		{
			if (_xmlData.att.encoding == "csv")
			{
				csvData = _xmlData.innerData;
			}
			else
			{
				throw "Must use CSV encoding in order to get CSV data.";
			}
		}
		return csvData;
	}
	
	public var tileArray(get, null):Array<Int>;
	
	private function get_tileArray():Array<Int>
	{
		if (tileArray == null)
		{
			var mapData:ByteArray = getByteArrayData();
			
			if (mapData == null)
			{
				throw "Must use Base64 encoding (with or without zlip compression) in order to get 1D Array.";
			}
			
			tileArray = new Array<Int>();
			
			while (mapData.position < mapData.length)
			{
				tileArray.push(resolveTile(mapData.readUnsignedInt()));
			}
		}
		
		return tileArray;
	}
}