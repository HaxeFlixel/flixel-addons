package flixel.addons.display;

import flixel.FlxStrip;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMath;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxRect;
import flixel.util.FlxSpriteUtil;

/**
 * Tiled sprite which displays repeated and clipped graphic.
 * @author Zaphod
 * @since  2.1.0
 */
class FlxTiledSprite extends FlxStrip
{
	/**
	 * The x-offset of the texture
	 */
	public var scrollX(default, set):Float = 0;
	
	/**
	 * The y-offset of the texture.
	 */
	public var scrollY(default, set):Float = 0;
	
	/**
	 * Repeat texture on x axis. Default is true
	 */
	public var repeatX(default, set):Bool = true;
	
	/**
	 * Repeat texture on y axis. Default is true
	 */
	public var repeatY(default, set):Bool = true;
	
	/**
	 * Helper sprite, which does actual rendering in blit render mode.
	 */
	var renderSprite:FlxSprite;
	
	var regen:Bool = true;
	
	var graphicVisible:Bool = true;
	
	public function new(?graphic:FlxGraphicAsset, width:Float, height:Float, repeatX = true, repeatY = true)
	{
		super();
		
		repeat = true;
		
		indices[0] = 0;
		indices[1] = 1;
		indices[2] = 2;
		indices[3] = 2;
		indices[4] = 3;
		indices[5] = 0;
		
		uvtData[0] = 0;
		uvtData[1] = 0;
		uvtData[2] = 1;
		uvtData[3] = 0;
		uvtData[4] = 1;
		uvtData[5] = 1;
		uvtData[6] = 0;
		uvtData[7] = 1;
		
		vertices[0] = 0;
		vertices[1] = 0;
		vertices[2] = width;
		vertices[3] = 0;
		vertices[4] = width;
		vertices[5] = height;
		vertices[6] = 0;
		vertices[7] = height;
		
		this.width = width;
		this.height = height;
		
		this.repeatX = repeatX;
		this.repeatY = repeatY;
		
		if (graphic != null)
			loadGraphic(graphic);
	}
	
	override function destroy():Void
	{
		renderSprite = FlxDestroyUtil.destroy(renderSprite);
		super.destroy();
	}
	
	override function loadGraphic(graphic, animated = false, width = 0, height = 0, unique = false, ?key:String):FlxSprite
	{
		this.graphic = FlxG.bitmap.add(graphic);
		return this;
	}
	
	public function loadFrame(frame:FlxFrame):FlxTiledSprite
	{
		graphic = FlxGraphic.fromFrame(frame);
		return this;
	}
	
	override function set_clipRect(value:FlxRect):FlxRect
	{
		regen = true;
		
		return super.set_clipRect(value);
	}
	
	override function set_graphic(value:FlxGraphic):FlxGraphic
	{
		if (graphic != value)
			regen = true;
		
		return super.set_graphic(value);
	}
	
	function regenGraphic():Void
	{
		if (!regen || graphic == null)
			return;
		
		if (FlxG.renderBlit)
		{
			updateRenderSprite();
		}
		else
		{
			updateVerticesData();
		}
		
		regen = false;
	}
	
	override function draw():Void
	{
		if (regen)
			regenGraphic();
		
		if (graphicVisible)
		{
			if (FlxG.renderBlit)
			{
				renderSprite.x = x;
				renderSprite.y = y;
				renderSprite.scrollFactor.set(scrollFactor.x, scrollFactor.y);
				renderSprite._cameras = _cameras;
				renderSprite.draw();
			}
			else
			{
				super.draw();
			}
		}
		
		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}
	
	#if FLX_DEBUG
	/**
	 * Copied exactly from `FlxObject`, to avoid any future changes to `FlxStrip`'s debug drawing
	 */
	override function drawDebug()
	{
		if (ignoreDrawDebug)
			return;
		
		final drawPath = path != null && !path.ignoreDrawDebug;
		
		for (camera in getCamerasLegacy())
		{
			drawDebugOnCamera(camera);
			
			if (drawPath)
			{
				path.drawDebugOnCamera(camera);
			}
		}
	}
	#end
	
