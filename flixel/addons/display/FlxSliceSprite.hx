package flixel.addons.display;

import flixel.FlxSprite;
import flixel.FlxStrip;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.render.common.DrawItem.DrawData;
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
#if (openfl >= "4.0.0")
class FlxSliceSprite extends FlxSprite
{
	private static inline var TOP_LEFT:Int = 0;
	private static inline var TOP:Int = 1;
	private static inline var TOP_RIGHT:Int = 2;
	private static inline var LEFT:Int = 3;
	private static inline var CENTER:Int = 4;
	private static inline var RIGHT:Int = 5;
	private static inline var BOTTOM_LEFT:Int = 6;
	private static inline var BOTTOM:Int = 7;
	private static inline var BOTTOM_RIGHT:Int = 8;
	
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
	 * Rectangle that defines slice grid.
	 */
	public var sliceRect(default, set):FlxRect;
	
	/**
	 * Graohic for slicing.
	 */
	public var sliceGraphic(default, set):FlxGraphic;
	
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
	private var slices:Array<FlxGraphic> = [];
	/**
	 * Internal array of FlxRect objects for each element of slice grid.
	 */
	private var sliceRects:Array<FlxRect> = [];
	
	/**
	 * Rectangles for each part of sliced sprite. Used in tile render mode only.
	 */
	private var sliceQuads:Array<FlxRect> = [];
	/**
	 * UV coordinates for each part of sliced sprite. Used in tile render mode only.
	 */
	private var sliceUVs:Array<FlxRect> = [];
	/**
	 * Helper point which is used for rendering in tile render mode.
	 */
	private var slicePoint:FlxPoint;
	
	private var regen:Bool = true;
	
	private var regenSlices:Bool = true;
	
	private var helperFrame:FlxFrame;
	
	private var _snappedWidth:Float = -1;
	private var _snappedHeight:Float = -1;
	
	public function new(Graphic:FlxGraphicAsset, SliceRect:FlxRect, Width:Float, Height:Float)
	{
		super();
		
		for (i in 0...9)
		{
			sliceRects[i] = FlxRect.get();
			
			if (FlxG.renderTile)
			{
				sliceQuads[i] = FlxRect.get();
				sliceUVs[i] = FlxRect.get();
			}
		}
		
		slicePoint = FlxPoint.get();
		sliceRect = SliceRect;
		loadGraphic(Graphic);
		
		width = Width;
		height = Height;
	}
	
	override public function destroy():Void
	{
		sliceGraphic = null;
		sliceRect = null;
		
		sliceRects = FlxDestroyUtil.putArray(sliceRects);
		sliceQuads = FlxDestroyUtil.putArray(sliceQuads);
		sliceUVs = FlxDestroyUtil.putArray(sliceUVs);
		slicePoint = FlxDestroyUtil.put(slicePoint);
		slices = FlxDestroyUtil.destroyArray(slices);
		helperFrame = FlxDestroyUtil.destroy(helperFrame);
		
		super.destroy();
	}
	
