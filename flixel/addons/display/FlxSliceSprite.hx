package flixel.addons.display;

import flixel.FlxSprite;
import flixel.FlxStrip;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;

/**
 * Sprite which can be used for various sorts of slicing (9-slice, 3 slice, tiled sprite but without scrolling).
 * Based on Kyle Pulver's NineSlice class for FlashPunk: http://kpulv.com/96/Flashpunk_NineSlice_Class__Updated__/
 * @author kpulv
 * @author Zaphod
 * @since  2.1.0
 */
class FlxSliceSprite extends FlxStrip
{
	static inline var TOP_LEFT:Int = 0;
	static inline var TOP:Int = 1;
	static inline var TOP_RIGHT:Int = 2;
	static inline var LEFT:Int = 3;
	static inline var CENTER:Int = 4;
	static inline var RIGHT:Int = 5;
	static inline var BOTTOM_LEFT:Int = 6;
	static inline var BOTTOM:Int = 7;
	static inline var BOTTOM_RIGHT:Int = 8;
	
	/**
	 * Whether to adjust sprite's width to slice grid or not.
	 */
	public var snapWidth(default, set):Bool = false;
	/**
	 * Whether to adjust sprite's height to slice grid or not.
	 */
	public var snapHeight(default, set):Bool = false;
	
	/**
	 * Whether to use tiling or to stretch left border of the sprite.
	 */
	public var stretchLeft(default, set):Bool = false;
	/**
	 * Whether to use tiling or to stretch top border of the sprite.
	 */
	public var stretchTop(default, set):Bool = false;
	/**
	 * Whether to use tiling or to stretch right border of the sprite.
	 */
	public var stretchRight(default, set):Bool = false;
	/**
	 * Whether to use tiling or to stretch bottom border of the sprite.
	 */
	public var stretchBottom(default, set):Bool = false;
	/**
	 * Whether to use tiling or to stretch center part of the sprite.
	 */
	public var stretchCenter(default, set):Bool = false;
	
	/**
	 * Rectangle that defines slice grid:
	 */
	public var sliceRect(default, set):FlxRect;
	
	/**
	 * Actual width of the sprite which will be visible.
	 * Its calculation is based on snapWidth and sliceRect values. 
	 */
	public var snappedWidth(get, null):Float;
	/**
	 * Actual height of the sprite which will be visible.
	 * Its calculation is based on snapHeight and sliceRect values. 
	 */
	public var snappedHeight(get, null):Float;
	
	/**
	 * Internal array of FlxGraphic objects for each element of slice grid.
	 */
	var slices:Array<FlxGraphic>;
	/**
	 * Internal array of FlxRect objects for each element of slice grid.
	 */
	var sliceRects:Array<FlxRect>;
	
	var sliceVertices:Array<DrawData<Float>>;
	var sliceUVTs:Array<DrawData<Float>>;
	
	/**
	 * Helper sprite, which does actual rendering in blit render mode.
	 */
	var renderSprite:FlxSprite;
	
	var regen:Bool = true;
	
	var regenSlices:Bool = true;
	
	var helperFrame:FlxFrame;
	
	var _snappedWidth:Float = -1;
	var _snappedHeight:Float = -1;
	
	public function new(Graphic:FlxGraphicAsset, SliceRect:FlxRect, Width:Float, Height:Float)
	{
		super();
		
		if (renderSprite == null)
			renderSprite = new FlxSprite();
		
		sliceRects = [];
		sliceVertices = [];
		sliceUVTs = [];
		
		for (i in 0...9)
		{
			sliceRects[i] = new FlxRect();
			sliceVertices[i] = new DrawData<Float>();
			sliceUVTs[i] = new DrawData<Float>();
		}
		
		indices[0] = 0;
		indices[1] = 1;
		indices[2] = 2;
		indices[3] = 2;
		indices[4] = 3;
		indices[5] = 0;
		
		repeat = true;
		sliceRect = SliceRect;
		loadGraphic(Graphic);
		
		width = Width;
		height = Height;
	}
	
	override public function destroy():Void
	{
		sliceRect = null;
		sliceRects = null;
		sliceVertices = null;
		sliceUVTs = null;
		slices = FlxDestroyUtil.destroyArray(slices);
		helperFrame = FlxDestroyUtil.destroy(helperFrame);
		renderSprite = FlxDestroyUtil.destroy(renderSprite);
		
		super.destroy();
	}
	
