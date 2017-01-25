package flixel.addons.display;

import flixel.FlxStrip;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;

/**
 * Tiled sprite which displays repeated and clipped graphic.
 * @author Zaphod
 */
#if (openfl >= "4.0.0")
class FlxTiledSprite extends FlxSprite
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
	
	private var regen:Bool = true;
	
	private var graphicVisible:Bool = true;
	
	/**
	 * Quad rectangle. Rendering related.
	 */
	private var rect:FlxRect;
	
	/**
	 * Quad UV coordinates. Rendering related.
	 */
	private var uv:FlxRect;
	
	/**
	 * Graphic to tile sprite with.
	 */
	public var tileGraphic(default, set):FlxGraphic;
	
	public function new(?Graphic:FlxGraphicAsset, Width:Float, Height:Float, RepeatX:Bool = true, RepeatY:Bool = true) 
	{
		super();
		
		rect = FlxRect.get();
		uv = FlxRect.get();
		
		width = Width;
		height = Height;
		
		repeatX = RepeatX;
		repeatY = RepeatY;
		
		if (Graphic != null)
			loadGraphic(Graphic);
	}
	
	override public function destroy():Void 
	{
		tileGraphic = null;
		rect = FlxDestroyUtil.put(rect);
		uv = FlxDestroyUtil.put(uv);
		
		super.destroy();
	}
	
	override public function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String):FlxSprite 
	{
		tileGraphic = FlxG.bitmap.add(Graphic);
		return this;
	}
	
	public function loadFrame(Frame:FlxFrame):FlxTiledSprite
	{
		tileGraphic = FlxGraphic.fromFrame(Frame);
		return this;
	}
	
	private function set_tileGraphic(Value:FlxGraphic):FlxGraphic 
	{
		var oldGraphic:FlxGraphic = tileGraphic;
		
		if ((tileGraphic != Value) && (Value != null))
		{
			Value.useCount++;
			regen = true;
		}
		
		if ((oldGraphic != null) && (oldGraphic != Value))
		{
			oldGraphic.useCount--;
		}
		
		return tileGraphic = Value;
	}
	
	private function regenGraphic():Void
	{
		if (!regen || tileGraphic == null)
			return;
		
		if (FlxG.renderBlit)
		{
			updateGraphic();
		}
		else
		{
			updateFrameData();
		}
		
		regen = false;
	}
	
	override public function draw():Void 
	{
		if (regen)
		{
			regenGraphic();
			dirty = true;
		}
		
		if (!graphicVisible)
			return;
			
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
				_point.add(rect.x, rect.y);
				_matrix.translate(_point.x, _point.y);
				
				if (isPixelPerfectRender(camera))
				{
					_matrix.tx = Math.floor(_matrix.tx);
					_matrix.ty = Math.floor(_matrix.ty);
				}
				
				camera.drawUVQuad(tileGraphic, rect, uv, _matrix, colorTransform, blend, antialiasing, shader);
				
				#if FLX_DEBUG
				FlxBasic.visibleCount++;
				#end
			}
			
			#if FLX_DEBUG
			if (FlxG.debugger.drawDebug)
				drawDebug();
			#end
		}
	}
	
	private function updateGraphic():Void
	{
		graphicVisible = true;
		
		var rectX:Float = repeatX ? 0 : scrollX;
		var rectWidth:Float = repeatX ? width : tileGraphic.bitmap.width;
		
		if (!repeatX && (rectX > width || rectX + rectWidth < 0))
		{
			graphicVisible = false;
			return;
		}
		
		var rectY:Float = repeatY ? 0 : scrollY;
		var rectHeight:Float = repeatY ? height : tileGraphic.bitmap.height;
		
		if (!repeatY && (rectY > height || rectY + rectHeight < 0))
		{
			graphicVisible = false;
			return;
		}
		
		if (graphic == null || (graphic.width != width || graphic.height != height))
		{
			makeGraphic(Std.int(width), Std.int(height), FlxColor.TRANSPARENT, true);
		}
		else
		{
			_flashRect2.setTo(0, 0, width, height);
			pixels.fillRect(_flashRect2, FlxColor.TRANSPARENT);
		}
		
		FlxSpriteUtil.flashGfx.clear();
		
		if (scrollX != 0 || scrollY != 0)
		{
			_matrix.identity();
			_matrix.tx = Math.round(scrollX);
			_matrix.ty = Math.round(scrollY);
			FlxSpriteUtil.flashGfx.beginBitmapFill(tileGraphic.bitmap, _matrix);
		}
		else
		{
			FlxSpriteUtil.flashGfx.beginBitmapFill(tileGraphic.bitmap);
		}
		
		FlxSpriteUtil.flashGfx.drawRect(rectX, rectY, rectWidth, rectHeight);
		pixels.draw(FlxSpriteUtil.flashGfxSprite, null, colorTransform);
		FlxSpriteUtil.flashGfx.clear();
		dirty = true;
	}
	
	private function updateFrameData():Void
	{
		if (tileGraphic == null)
		{
			graphicVisible = false;
			return;
		}
		
		var frame:FlxFrame = tileGraphic.imageFrame.frame;
		graphicVisible = true;
		
		if (repeatX)
		{
			rect.x = 0.0;
			rect.width = width;
			
			uv.x = -scrollX / frame.sourceSize.x;
			uv.width = uv.x + width / frame.sourceSize.x;
		}
		else
		{
			rect.x = FlxMath.bound(scrollX, 0, width);
			rect.right = FlxMath.bound(scrollX + frame.sourceSize.x, 0, width);
			
			if (rect.width <= 0)
			{
				graphicVisible = false;
				return;
			}
			
			uv.x = (rect.x - scrollX) / frame.sourceSize.x;
			uv.width = uv.x + rect.width / frame.sourceSize.x;
		}
		
		if (repeatY)
		{
			rect.y = 0.0;
			rect.height = height;
			
			uv.y = -scrollY / frame.sourceSize.y;
			uv.height = uv.y + height / frame.sourceSize.y;
		}
		else
		{
			rect.y = FlxMath.bound(scrollY, 0, height);
			rect.bottom = FlxMath.bound(scrollY + frame.sourceSize.y, 0, height);
			
			if (rect.height <= 0)
			{
				graphicVisible = false;
				return;
			}
			
			uv.y = (rect.y - scrollY) / frame.sourceSize.y;
			uv.height = uv.y + rect.height / frame.sourceSize.y;
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
	
	private function set_scrollX(Value:Float):Float
	{
		if (Value != scrollX)
			regen = true;
		
		return scrollX = Value;
	}
	
	private function set_scrollY(Value:Float):Float
	{
		if (Value != scrollY)
			regen = true;
		
		return scrollY = Value;
	}
	
	private function set_repeatX(Value:Bool):Bool
	{
		if (Value != repeatX)
			regen = true;
		
		return repeatX = Value;
	}
	
	private function set_repeatY(Value:Bool):Bool
	{
		if (Value != repeatY)
			regen = true;
		
		return repeatY = Value;
	}
}
#else
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
	private var renderSprite:FlxSprite;
	
	private var regen:Bool = true;
	
	private var graphicVisible:Bool = true;
	
	public function new(?Graphic:FlxGraphicAsset, Width:Float, Height:Float, RepeatX:Bool = true, RepeatY:Bool = true) 
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
		vertices[2] = Width;
		vertices[3] = 0;
		vertices[4] = Width;
		vertices[5] = Height;
		vertices[6] = 0;
		vertices[7] = Height;
		
		width = Width;
		height = Height;
		
		repeatX = RepeatX;
		repeatY = RepeatY;
		
		if (Graphic != null)
			loadGraphic(Graphic);
	}
	
	override public function destroy():Void 
	{
		renderSprite = FlxDestroyUtil.destroy(renderSprite);
		super.destroy();
	}
	
	override public function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String):FlxSprite 
	{
		graphic = FlxG.bitmap.add(Graphic);
		return this;
	}
	
	public function loadFrame(Frame:FlxFrame):FlxTiledSprite
	{
		graphic = FlxGraphic.fromFrame(Frame);
		return this;
	}
	
	override function set_graphic(Value:FlxGraphic):FlxGraphic 
	{
		if (graphic != Value)
			regen = true;
		
		return super.set_graphic(Value);
	}
	
	private function regenGraphic():Void
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
	
	override public function draw():Void 
	{
		if (regen)
		{
			regenGraphic();
			dirty = true;
		}
		
		if (!graphicVisible)
			return;
			
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
			super.draw();
		}
	}
	
	private function updateRenderSprite():Void
	{
		graphicVisible = true;
			
		if (renderSprite == null)
			renderSprite = new FlxSprite();
		
		var rectX:Float = repeatX ? 0 : scrollX;
		var rectWidth:Float = repeatX ? width : graphic.bitmap.width;
		
		if (!repeatX && (rectX > width || rectX + rectWidth < 0))
		{
			graphicVisible = false;
			return;
		}
		
		var rectY:Float = repeatY ? 0 : scrollY;
		var rectHeight:Float = repeatY ? height : graphic.bitmap.height;
		
		if (!repeatY && (rectY > height || rectY + rectHeight < 0))
		{
			graphicVisible = false;
			return;
		}
		
		if (renderSprite.width != width || renderSprite.height != height)
		{
			renderSprite.makeGraphic(Std.int(width), Std.int(height), FlxColor.TRANSPARENT, true);
		}
		else
		{
			_flashRect2.setTo(0, 0, width, height);
			renderSprite.pixels.fillRect(_flashRect2, FlxColor.TRANSPARENT);
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
		
		FlxSpriteUtil.flashGfx.drawRect(rectX, rectY, rectWidth, rectHeight);
		renderSprite.pixels.draw(FlxSpriteUtil.flashGfxSprite, null, colorTransform);
		FlxSpriteUtil.flashGfx.clear();
		renderSprite.dirty = true;
	}
	
	private function updateVerticesData():Void
	{
		if (graphic == null)
			return;
		
		var frame:FlxFrame = graphic.imageFrame.frame;
		graphicVisible = true;
		
		if (repeatX)
		{
			vertices[0] = vertices[6] = 0.0;
			vertices[2] = vertices[4] = width;
			
			uvtData[0] = uvtData[6] = -scrollX / frame.sourceSize.x;
			uvtData[2] = uvtData[4] = uvtData[0] + width / frame.sourceSize.x;
		}
		else
		{
			vertices[0] = vertices[6] = FlxMath.bound(scrollX, 0, width);
			vertices[2] = vertices[4] = FlxMath.bound(scrollX + frame.sourceSize.x, 0, width);
			
			if (vertices[2] - vertices[0] <= 0)
			{
				graphicVisible = false;
				return;
			}
			
			uvtData[0] = uvtData[6] = (vertices[0] - scrollX) / frame.sourceSize.x;
			uvtData[2] = uvtData[4] = uvtData[0] + (vertices[2] - vertices[0]) / frame.sourceSize.x;
		}
		
		if (repeatY)
		{
			vertices[1] = vertices[3] = 0.0;
			vertices[5] = vertices[7] = height;
			
			uvtData[1] = uvtData[3] = -scrollY / frame.sourceSize.y;
			uvtData[5] = uvtData[7] = uvtData[1] + height / frame.sourceSize.y;
		}
		else
		{
			vertices[1] = vertices[3] = FlxMath.bound(scrollY, 0, height);
			vertices[5] = vertices[7] = FlxMath.bound(scrollY + frame.sourceSize.y, 0, height);
			
			if (vertices[5] - vertices[1] <= 0)
			{
				graphicVisible = false;
				return;
			}
			
			uvtData[1] = uvtData[3] = (vertices[1] - scrollY) / frame.sourceSize.y;
			uvtData[5] = uvtData[7] = uvtData[1] + (vertices[5] - vertices[1]) / frame.sourceSize.y;
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
	
	private function set_scrollX(Value:Float):Float
	{
		if (Value != scrollX)
			regen = true;
		
		return scrollX = Value;
	}
	
	private function set_scrollY(Value:Float):Float
	{
		if (Value != scrollY)
			regen = true;
		
		return scrollY = Value;
	}
	
	private function set_repeatX(Value:Bool):Bool
	{
		if (Value != repeatX)
			regen = true;
		
		return repeatX = Value;
	}
	
	private function set_repeatY(Value:Bool):Bool
	{
		if (Value != repeatY)
			regen = true;
		
		return repeatY = Value;
	}
}
#end