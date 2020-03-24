package flixel.addons.display;

import flixel.FlxSprite;
import flixel.FlxStrip;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
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

	static var helperRect:FlxRect = new FlxRect();
	static var helperSize:FlxPoint = new FlxPoint();
	static var helperDst:FlxPoint = new FlxPoint();
	static var helperBdSize:FlxPoint = new FlxPoint();

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
	 * Whether to fill center part of sprite.
	 */
	public var fillCenter(default, set):Bool = true;

	/**
	 * Rectangle that defines slice grid:
	 */
	public var sliceRect(default, set):FlxRect;

	/**
	 * Rectangle that defines what part of source image to use as a texture for slicing.
	 */
	public var sourceRect(default, set):FlxRect;

	/**
	 * Actual width of the sprite which will be visible.
	 * Its calculation is based on snapWidth and sliceRect values.
	 */
	public var snappedWidth(get, never):Float;

	/**
	 * Actual height of the sprite which will be visible.
	 * Its calculation is based on snapHeight and sliceRect values.
	 */
	public var snappedHeight(get, never):Float;

	/**
	 * Internal array of FlxRect objects for each element of slice grid.
	 */
	var sliceRects:Array<FlxRect>;

	/**
	 * Helper sprite, which does actual rendering in blit render mode.
	 */
	var renderSprite:FlxSprite;

	var regen:Bool = true;

	var regenSlices:Bool = true;

	var helperFrame:FlxFrame;

	var _snappedWidth:Float = -1;
	var _snappedHeight:Float = -1;

	/**
	 * Current number of vertices
	 */
	var numVertices:Int = 0;

	public function new(Graphic:FlxGraphicAsset, SliceRect:FlxRect, Width:Float, Height:Float, ?SourceRect:FlxRect)
	{
		super();

		if (renderSprite == null)
			renderSprite = new FlxSprite();

		sliceRects = [];

		for (i in 0...9)
			sliceRects[i] = new FlxRect();

		repeat = true;
		sliceRect = SliceRect;
		sourceRect = SourceRect;
		loadGraphic(Graphic);

		width = Width;
		height = Height;
	}

	override public function destroy():Void
	{
		sliceRect = null;
		sliceRects = null;
		helperFrame = FlxDestroyUtil.destroy(helperFrame);
		renderSprite = FlxDestroyUtil.destroy(renderSprite);

		super.destroy();
	}

	override public function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false,
			?Key:String):FlxSprite
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
			regenSliceRects();

		var topLeft:FlxRect = sliceRects[TOP_LEFT];
		var topMiddle:FlxRect = sliceRects[TOP];
		var topRight:FlxRect = sliceRects[TOP_RIGHT];

		var middleLeft:FlxRect = sliceRects[LEFT];
		var middle:FlxRect = sliceRects[CENTER];
		var middleRight:FlxRect = sliceRects[RIGHT];

		var bottomLeft:FlxRect = sliceRects[BOTTOM_LEFT];
		var bottomMiddle:FlxRect = sliceRects[BOTTOM];
		var bottomRight:FlxRect = sliceRects[BOTTOM_RIGHT];

		var centerWidth:Float = width - middleLeft.width - middleRight.width;
		var centerHeight:Float = height - topMiddle.height - bottomMiddle.height;

		if (snapWidth)
		{
			centerWidth = Math.floor((width - middleLeft.width - middleRight.width) / middle.width) * middle.width;
			centerWidth = Math.max(centerWidth, middle.width);
		}

		if (snapHeight)
		{
			centerHeight = Math.floor((height - topMiddle.height - bottomMiddle.height) / middle.height) * middle.height;
			centerHeight = Math.max(centerHeight, middle.height);
		}

		_snappedWidth = centerWidth + middleLeft.width + middleRight.width;
		_snappedHeight = centerHeight + topMiddle.height + bottomMiddle.height;

		var centerX = topLeft.width;
		var centerY = topLeft.height;
		
		var bdSize:FlxPoint = helperBdSize.set(graphic.width, graphic.height);
		var dst:FlxPoint = helperDst;
		var slice:FlxRect = helperRect;
		var size:FlxPoint = helperSize;

		var numHorizontal:Int = Math.ceil((_snappedWidth - topLeft.width - topRight.width) / topMiddle.width);
		var numVertical:Int = Math.ceil((_snappedHeight - topLeft.height - bottomLeft.height) / middleLeft.height);
	
		vertices = new DrawData<Float>();
		uvtData = new DrawData<Float>();
		indices = new DrawData<Int>();
		colors = new DrawData<Int>();
		numVertices = 0;

		if (fillCenter)
		{
			// fill central tiles:
			slice.copyFrom(middle);

			if (stretchCenter)
			{
				size.set(_snappedWidth - middleLeft.width - middleRight.width, _snappedHeight - topMiddle.height - bottomMiddle.height);
				dst.set(topLeft.width, topLeft.height);
				numVertices = stretchSlice(numVertices, slice, dst, bdSize, size);
			}
			else
			{
				for (i in 0...numHorizontal)
				{
					slice.width = middle.width;
					if (i == numHorizontal - 1)
					{
						slice.width = _snappedWidth - middleLeft.width - middleRight.width - (numHorizontal - 1) * middle.width;
					}

					for (j in 0...numVertical)
					{
						slice.height = middle.height;
						if (j == numVertical - 1)
						{
							slice.height = _snappedHeight - topMiddle.height - bottomMiddle.height - (numVertical - 1) * middle.height;
						}

						size.set(slice.width, slice.height);
						dst.set(topLeft.width + i * middle.width, topLeft.height + j * middle.height);
						numVertices = stretchSlice(numVertices, slice, dst, bdSize, size);
					}
				}
			}
		}

		if (stretchTop)
		{
			slice.copyFrom(topMiddle);
			size.set(_snappedWidth - topLeft.width - topRight.width, topMiddle.height);
			dst.set(topLeft.width, 0);
			numVertices = stretchSlice(numVertices, slice, dst, bdSize, size);
		}
		else
		{
			for (i in 0...numHorizontal)
			{
				slice.copyFrom(topMiddle);
				if (i == numHorizontal - 1)
				{
					slice.width = _snappedWidth - topLeft.width - topRight.width - (numHorizontal - 1) * topMiddle.width;
				}

				size.set(slice.width, slice.height);
				dst.set(topLeft.width + i * topMiddle.width, 0);
				numVertices = stretchSlice(numVertices, slice, dst, bdSize, size);
			}
		}

		if (stretchBottom)
		{
			slice.copyFrom(bottomMiddle);
			dst.set(bottomLeft.width, _snappedHeight - bottomMiddle.height);
			size.set(_snappedWidth - bottomLeft.width - bottomRight.width, bottomMiddle.height);
			numVertices = stretchSlice(numVertices, slice, dst, bdSize, size);
		}
		else
		{
			for (i in 0...numHorizontal)
			{
				slice.copyFrom(bottomMiddle);
				if (i == numHorizontal - 1)
				{
					slice.width = _snappedWidth - bottomLeft.width - bottomRight.width - (numHorizontal - 1) * bottomMiddle.width;
				}

				dst.set(bottomLeft.width + i * bottomMiddle.width, _snappedHeight - bottomMiddle.height);
				size.set(slice.width, slice.height);
				numVertices = stretchSlice(numVertices, slice, dst, bdSize, size);
			}
		}

		if (stretchLeft)
		{
			slice.copyFrom(middleLeft);
			dst.set(0, topLeft.height);
			size.set(middleLeft.width, _snappedHeight - topLeft.height - bottomLeft.height);
			numVertices = stretchSlice(numVertices, slice, dst, bdSize, size);
		}
		else
		{
			for (i in 0...numVertical)
			{
				slice.copyFrom(middleLeft);
				if (i == numVertical - 1)
				{
					slice.height = _snappedHeight - topLeft.height - bottomLeft.height - (numVertical - 1) * middleLeft.height;
				}

				dst.set(0, topLeft.height + i * middleLeft.height);
				size.set(slice.width, slice.height);
				numVertices = stretchSlice(numVertices, slice, dst, bdSize, size);
			}
		}

		if (stretchRight)
		{
			slice.copyFrom(middleRight);
			dst.set(_snappedWidth - middleRight.width, topRight.height);
			size.set(middleRight.width, _snappedHeight - topRight.height - bottomRight.height);
			numVertices = stretchSlice(numVertices, slice, dst, bdSize, size);
		}
		else
		{
			for (i in 0...numVertical)
			{
				slice.copyFrom(middleRight);
				if (i == numVertical - 1)
				{
					slice.height = _snappedHeight - topRight.height - bottomRight.height - (numVertical - 1) * middleRight.height;
				}

				dst.set(_snappedWidth - middleRight.width, topRight.height + i * middleRight.height);
				size.set(slice.width, slice.height);
				numVertices = stretchSlice(numVertices, slice, dst, bdSize, size);
			}
		}

		// draw corners:
		// 1. top left
		dst.set(0, 0);
		size.set(topLeft.width, topLeft.height);
		numVertices = stretchSlice(numVertices, topLeft, dst, bdSize, size);
		// 2. bottom left
		dst.set(0, _snappedHeight - bottomLeft.height);
		size.set(bottomLeft.width, bottomLeft.height);
		numVertices = stretchSlice(numVertices, bottomLeft, dst, bdSize, size);
		// 3. top right
		dst.set(_snappedWidth - topRight.width, 0);
		size.set(topRight.width, topRight.height);
		numVertices = stretchSlice(numVertices, topRight, dst, bdSize, size);
		// 4. bottom right
		dst.set(_snappedWidth - bottomRight.width, _snappedHeight - bottomRight.height);
		size.set(bottomRight.width, bottomRight.height);
		numVertices = stretchSlice(numVertices, bottomRight, dst, bdSize, size);

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

			FlxSpriteUtil.flashGfx.clear();
			FlxSpriteUtil.flashGfx.beginBitmapFill(graphic.bitmap);
			FlxSpriteUtil.flashGfx.drawTriangles(vertices, indices, uvtData);
			FlxSpriteUtil.flashGfx.endFill();
			renderSprite.pixels.draw(FlxSpriteUtil.flashGfxSprite, null, colorTransform);
			FlxSpriteUtil.flashGfx.clear();

			renderSprite.dirty = true;
		}
		else
		{
			var c:FlxColor = color;
			c.alphaFloat = alpha;
			updateColors(c);
		}

		regen = false;
	}

	function stretchSlice(vertex:Int, slice:FlxRect, dst:FlxPoint, bdSize:FlxPoint, size:FlxPoint):Int
	{
		// there are 2 values per vertex:
		var vertexIndex:Int = 2 * vertex;
		var uvIndex:Int = vertexIndex;
		var colorIndex:Int = vertex;

		vertices[vertexIndex++] = dst.x;
		vertices[vertexIndex++] = dst.y;
		vertices[vertexIndex++] = dst.x + size.x;
		vertices[vertexIndex++] = dst.y;
		vertices[vertexIndex++] = dst.x + size.x;
		vertices[vertexIndex++] = dst.y + size.y;
		vertices[vertexIndex++] = dst.x;
		vertices[vertexIndex++] = dst.y + size.y;

		uvtData[uvIndex++] = slice.x / bdSize.x;
		uvtData[uvIndex++] = slice.y / bdSize.y;

		uvtData[uvIndex++] = slice.right / bdSize.x;
		uvtData[uvIndex++] = slice.y / bdSize.y;

		uvtData[uvIndex++] = slice.right / bdSize.x;
		uvtData[uvIndex++] = slice.bottom / bdSize.y;

		uvtData[uvIndex++] = slice.x / bdSize.x;
		uvtData[uvIndex++] = slice.bottom / bdSize.y;

		// there are 6 indices per slice, which have 4 vertices per vertex:
		var indexPosition:Int = Math.round(6 * vertex / 4);

		indices[indexPosition++] = vertex + 0;
		indices[indexPosition++] = vertex + 1;
		indices[indexPosition++] = vertex + 2;
		indices[indexPosition++] = vertex + 0;
		indices[indexPosition++] = vertex + 2;
		indices[indexPosition++] = vertex + 3;

		return vertex + 4;
	}

	function regenSliceRects():Void
	{
		if (!regenSlices || graphic == null || sliceRect == null)
			return;

		var sourceWidth:Int = graphic.width;
		var sourceHeight:Int = graphic.height;

		var rectX:Float = Std.int(FlxMath.bound(sliceRect.x, 0, sourceWidth));
		var rectY:Float = Std.int(FlxMath.bound(sliceRect.y, 0, sourceHeight));

		var rectX2:Float = Std.int(FlxMath.bound(sliceRect.right, rectX, sourceWidth));
		var rectY2:Float = Std.int(FlxMath.bound(sliceRect.bottom, rectY, sourceHeight));

		var sourceX:Float = 0;
		var sourceY:Float = 0;

		if (sourceRect != null)
		{
			sourceX = Std.int(FlxMath.bound(sourceRect.x, 0, sourceWidth));
			sourceY = Std.int(FlxMath.bound(sourceRect.y, 0, sourceHeight));
			sourceWidth = Std.int(FlxMath.bound(sourceX + sourceRect.width, 0, sourceWidth));
			sourceHeight = Std.int(FlxMath.bound(sourceY + sourceRect.height, 0, sourceHeight));
		}

		rectX += sourceX;
		rectY += sourceY;

		rectX2 += sourceX;
		rectY2 += sourceY;

		// fill all 9 slice rectangles:
		var xArray:Array<Float> = [sourceX, rectX, rectX2, sourceWidth];
		var yArray:Array<Float> = [sourceY, rectY, rectY2, sourceHeight];

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
			super.draw();
		}
	}

	function updateColors(color:FlxColor):Void
	{
		for (i in 0...numVertices)
			colors[i] = color;
	}

	override function set_alpha(Alpha:Float):Float
	{
		if (alpha == Alpha)
			return Alpha;

		var newAlpha:Float = super.set_alpha(Alpha);

		if (FlxG.renderBlit && renderSprite != null)
			renderSprite.alpha = newAlpha;
		else if (FlxG.renderTile)
		{
			var c:FlxColor = color;
			c.alphaFloat = newAlpha;
			updateColors(c);
		}
		regen = true;
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
			updateColors(newColor);
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

	function set_fillCenter(Value:Bool):Bool
	{
		if (Value != fillCenter)
			regen = true;
		
		return fillCenter = Value;
	}

	function set_sliceRect(Value:FlxRect):FlxRect
	{
		regen = regenSlices = true;
		return sliceRect = Value;
	}

	function set_sourceRect(Value:FlxRect):FlxRect
	{
		regen = regenSlices = true;
		return sourceRect = Value;
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
