package flixel.addons.display;

import flixel.system.layer.Region;
import flixel.util.loaders.TextureRegion;
import openfl.Assets;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.system.layer.DrawStackItem;

/**
 * Used for showing infinitely scrolling backgrounds.
 * @author Chevy Ray
 */
class FlxBackdrop extends FlxObject
{
	private var _ppoint:Point;
	private var _scrollW:Int;
	private var _scrollH:Int;
	private var _repeatX:Bool;
	private var _repeatY:Bool;
	
	#if !flash
	private var _tileID:Int;
	private var _tileInfo:Array<Float>;
	private var _numTiles:Int = 0;
	#else
	private var _data:BitmapData;
	#end
	
	/**
	 * Creates an instance of the FlxBackdrop class, used to create infinitely scrolling backgrounds.
	 * 
	 * @param   Graphic		The image you want to use for the backdrop.
	 * @param   ScrollX 	Scrollrate on the X axis.
	 * @param   ScrollY 	Scrollrate on the Y axis.
	 * @param   RepeatX 	If the backdrop should repeat on the X axis.
	 * @param   RepeatY 	If the backdrop should repeat on the Y axis.
	 */
	public function new(Graphic:Dynamic, ScrollX:Float = 1, ScrollY:Float = 1, RepeatX:Bool = true, RepeatY:Bool = true) 
	{
		super();
		
		setCachedGraphics(FlxG.bitmap.add(Graphic));
		
		if (!Std.is(Graphic, TextureRegion))
		{
			_region = new Region(0, 0, _cachedGraphics.bitmap.width, _cachedGraphics.bitmap.height);
			_region.width = _cachedGraphics.bitmap.width;
			_region.height = _cachedGraphics.bitmap.height;
		}
		else
		{
			_region = cast(Graphic, TextureRegion).region.clone();
		}
		
		var w:Int = _region.width;
		var h:Int = _region.height;
		
		if (RepeatX) 
		{
			w += FlxG.width;
		}
		if (RepeatY) 
		{
			h += FlxG.height;
		}
		
		#if flash
		_data = new BitmapData(w, h);
		#end
		_ppoint = new Point();

		_scrollW = _region.width;
		_scrollH = _region.height;
		_repeatX = RepeatX;
		_repeatY = RepeatY;
		
		#if !flash
		_tileInfo = [];
		_numTiles = 0;
		#else
		var regionRect:Rectangle = new Rectangle(_region.startX, _region.startY, _region.width, _region.height);
		#end
		
		while (_ppoint.y < h + _region.height)
		{
			while (_ppoint.x < w + _region.width)
			{
				#if flash
				_data.copyPixels(_cachedGraphics.bitmap, regionRect, _ppoint);
				#else
				_tileInfo.push(_ppoint.x);
				_tileInfo.push(_ppoint.y);
				_numTiles++;
				#end
				_ppoint.x += _region.width;
			}
			_ppoint.x = 0;
			_ppoint.y += _region.height;
		}
		
		scrollFactor.x = ScrollX;
		scrollFactor.y = ScrollY;
		
		updateFrameData();
	}
	
	override public function destroy():Void 
	{
		#if flash
		if (_data != null)
		{
			_data.dispose();
		}
		_data = null;
		#else
		_tileInfo = null;
		#end
		_ppoint = null;
		
		super.destroy();
	}

	override public function draw():Void
	{
		if (cameras == null)
		{
			cameras = FlxG.cameras.list;
		}
		var camera:FlxCamera;
		var l:Int = cameras.length;
		
		for (i in 0...(l))
		{
			camera = cameras[i];
			
			if (!camera.visible || !camera.exists)
			{
				continue;
			}
			
			// Find x position
			if (_repeatX)
			{   
				_ppoint.x = (x - camera.scroll.x * scrollFactor.x) % _scrollW;
				if (_ppoint.x > 0) _ppoint.x -= _scrollW;
			}
			else 
			{
				_ppoint.x = (x - camera.scroll.x * scrollFactor.x);
			}

			// Find y position
			if (_repeatY)
			{
				_ppoint.y = (y - camera.scroll.y * scrollFactor.y) % _scrollH;
				if (_ppoint.y > 0) _ppoint.y -= _scrollH;
			}
			else 
			{
				_ppoint.y = (y - camera.scroll.y * scrollFactor.y);
			}
			
			// Draw to the screen
			#if flash
			camera.buffer.copyPixels(_data, _data.rect, _ppoint, null, null, true);
			#else
			if (_cachedGraphics == null)
			{
				return;
			}
			
			var currDrawData:Array<Float>;
			var currIndex:Int;
			#if !js
			var drawItem:DrawStackItem = camera.getDrawStackItem(_cachedGraphics, false, 0);
			#else
			var drawItem:DrawStackItem = camera.getDrawStackItem(_cachedGraphics, false);
			#end
			
			currDrawData = drawItem.drawData;
			currIndex = drawItem.position;
			
			var currPosInArr:Int;
			var currTileX:Float;
			var currTileY:Float;
			
			for (j in 0...(_numTiles))
			{
				currPosInArr = j * 2;
				currTileX = _tileInfo[currPosInArr];
				currTileY = _tileInfo[currPosInArr + 1];
				#if !js
				currDrawData[currIndex++] = (_ppoint.x) + currTileX;
				currDrawData[currIndex++] = (_ppoint.y) + currTileY;
				#else
				currDrawData[currIndex++] = Math.floor(_ppoint.x) + currTileX;
				currDrawData[currIndex++] = Math.floor(_ppoint.y) + currTileY;
				#end
				currDrawData[currIndex++] = _tileID;
				
				currDrawData[currIndex++] = 1;
				currDrawData[currIndex++] = 0;
				currDrawData[currIndex++] = 0;
				currDrawData[currIndex++] = 1;
				
				#if !js
				// Alpha
				currDrawData[currIndex++] = 1.0;	
				#end
			}
			
			drawItem.position = currIndex;
			#end
		}
	}
	
	override public function updateFrameData():Void
	{
		#if !flash
		if (_cachedGraphics != null)
		{
			_tileID = _cachedGraphics.tilesheet.addTileRect(new Rectangle(_region.startX, _region.startY, _scrollW, _scrollH), new Point());
		}
		#end
	}
}