	override public function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String):FlxSprite
	{
		sliceGraphic = FlxG.bitmap.add(Graphic);
		return this;
	}
	
	public function loadFrame(Frame:FlxFrame):FlxSliceSprite
	{
		sliceGraphic = FlxGraphic.fromFrame(Frame);
		return this;
	}
	
	private function set_sliceGraphic(Value:FlxGraphic):FlxGraphic
	{
		var oldGraphic:FlxGraphic = sliceGraphic;
		
		if ((sliceGraphic != Value) && (Value != null))
		{
			Value.useCount++;
			regen = regenSlices = true;
		}
		
		if ((oldGraphic != null) && (oldGraphic != Value))
		{
			oldGraphic.useCount--;
		}
		
		return sliceGraphic = Value;
	}
	
	private function regenGraphic():Void
	{
		if (!regen || sliceGraphic == null)
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
			if (graphic == null || (graphic.width != Std.int(_snappedWidth) || graphic.height != Std.int(_snappedHeight)))
			{
				makeGraphic(Std.int(_snappedWidth), Std.int(_snappedHeight), FlxColor.TRANSPARENT, true);
			}
			else
			{
				_flashRect2.setTo(0, 0, _snappedWidth, _snappedHeight);
				pixels.fillRect(_flashRect2, FlxColor.TRANSPARENT);
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
			
			dirty = true;
		}
		else
		{
			fillTileVerticesUVs(CENTER, stretchCenter, sliceRects[CENTER].x, sliceRects[CENTER].y, centerWidth, centerHeight);
			fillTileVerticesUVs(TOP, stretchTop, sliceRects[TOP].x, 0, centerWidth, sliceRects[TOP].height);
			fillTileVerticesUVs(BOTTOM, stretchBottom, sliceRects[BOTTOM].x, _snappedHeight - sliceRects[BOTTOM].height, centerWidth, sliceRects[BOTTOM].height);
			fillTileVerticesUVs(LEFT, stretchLeft, 0, sliceRects[LEFT].y, sliceRects[LEFT].width, centerHeight);
			fillTileVerticesUVs(RIGHT, stretchRight, _snappedWidth - sliceRects[RIGHT].width, sliceRects[RIGHT].y, sliceRects[RIGHT].width, centerHeight);
			fillTileVerticesUVs(TOP_LEFT, false, 0, 0, sliceRects[TOP_LEFT].width, sliceRects[TOP_LEFT].height);
			fillTileVerticesUVs(TOP_RIGHT, false, _snappedWidth - sliceRects[TOP_RIGHT].width, 0, sliceRects[TOP_RIGHT].width, sliceRects[TOP_RIGHT].height);
			fillTileVerticesUVs(BOTTOM_LEFT, false, 0, _snappedHeight - sliceRects[BOTTOM_LEFT].height, sliceRects[BOTTOM_LEFT].width, sliceRects[BOTTOM_LEFT].height);
			fillTileVerticesUVs(BOTTOM_RIGHT, false, _snappedWidth - sliceRects[BOTTOM_RIGHT].width, _snappedHeight - sliceRects[BOTTOM_RIGHT].height, sliceRects[BOTTOM_RIGHT].width, sliceRects[BOTTOM_RIGHT].height);
		}
		
		regen = false;
	}
	
	private function blitTileOnCanvas(TileIndex:Int, Stretch:Bool, X:Float, Y:Float, Width:Float, Height:Float):Void
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
			pixels.draw(FlxSpriteUtil.flashGfxSprite, null, null);
			FlxSpriteUtil.flashGfx.clear();
		}
	}
	
	private function fillTileVerticesUVs(TileIndex:Int, Stretch:Bool, X:Float, Y:Float, Width:Float, Height:Float):Void
	{
		var tile:FlxGraphic = slices[TileIndex];
		
		if (tile != null)
		{
			var quad:FlxRect = sliceQuads[TileIndex];
			var uv:FlxRect = sliceUVs[TileIndex];
			
			quad.set(X, Y, Width, Height);
			
			if (Stretch)
				uv.set(0, 0, 1, 1);
			else
				uv.set(0, 0, Width / tile.width, Height / tile.height);
		}
	}
	
	private function regenSliceFrames():Void
	{
		if (!regenSlices || sliceGraphic == null || sliceRect == null)
			return;
		
		var sourceWidth:Int = sliceGraphic.width;
		var sourceHeight:Int = sliceGraphic.height;
		
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
				helperFrame = sliceGraphic.imageFrame.frame.subFrameTo(tempRect, helperFrame);
				slices[i] = FlxGraphic.fromFrame(helperFrame, true, null, false);
			}
		}
		
		regenSlices = false;
	}
	
	override public function draw():Void
	{
		if (regen)
		{
			regenGraphic();
			dirty = true;
		}
		
		if (FlxG.renderBlit)
		{
			super.draw();
		}
		else
		{
			for (camera in cameras)
			{
				if (!camera.visible || !camera.exists || !isOnScreen(camera))
					continue;
				
				getScreenPosition(_point, camera).subtractPoint(offset);
				
				_matrix.identity();
				_matrix.translate(-origin.x, -origin.y);
				_matrix.scale(scale.x, scale.y);
				
				updateTrig();
				
				if (angle != 0)
					_matrix.rotateWithTrig(_cosAngle, _sinAngle);
				
				_point.add(origin.x, origin.y);
				_matrix.translate(_point.x, _point.y);
				
				if (isPixelPerfectRender(camera))
				{
					_matrix.tx = Math.floor(_matrix.tx);
					_matrix.ty = Math.floor(_matrix.ty);
				}
				
				var sliceGraphic:FlxGraphic;
				var quad:FlxRect;
				var uv:FlxRect;
				
				for (i in 0...9)
				{
					sliceGraphic = slices[i];
					
					if (sliceGraphic != null)
					{
						quad = sliceQuads[i];
						uv = sliceUVs[i];
						
						slicePoint.set(quad.x, quad.y);
						slicePoint.transform(_matrix);
						
						_matrix.translate(slicePoint.x, slicePoint.y);
						
						camera.drawUVQuad(sliceGraphic, quad, uv, _matrix, colorTransform, blend, smoothing, shader);
						
						_matrix.translate( -slicePoint.x, -slicePoint.y);
					}
				}
				
				#if FLX_DEBUG
				FlxBasic.visibleCount++;
				#end
			}
		}
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
	
	private function set_snapWidth(Value:Bool):Bool
	{
		if (Value != snapWidth)
			regen = true;
		
		return snapWidth = Value;
	}
	
	private function set_snapHeight(Value:Bool):Bool
	{
		if (Value != snapHeight)
			regen = true;
		
		return snapHeight = Value;
	}
	
	private function set_stretchLeft(Value:Bool):Bool
	{
		if (Value != stretchLeft)
			regen = true;
		
		return stretchLeft = Value;
	}
	
	private function set_stretchTop(Value:Bool):Bool
	{
		if (Value != stretchTop)
			regen = true;
		
		return stretchTop = Value;
	}
	
	private function set_stretchRight(Value:Bool):Bool
	{
		if (Value != stretchRight)
			regen = true;
		
		return stretchRight = Value;
	}
	
	private function set_stretchBottom(Value:Bool):Bool
	{
		if (Value != stretchBottom)
			regen = true;
		
		return stretchBottom = Value;
	}
	
	private function set_stretchCenter(Value:Bool):Bool
	{
		if (Value != stretchCenter)
			regen = true;
		
		return stretchCenter = Value;
	}
	
	private function set_sliceRect(Value:FlxRect):FlxRect
	{
		regen = regenSlices = true;
		return sliceRect = Value;
	}
	
	private function get_snappedWidth():Float
	{
		if (regen)
			regenGraphic();
		
		return _snappedWidth;
	}
	
	private function get_snappedHeight():Float
	{
		if (regen)
			regenGraphic();
		
		return _snappedHeight;
	}
}
#else
class FlxSliceSprite extends FlxStrip
{
	private static inline var TOP_LEFT:Int = 0;
	private static inline var TOP:Int = 1;
	private static inline var TOP_RIGHT:Int = 2;
	private static inline var LEFT:Int = 3;
	private static inline var CENTER:Int = 4;
	private static inline var RIGHT:Int = 5;
	private static inline var BOTTOM_LEFT:Int = 6;
	private static inline var BOTTOM:Int = 7;
	private static inline var BOTTOM_RIGHT:Int = 8;
	
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
	private var slices:Array<FlxGraphic>;
	/**
	 * Internal array of FlxRect objects for each element of slice grid.
	 */
	private var sliceRects:Array<FlxRect>;
	
