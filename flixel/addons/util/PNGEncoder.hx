/*
	Copyright (c) 2008, Adobe Systems Incorporated
	All rights reserved.

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are
	met:

	* Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.

	* Redistributions in binary form must reproduce the above copyright
	notice, this list of conditions and the following disclaimer in the
	documentation and/or other materials provided with the distribution.

	* Neither the name of Adobe Systems Incorporated nor the names of its
	contributors may be used to endorse or promote products derived from
	this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
	IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
	THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
	PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
	PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
	LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package flixel.addons.util;

#if !js
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.utils.ByteArray;

/**
 * Class that converts BitmapData into a valid PNG
 */
class PNGEncoder
{
	static var crcTable:Array<Int>;
	static var crcTableComputed:Bool;

	/**
	 * Created a PNG image from the specified BitmapData
	 *
	 * @param image The BitmapData that will be converted into the PNG format.
	 * @return a ByteArray representing the PNG encoded image data.
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 9.0
	 * @tiptext
	 */
	public static function encode(img:BitmapData):ByteArray
	{
		// Create output byte array
		var png:ByteArray = new ByteArray();
		// Write PNG signature
		png.writeUnsignedInt(0x89504e47);
		png.writeUnsignedInt(0x0D0A1A0A);
		// Build IHDR chunk
		var IHDR:ByteArray = new ByteArray();
		IHDR.writeInt(img.width);
		IHDR.writeInt(img.height);
		IHDR.writeUnsignedInt(0x08060000); // 32bit RGBA
		IHDR.writeByte(0);
		writeChunk(png, 0x49484452, IHDR);
		// Build IDAT chunk
		var IDAT:ByteArray = new ByteArray();
		for (i in 0...img.height)
		{
			// no filter
			IDAT.writeByte(0);
			var p:Int;
			if (!img.transparent)
			{
				for (j in 0...img.width)
				{
					p = img.getPixel(j, i);
					IDAT.writeUnsignedInt(((p & 0xFFFFFF) << 8) | 0xFF);
				}
			}
			else
			{
				for (j in 0...img.width)
				{
					p = img.getPixel32(j, i);
					IDAT.writeUnsignedInt(((p & 0xFFFFFF) << 8) | (p >>> 24));
				}
			}
		}
		IDAT.compress();
		writeChunk(png, 0x49444154, IDAT);
		// Build IEND chunk
		writeChunk(png, 0x49454E44, null);
		// return PNG
		return png;
	}

	static function writeChunk(png:ByteArray, type:Int, data:ByteArray):Void
	{
		var c:Int;

		if (!crcTableComputed)
		{
			crcTableComputed = true;
			crcTable = [];

			for (n in 0...256)
			{
				c = n;
				for (k in 0...8)
				{
					if ((c & 1) != 0)
					{
						c = 0xedb88320 ^ (c >>> 1);
					}
					else
					{
						c = c >>> 1;
					}
				}
				crcTable[n] = c;
			}
		}
		var len:Int = 0;
		if (data != null)
		{
			len = data.length;
		}
		png.writeUnsignedInt(len);
		var p:Int = png.position;
		png.writeUnsignedInt(type);
		if (data != null)
		{
			png.writeBytes(data);
		}
		var e:Int = png.position;
		png.position = p;
		c = 0xffffffff;
		for (i in 0...(e - p))
		{
			c = crcTable[(c ^ png.readUnsignedByte()) & 0xff] ^ c >>> 8;
		}
		c = c ^ 0xffffffff;
		png.position = e;
		png.writeUnsignedInt(c);
	}
}
#end
