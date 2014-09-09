package flixel.addons.display;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.layer.DrawStackItem;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

// TODO: loadGraphic() and loadFrame() methods
// TODO: scale support.

/**
 * Used for showing infinitely scrolling backgrounds.
 * @author Chevy Ray
 */
class FlxBackdrop extends FlxSprite
{
	private var _ppoint:Point;
	private var _scrollW:Int;
	private var _scrollH:Int;
	private var _repeatX:Bool;
	private var _repeatY:Bool;
	
	/**
	 * Frame used for tiling
	 */
	private var _tileFrame:FlxFrame;
	
	private var _frameRect:Rectangle;
	
	#if FLX_RENDER_TILE
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
	public function new(Graphic:FlxGraphicAsset, ScrollX:Float = 1, ScrollY:Float = 1, RepeatX:Bool = true, RepeatY:Bool = true) 
	{
		super();
		
		_repeatX = RepeatX;
		_repeatY = RepeatY;
		
		_ppoint = new Point();
		_frameRect = new Rectangle();
		
		scrollFactor.x = ScrollX;
		scrollFactor.y = ScrollY;
		
		loadGraphic(Graphic);
	}
	
	override public function destroy():Void 
	{
		#if FLX_RENDER_BLIT
		_data = FlxDestroyUtil.dispose(_data);
		#else
		_tileInfo = null;
		#end
		_ppoint = null;
		
		// TODO: do something with _tileFrame
	//	_tileFrame
		
		super.destroy();
	}
	
	override public function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String):FlxSprite 
	{
		var tileGraphic:FlxGraphic = FlxG.bitmap.add(Graphic);
		_tileFrame = tileGraphic.imageFrame.frame;
		
		var w:Int = Std.int(_tileFrame.sourceSize.x);
		var h:Int = Std.int(_tileFrame.sourceSize.y);
		
		_scrollW = w;
		_scrollH = h;
		
		_frameRect.setTo(0, 0, _scrollW, _scrollH);
		
		if (_repeatX) 
		{
			w += FlxG.width;
		}
		if (_repeatY)
		{
			h += FlxG.height;
		}
		
		#if FLX_RENDER_BLIT
		makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		#end
		
		#if FLX_RENDER_TILE
		_tileInfo = [];
		_numTiles = 0;
		#end
		
		_ppoint.x = _ppoint.y = 0;
		
		#if FLX_RENDER_BLIT
		pixels.lock();
		#end
		
		while (_ppoint.y < h)
		{
			while (_ppoint.x < w)
			{
				#if FLX_RENDER_BLIT
				pixels.copyPixels(_tileFrame.getBitmap(), _frameRect, _ppoint);
				#else
				_tileInfo.push(_ppoint.x + 0.5 * _scrollW);
				_tileInfo.push(_ppoint.y + 0.5 * _scrollH);
				_numTiles++;
				#end
				_ppoint.x += _scrollW;
			}
			_ppoint.x = 0;
			_ppoint.y += _scrollH;
		}
		
		#if FLX_RENDER_BLIT
		pixels.unlock();
		resetFrameBitmaps();
		#end
		
		return this;
	}
	
	public function loadFrame(Frame:FlxFrame):FlxBackdrop
	{
		// TODO: implement this
		
		return this;
	}

	override public function draw():Void
	{
		for (camera in cameras)
		{
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
		#if FLX_RENDER_BLIT
			_flashRect2.setTo(0, 0, graphic.width, graphic.height);
			camera.buffer.copyPixels(frame.getBitmap(), _flashRect2, _ppoint, null, null, true);
		#else
			if (graphic == null)
			{
				return;
			}
			
			var drawItem:DrawStackItem = camera.getDrawStackItem(cachedGraphics, false, 0);
			
			for (j in 0..._numTiles)
			{
				var currTileX = _tileInfo[j * 2];
				var currTileY = _tileInfo[(j * 2) + 1];
				
				_point.set(_ppoint.x + currTileX, _ppoint.y + currTileY);
				setDrawData(drawItem, camera, 1, 0, 0, 1, _tileID);
			}
		#end
		}
	}
}