	private var sliceVertices:Array<DrawData<Float>>;
	private var sliceUVTs:Array<DrawData<Float>>;
	
	/**
	 * Helper sprite, which does actual rendering in blit render mode.
	 */
	private var renderSprite:FlxSprite;
	
	private var regen:Bool = true;
	
	private var regenSlices:Bool = true;
	
	private var helperFrame:FlxFrame;
	
	private var _snappedWidth:Float = -1;
	private var _snappedHeight:Float = -1;
	
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
	
	private function regenGraphic():Void
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
			fillTileVerticesUVs(BOTTOM, stretchBottom, sliceRects[BOTTOM].x, _snappedHeight - sliceRects[BOTTOM].height, centerWidth, sliceRects[BOTTOM].height);
			fillTileVerticesUVs(LEFT, stretchLeft, 0, sliceRects[LEFT].y, sliceRects[LEFT].width, centerHeight);
			fillTileVerticesUVs(RIGHT, stretchRight, _snappedWidth - sliceRects[RIGHT].width, sliceRects[RIGHT].y, sliceRects[RIGHT].width, centerHeight);
			fillTileVerticesUVs(TOP_LEFT, false, 0, 0, sliceRects[TOP_LEFT].width, sliceRects[TOP_LEFT].height);
			fillTileVerticesUVs(TOP_RIGHT, false, _snappedWidth - sliceRects[TOP_RIGHT].width, 0, sliceRects[TOP_RIGHT].width, sliceRects[TOP_RIGHT].height);
			fillTileVerticesUVs(BOTTOM_LEFT, false, 0, _snappedHeight - sliceRects[BOTTOM_LEFT].height, sliceRects[BOTTOM_LEFT].width, sliceRects[BOTTOM_LEFT].height);
			fillTileVerticesUVs(BOTTOM_RIGHT, false, _snappedWidth - sliceRects[BOTTOM_RIGHT].width, _snappedHeight - sliceRects[BOTTOM_RIGHT].height, sliceRects[BOTTOM_RIGHT].width, sliceRects[BOTTOM_RIGHT].height);
		}
		
		regen = false;
	}
	
	private function blitTileOnCanvas(TileIndex:Int, Stretch:Bool, X:Float, Y:Float, Width:Float, Height:Float):Void
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
	
	private function fillTileVerticesUVs(TileIndex:Int, Stretch:Bool, X:Float, Y:Float, Width:Float, Height:Float):Void
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
	
	private function regenSliceFrames():Void
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
		{
			regenGraphic();
			dirty = true;
		}
		
		if (FlxG.renderBlit)
		{
			renderSprite.x = x;
			renderSprite.y = y;
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
				
				_matrix.identity();
				_matrix.translate(_point.x, _point.y);
				
				for (i in 0...9)
					drawTileOnCamera(i, camera);
			}
		}
	}
	
	private inline function drawTileOnCamera(TileIndex:Int, Camera:FlxCamera):Void
	{
		if (slices[TileIndex] != null)
			Camera.drawTriangles(slices[TileIndex], sliceVertices[TileIndex], indices, sliceUVTs[TileIndex], _matrix, colorTransform, blend, repeat, smoothing);
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
	
	private function set_snapWidth(Value:Bool):Bool
	{
		if (Value != snapWidth)
			regen = true;
		
		return snapWidth = Value;
	}
	
	private function set_snapHeight(Value:Bool):Bool
	{
		if (Value != snapHeight)
			regen = true;
		
		return snapHeight = Value;
	}
	
	private function set_stretchLeft(Value:Bool):Bool
	{
		if (Value != stretchLeft)
			regen = true;
		
		return stretchLeft = Value;
	}
	
	private function set_stretchTop(Value:Bool):Bool
	{
		if (Value != stretchTop)
			regen = true;
		
		return stretchTop = Value;
	}
	
	private function set_stretchRight(Value:Bool):Bool
	{
		if (Value != stretchRight)
			regen = true;
		
		return stretchRight = Value;
	}
	
	private function set_stretchBottom(Value:Bool):Bool
	{
		if (Value != stretchBottom)
			regen = true;
		
		return stretchBottom = Value;
	}
	
	private function set_stretchCenter(Value:Bool):Bool
	{
		if (Value != stretchCenter)
			regen = true;
		
		return stretchCenter = Value;
	}
	
	private function set_sliceRect(Value:FlxRect):FlxRect
	{
		regen = regenSlices = true;
		return sliceRect = Value;
	}
	
	private function get_snappedWidth():Float
	{
		if (regen)
			regenGraphic();
		
		return _snappedWidth;
	}
	
	private function get_snappedHeight():Float
	{
		if (regen)
			regenGraphic();
		
		return _snappedHeight;
	}
}
#end