	function updateRenderSprite():Void
	{
		graphicVisible = true;
		
		if (renderSprite == null)
			renderSprite = new FlxSprite();
		
		final drawRect = getDrawRect();
		drawRect.x = Std.int(drawRect.x);
		drawRect.y = Std.int(drawRect.y);
		drawRect.width = Std.int(drawRect.width);
		drawRect.height = Std.int(drawRect.height);
		//TODO: rect.int() or smth
		
		if (drawRect.width * drawRect.height == 0)
		{
			graphicVisible = false;
			drawRect.put();
			return;
		}
		
		if (renderSprite.width != drawRect.width || renderSprite.height != drawRect.height)
		{
			renderSprite.makeGraphic(Std.int(drawRect.width), Std.int(drawRect.height), FlxColor.TRANSPARENT, true);
		}
		else
		{
			renderSprite.pixels.fillRect(renderSprite.pixels.rect, FlxColor.TRANSPARENT);
		}
		
		FlxSpriteUtil.flashGfx.clear();
		
		if (scrollX != 0 || scrollY != 0)
		{
			_matrix.identity();
			_matrix.tx = Math.round(scrollX);
			_matrix.ty = Math.round(scrollY);
			FlxSpriteUtil.flashGfx.beginBitmapFill(graphic.bitmap, _matrix);
		}
		else
		{
			FlxSpriteUtil.flashGfx.beginBitmapFill(graphic.bitmap);
		}
		
		FlxSpriteUtil.flashGfx.drawRect(drawRect.x, drawRect.y, drawRect.width, drawRect.height);
		renderSprite.pixels.draw(FlxSpriteUtil.flashGfxSprite, null, colorTransform);
		FlxSpriteUtil.flashGfx.clear();
		renderSprite.dirty = true;
	}
	
	function updateVerticesData():Void
	{
		if (graphic == null)
			return;
		
		final frame:FlxFrame = graphic.imageFrame.frame;
		graphicVisible = true;
		
		final drawRect = getDrawRect();
		
		if (drawRect.width * drawRect.height == 0)
		{
			graphicVisible = false;
			drawRect.put();
			return;
		}
		
		// Texture coordinates (UVs)
		final rectUX:Float = (drawRect.x - scrollX) / frame.sourceSize.x;
		final rectVX:Float = rectUX + (drawRect.width-drawRect.x) / frame.sourceSize.x;
		final rectUY:Float = (drawRect.y - scrollY) / frame.sourceSize.y;
		final rectVY:Float = rectUY + (drawRect.height - drawRect.y) / frame.sourceSize.y;
		
		vertices[0] = drawRect.x;
		vertices[2] = drawRect.width;
		vertices[4] = drawRect.width;
		vertices[6] = drawRect.x;
		
		uvtData[0] = rectUX;
		uvtData[2] = rectVX;
		uvtData[4] = rectVX;
		uvtData[6] = rectUX;
		
		vertices[1] = drawRect.y;
		vertices[3] = drawRect.y;
		vertices[5] = drawRect.height;
		vertices[7] = drawRect.height;
		
		uvtData[1] = rectUY;
		uvtData[3] = rectUY;
		uvtData[5] = rectVY;
		uvtData[7] = rectVY;
		
		drawRect.put();
	}
	
	function getDrawRect(?result:FlxRect):FlxRect
	{
		if (result == null)
			result = FlxRect.get();
		
		final frame:FlxFrame = graphic.imageFrame.frame;
		final sourceSizeX = FlxG.renderBlit ? graphic.bitmap.width : frame.sourceSize.x;
		final sourceSizeY = FlxG.renderBlit ? graphic.bitmap.height : frame.sourceSize.y;
		
		result.x = (repeatX ? 0 : scrollX);
		if (clipRect != null)
		{
			result.x += clipRect.x;
		}
		result.x = FlxMath.bound(result.x, 0, width);
		
		result.width = (repeatX ? result.x + width : scrollX + sourceSizeX);
		if (clipRect != null)
		{
			result.width = FlxMath.bound(result.width, clipRect.x, clipRect.right);
		}
		result.width = FlxMath.bound(result.width, 0, width);
		
		result.y = (repeatY ? 0 : scrollY);
		if (clipRect != null) 
		{
			result.y += clipRect.y;
		}
		result.y = FlxMath.bound(result.y, 0, height);
		
		result.height = (repeatY ? result.y + height : scrollY + sourceSizeY);
		if (clipRect != null)
		{
			result.height = FlxMath.bound(result.height, clipRect.y, clipRect.bottom);
		}
		result.height = FlxMath.bound(result.height, 0, height);
		
		return result;
	}
	
	override function set_width(value:Float):Float
	{
		if (value <= 0)
			return value;
		
		if (value != width)
			regen = true;
		
		return super.set_width(value);
	}
	
	override function set_height(value:Float):Float
	{
		if (value <= 0)
			return value;
		
		if (value != height)
			regen = true;
		
		return super.set_height(value);
	}
	
	function set_scrollX(value:Float):Float
	{
		if (value != scrollX)
			regen = true;
		
		return scrollX = value;
	}
	
	function set_scrollY(value:Float):Float
	{
		if (value != scrollY)
			regen = true;
		
		return scrollY = value;
	}
	
	function set_repeatX(value:Bool):Bool
	{
		if (value != repeatX)
			regen = true;
		
		return repeatX = value;
	}
	
	function set_repeatY(value:Bool):Bool
	{
		if (value != repeatY)
			regen = true;
		
		return repeatY = value;
	}
}