	override public function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String):FlxSprite
	{
		graphic = FlxG.bitmap.add(Graphic);
		return this;
	}
	
	public function loadFrame(Frame:FlxFrame):FlxSliceSprite
	{
		graphic = FlxGraphic.fromFrame(Frame);
		return this;
	}
	
	override function set_graphic(Value:FlxGraphic):FlxGraphic
	{
		if (graphic != Value)
			regen = regenSlices = true;
		
		return super.set_graphic(Value);
	}
	
	function regenGraphic():Void
	{
		if (!regen || graphic == null)
			return;
		
		if (regenSlices)
			regenSliceFrames();
		
		var centerWidth:Float = width - sliceRects[LEFT].width - sliceRects[RIGHT].width;
		var centerHeight:Float = height - sliceRects[TOP].height - sliceRects[BOTTOM].height;
		
		if (snapWidth)
		{
			centerWidth = Math.floor((width - sliceRects[LEFT].width - sliceRects[RIGHT].width) / sliceRects[CENTER].width) * sliceRects[CENTER].width;
			centerWidth = Math.max(centerWidth, sliceRects[CENTER].width);
		}
		
		if (snapHeight)
		{
			centerHeight = Math.floor((height - sliceRects[TOP].height - sliceRects[BOTTOM].height) / sliceRects[CENTER].height) * sliceRects[CENTER].height;
			centerHeight = Math.max(centerHeight, sliceRects[CENTER].height);
		}
		
		_snappedWidth = centerWidth + sliceRects[LEFT].width + sliceRects[RIGHT].width;
		_snappedHeight = centerHeight + sliceRects[TOP].height + sliceRects[BOTTOM].height;
		
		if (FlxG.renderBlit)
		{
			if (renderSprite.width != _snappedWidth || renderSprite.height != _snappedHeight)
			{
				renderSprite.makeGraphic(Std.int(_snappedWidth), Std.int(_snappedHeight), FlxColor.TRANSPARENT, true);
			}
			else
			{
				_flashRect2.setTo(0, 0, _snappedWidth, _snappedHeight);
				renderSprite.pixels.fillRect(_flashRect2, FlxColor.TRANSPARENT);
			}
			
			blitTileOnCanvas(CENTER, stretchCenter, sliceRects[CENTER].x, sliceRects[CENTER].y, centerWidth, centerHeight);
			blitTileOnCanvas(TOP, stretchTop, sliceRects[TOP].x, 0, centerWidth, sliceRects[TOP].height);
			blitTileOnCanvas(BOTTOM, stretchBottom, sliceRects[BOTTOM].x, _snappedHeight - sliceRects[BOTTOM].height, centerWidth, sliceRects[BOTTOM].height);
			blitTileOnCanvas(LEFT, stretchLeft, 0, sliceRects[LEFT].y, sliceRects[LEFT].width, centerHeight);
			blitTileOnCanvas(RIGHT, stretchRight, _snappedWidth - sliceRects[RIGHT].width, sliceRects[RIGHT].y, sliceRects[RIGHT].width, centerHeight);
			blitTileOnCanvas(TOP_LEFT, false, 0, 0, sliceRects[TOP_LEFT].width, sliceRects[TOP_LEFT].height);
			blitTileOnCanvas(TOP_RIGHT, false, _snappedWidth - sliceRects[TOP_RIGHT].width, 0, sliceRects[TOP_RIGHT].width, sliceRects[TOP_RIGHT].height);
			blitTileOnCanvas(BOTTOM_LEFT, false, 0, _snappedHeight - sliceRects[BOTTOM_LEFT].height, sliceRects[BOTTOM_LEFT].width, sliceRects[BOTTOM_LEFT].height);
			blitTileOnCanvas(BOTTOM_RIGHT, false, _snappedWidth - sliceRects[BOTTOM_RIGHT].width, _snappedHeight - sliceRects[BOTTOM_RIGHT].height, sliceRects[BOTTOM_RIGHT].width, sliceRects[BOTTOM_RIGHT].height);
			
			renderSprite.dirty = true;
		}
		else
		{
			fillTileVerticesUVs(CENTER, stretchCenter, sliceRects[CENTER].x, sliceRects[CENTER].y, centerWidth, centerHeight);
			fillTileVerticesUVs(TOP, stretchTop, sliceRects[TOP].x, 0, centerWidth, sliceRects[TOP].height);
			fillTileVerticesUVs(BOTTOM, stretchBottom, sliceRects[TOP].x, _snappedHeight - sliceRects[BOTTOM].height, centerWidth, sliceRects[BOTTOM].height);
			fillTileVerticesUVs(LEFT, stretchLeft, 0, sliceRects[LEFT].y, sliceRects[LEFT].width, centerHeight);
			fillTileVerticesUVs(RIGHT, stretchRight, _snappedWidth - sliceRects[RIGHT].width, sliceRects[RIGHT].y, sliceRects[RIGHT].width, centerHeight);
			fillTileVerticesUVs(TOP_LEFT, false, 0, 0, sliceRects[TOP_LEFT].width, sliceRects[TOP_LEFT].height);
			fillTileVerticesUVs(TOP_RIGHT, false, _snappedWidth - sliceRects[TOP_RIGHT].width, 0, sliceRects[TOP_RIGHT].width, sliceRects[TOP_RIGHT].height);
			fillTileVerticesUVs(BOTTOM_LEFT, false, 0, _snappedHeight - sliceRects[BOTTOM_LEFT].height, sliceRects[BOTTOM_LEFT].width, sliceRects[BOTTOM_LEFT].height);
			fillTileVerticesUVs(BOTTOM_RIGHT, false, _snappedWidth - sliceRects[BOTTOM_RIGHT].width, _snappedHeight - sliceRects[BOTTOM_RIGHT].height, sliceRects[BOTTOM_RIGHT].width, sliceRects[BOTTOM_RIGHT].height);
		}
		
		regen = false;
	}
	
	function blitTileOnCanvas(TileIndex:Int, Stretch:Bool, X:Float, Y:Float, Width:Float, Height:Float):Void
	{
		var tile:FlxGraphic = slices[TileIndex];
		
		if (tile != null)
		{
			FlxSpriteUtil.flashGfx.clear();
			
			_matrix.identity();
			
			if (Stretch)
				_matrix.scale(Width / tile.width, Height / tile.height);
			
			_matrix.translate(X, Y);
			FlxSpriteUtil.flashGfx.beginBitmapFill(tile.bitmap, _matrix);
			
			FlxSpriteUtil.flashGfx.drawRect(X, Y, Width, Height);
			renderSprite.pixels.draw(FlxSpriteUtil.flashGfxSprite, null, colorTransform);
			FlxSpriteUtil.flashGfx.clear();
		}
	}
	
	function fillTileVerticesUVs(TileIndex:Int, Stretch:Bool, X:Float, Y:Float, Width:Float, Height:Float):Void
	{
		var tile:FlxGraphic = slices[TileIndex];
		
		if (tile != null)
		{
			var sliceV:DrawData<Float> = sliceVertices[TileIndex];
			var sliceUVs:DrawData<Float> = sliceUVTs[TileIndex];
			
			sliceV[0] = X;
			sliceV[1] = Y;
			sliceV[2] = X + Width;
			sliceV[3] = Y;
			sliceV[4] = X + Width;
			sliceV[5] = Y + Height;
			sliceV[6] = X;
			sliceV[7] = Y + Height;
			
			if (Stretch)
			{
				sliceUVs[0] = 0;
				sliceUVs[1] = 0;
				sliceUVs[2] = 1;
				sliceUVs[3] = 0;
				sliceUVs[4] = 1;
				sliceUVs[5] = 1;
				sliceUVs[6] = 0;
				sliceUVs[7] = 1;
			}
			else
			{
				sliceUVs[0] = 0;
				sliceUVs[1] = 0;
				sliceUVs[2] = Width / tile.width;
				sliceUVs[3] = 0;
				sliceUVs[4] = Width / tile.width;
				sliceUVs[5] = Height / tile.height;
				sliceUVs[6] = 0;
				sliceUVs[7] = Height / tile.height;
			}
		}
	}
	
	function regenSliceFrames():Void
	{
		if (!regenSlices || graphic == null || sliceRect == null)
			return;
		
		var sourceWidth:Int = graphic.width;
		var sourceHeight:Int = graphic.height;
		
		var rectX:Float = Std.int(FlxMath.bound(sliceRect.x, 0, sourceWidth));
		var rectY:Float = Std.int(FlxMath.bound(sliceRect.y, 0, sourceHeight));
		
		var rectX2:Float = Std.int(FlxMath.bound(sliceRect.right, rectX, sourceWidth));
		var rectY2:Float = Std.int(FlxMath.bound(sliceRect.bottom, rectY, sourceHeight));
		
		// fill all 9 slice rectangles:
		var xArray:Array<Float> = [0, rectX, rectX2, sourceWidth];
		var yArray:Array<Float> = [0, rectY, rectY2, sourceHeight];
		
		for (i in 0...3)
		{
			for (j in 0...3)
			{
				rectX = xArray[j];
				rectX2 = xArray[j + 1];
				rectY = yArray[i];
				rectY2 = yArray[i + 1];
				
				sliceRects[i * 3 + j].set(rectX, rectY, rectX2 - rectX, rectY2 - rectY);
			}
		}
		
		slices = FlxDestroyUtil.destroyArray(slices);
		slices = [];
		
		for (i in 0...9)
		{
			var tempRect:FlxRect = sliceRects[i];
			
			if (tempRect.width > 0 && tempRect.height > 0)
			{
				helperFrame = graphic.imageFrame.frame.subFrameTo(tempRect, helperFrame);
				slices[i] = FlxGraphic.fromFrame(helperFrame, true, null, false);
			}
		}
		
		regenSlices = false;
	}
	
	override public function draw():Void
	{
		if (regen)
			regenGraphic();
		
		if (FlxG.renderBlit)
		{
			renderSprite.x = x;
			renderSprite.y = y;
			renderSprite.scale.copyFrom(scale);
			renderSprite.scrollFactor.set(scrollFactor.x, scrollFactor.y);
			renderSprite.cameras = cameras;
			renderSprite.draw();
		}
		else
		{
			for (camera in cameras)
			{
				if (!camera.visible || !camera.exists)
					continue;
				
				getScreenPosition(_point, camera);
				
				for (i in 0...9)
					drawTileOnCamera(i, camera);
			}
		}
	}
	
	inline function drawTileOnCamera(TileIndex:Int, Camera:FlxCamera):Void
	{
		if (slices[TileIndex] != null)
			Camera.drawTriangles(slices[TileIndex], sliceVertices[TileIndex], indices, sliceUVTs[TileIndex], colors, _point, blend, repeat, antialiasing);
	}
	
	override function set_alpha(Alpha:Float):Float
	{
		var newAlpha:Float = super.set_alpha(Alpha);
		
		if (FlxG.renderBlit && renderSprite != null)
			renderSprite.alpha = newAlpha;
		else if (FlxG.renderTile)
		{
			var c:FlxColor = color;
			c.alphaFloat = newAlpha;
			
			for (i in 0...4)
				colors[i] = c;
		}
		
		return newAlpha;
	}

	override function set_color(Color:FlxColor):FlxColor
	{
		if (FlxG.renderBlit && renderSprite != null)
			renderSprite.color = Color;
		else if (FlxG.renderTile)
		{
			var newColor:FlxColor = Color;
			newColor.alphaFloat = alpha;
			
			for (i in 0...4)
				colors[i] = newColor;
		}
		
		return super.set_color(Color);
	}
	
	override function set_width(Width:Float):Float
	{
		if (Width <= 0)
			return Width;
		
		if (Width != width)
			regen = true;
		
		return super.set_width(Width);
	}
	
	override function set_height(Height:Float):Float
	{
		if (Height <= 0)
			return Height;
		
		if (Height != height)
			regen = true;
		
		return super.set_height(Height);
	}
	
	function set_snapWidth(Value:Bool):Bool
	{
		if (Value != snapWidth)
			regen = true;
		
		return snapWidth = Value;
	}
	
	function set_snapHeight(Value:Bool):Bool
	{
		if (Value != snapHeight)
			regen = true;
		
		return snapHeight = Value;
	}
	
	function set_stretchLeft(Value:Bool):Bool
	{
		if (Value != stretchLeft)
			regen = true;
		
		return stretchLeft = Value;
	}
	
	function set_stretchTop(Value:Bool):Bool
	{
		if (Value != stretchTop)
			regen = true;
		
		return stretchTop = Value;
	}
	
	function set_stretchRight(Value:Bool):Bool
	{
		if (Value != stretchRight)
			regen = true;
		
		return stretchRight = Value;
	}
	
	function set_stretchBottom(Value:Bool):Bool
	{
		if (Value != stretchBottom)
			regen = true;
		
		return stretchBottom = Value;
	}
	
	function set_stretchCenter(Value:Bool):Bool
	{
		if (Value != stretchCenter)
			regen = true;
		
		return stretchCenter = Value;
	}
	
	function set_sliceRect(Value:FlxRect):FlxRect
	{
		regen = regenSlices = true;
		return sliceRect = Value;
	}
	
	function get_snappedWidth():Float
	{
		if (regen)
			regenGraphic();
		
		return _snappedWidth;
	}
	
	function get_snappedHeight():Float
	{
		if (regen)
			regenGraphic();
		
		return _snappedHeight;
	}
}
