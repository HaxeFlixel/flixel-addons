package flixel.addons.display;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import flixel.math.FlxPoint.FlxCallbackPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.layer.DrawStackItem;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

// TODO: maybe add game resize handler

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
	
	#if FLX_RENDER_TILE
	private var _tileID:Int;
	private var _tileInfo:Array<Float>;
	private var _numTiles:Int = 0;
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
		
		scale = new FlxCallbackPoint(scaleCallback);
		scale.set(1, 1);
		
		_repeatX = RepeatX;
		_repeatY = RepeatY;
		
		_ppoint = new Point();
		
		scrollFactor.x = ScrollX;
		scrollFactor.y = ScrollY;
		
		loadGraphic(Graphic);
	}
	
	override public function destroy():Void 
	{
		#if FLX_RENDER_TILE
		_tileInfo = null;
		#end
		_ppoint = null;
		scale = FlxDestroyUtil.destroy(scale);
		setTileFrame(null);
		
		super.destroy();
	}
	
	override public function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String):FlxSprite 
	{
		var tileGraphic:FlxGraphic = FlxG.bitmap.add(Graphic);
		setTileFrame(tileGraphic.imageFrame.frame);
		
		var w:Int = Std.int(_tileFrame.sourceSize.x);
		var h:Int = Std.int(_tileFrame.sourceSize.y);
		
		_scrollW = w;
		_scrollH = h;
		
		regenGraphic();
		
		return this;
	}
	
	public function loadFrame(Frame:FlxFrame):FlxBackdrop
	{
		setTileFrame(Frame);
		
		var w:Int = Std.int(_tileFrame.sourceSize.x);
		var h:Int = Std.int(_tileFrame.sourceSize.y);
		
		_scrollW = w;
		_scrollH = h;
		
		regenGraphic();
		
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
			
			var ssw:Float = _scrollW * Math.abs(scale.x);
			var ssh:Float = _scrollH * Math.abs(scale.y);
			
			// Find x position
			if (_repeatX)
			{   
				_ppoint.x = ((x - camera.scroll.x * scrollFactor.x) % ssw);
				if (_ppoint.x > 0) _ppoint.x -= ssw;
			}
			else 
			{
				_ppoint.x = (x - camera.scroll.x * scrollFactor.x);
			}
			
			// Find y position
			if (_repeatY)
			{
				_ppoint.y = ((y - camera.scroll.y * scrollFactor.y) % ssh);
				if (_ppoint.y > 0) _ppoint.y -= ssh;
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
			if (_tileFrame == null)
			{
				return;
			}
			
			var drawItem:DrawStackItem = camera.getDrawStackItem(_tileFrame.parent, false, 0);
			
			_matrix.identity();
			
			if (_tileFrame.angle != 0)
			{
				_tileFrame.prepareFrameMatrix(_matrix);
			}
			
			_matrix.scale(scale.x * camera.totalScaleX, scale.y * camera.totalScaleY);
			
			_ppoint.x += _tileFrame.center.x * scale.x;
			_ppoint.y += _tileFrame.center.y * scale.y;
			
			for (j in 0..._numTiles)
			{
				var currTileX = _tileInfo[j * 2];
				var currTileY = _tileInfo[(j * 2) + 1];
				
				_point.set(_ppoint.x + currTileX, _ppoint.y + currTileY);
				
				_point.x *= camera.totalScaleX;
				_point.y *= camera.totalScaleY;
				
				setDrawData(drawItem, camera, _matrix, _tileFrame.tileID);
			}
		#end
		}
	}
	
	private function regenGraphic():Void
	{
		var sx:Float = Math.abs(scale.x);
		var sy:Float = Math.abs(scale.y);
		
		var ssw:Int = Std.int(_scrollW * sx);
		var ssh:Int = Std.int(_scrollH * sy);
		
		var w:Int = ssw;
		var h:Int = ssh;
		
		if (_repeatX) 
		{
			w += FlxG.width;
		}
		if (_repeatY)
		{
			h += FlxG.height;
		}
		
		#if FLX_RENDER_BLIT
		if (graphic == null || (graphic.width != w || graphic.height != h))
		{
			makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		}
		#else
		_tileInfo = [];
		_numTiles = 0;
		#end
		
		_ppoint.x = _ppoint.y = 0;
		
		#if FLX_RENDER_BLIT
		pixels.lock();
		_flashRect2.setTo(0, 0, graphic.width, graphic.height);
		pixels.fillRect(_flashRect2, FlxColor.TRANSPARENT);
		_matrix.identity();
		_matrix.scale(sx, sy);
		#end
		
		while (_ppoint.y < h)
		{
			while (_ppoint.x < w)
			{
				#if FLX_RENDER_BLIT
				pixels.draw(_tileFrame.getBitmap(), _matrix);
				_matrix.tx += ssw;
				#else
				_tileInfo.push(_ppoint.x);
				_tileInfo.push(_ppoint.y);
				_numTiles++;
				#end
				_ppoint.x += ssw;
			}
			#if FLX_RENDER_BLIT
			_matrix.tx = 0;
			_matrix.ty += ssh;
			#end
			_ppoint.x = 0;
			_ppoint.y += ssh;
		}
		
		#if FLX_RENDER_BLIT
		pixels.unlock();
		resetFrameBitmaps();
		#end
	}
	
	private inline function scaleCallback(Scale:FlxPoint)
	{ 
		if (_tileFrame != null)
			regenGraphic();
	}
	
	private function setTileFrame(Frame:FlxFrame):FlxFrame
	{
		if (Frame != _tileFrame)
		{
			if (_tileFrame != null)
			{
				_tileFrame.parent.useCount--;
			}
			
			if (Frame != null)
			{
				Frame.parent.useCount++;
			}
		}
		
		return _tileFrame = Frame;
	}
}