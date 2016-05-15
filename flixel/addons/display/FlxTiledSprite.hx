package flixel.addons.display;

import flixel.FlxStrip;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;

/**
 * Tiled sprite which displays repeated and clipped graphic.
 * @author Zaphod
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
	 * Helper sprite, which does actual rendering in blit render mode.
	 */
	private var renderSprite:FlxSprite;
	
	private var regen:Bool = true;
	
	public function new(?Graphic:FlxGraphicAsset, Width:Float, Height:Float) 
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
		
		if (FlxG.renderBlit)
		{
			renderSprite = new FlxSprite();
		}
		
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
		if (renderSprite != null)
		{
			renderSprite.graphic = Value;
		}
		
		regen = true;
		return super.set_graphic(Value);
	}
	
	private function regenGraphic():Void
	{
		if (!regen || graphic == null)
			return;
		
		if (FlxG.renderBlit)
		{
			if (renderSprite == null)
			{
				renderSprite = new FlxSprite();
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
			
			FlxSpriteUtil.flashGfx.drawRect(0, 0, width, height);
			renderSprite.pixels.draw(FlxSpriteUtil.flashGfxSprite, null, colorTransform);
			renderSprite.dirty = true;
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
			regenGraphic();
		
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
	
	private function updateVerticesData():Void
	{
		if (graphic == null)
			return;
		
		var frame:FlxFrame = graphic.imageFrame.frame;
		
		uvtData[0] = uvtData[6] = -scrollX / frame.sourceSize.x;
		uvtData[2] = uvtData[4] = uvtData[0] + width / frame.sourceSize.x;
		
		uvtData[1] = uvtData[3] = -scrollY / frame.sourceSize.y;
		uvtData[5] = uvtData[7] = uvtData[0] + height / frame.sourceSize.y;
		
		vertices[2] = vertices[4] = width;
		uvtData[2] = uvtData[4] = uvtData[0] + width / frame.sourceSize.x;
		
		vertices[5] = vertices[7] = height;
		uvtData[5] = uvtData[5] = uvtData[0] + height / frame.sourceSize.y;
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
}