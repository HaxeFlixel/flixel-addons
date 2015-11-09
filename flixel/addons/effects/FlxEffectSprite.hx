package flixel.addons.effects;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.geom.Point;

class FlxEffectSprite extends FlxSprite
{
	public var updateEffects:Bool = true;
	
	/**
	 * Effects applied to frames
	 */
	public var effects:Array<IFlxEffect>;
	/**
	 * The actual Flash BitmapData object representing the current display state of the modified framePixels.
	 */
	public var effectPixels(default, null):BitmapData;
	
	/**
	 * Use to offset the drawing position of the bitmap.
	 */
	private var _effectOffset:Point;
	
	/**
	 * Creates a FlxEffectSprite at a specified position with a specified one-frame graphic. 
	 * If none is provided, a 16x16 image of the HaxeFlixel logo is used.
	 * 
	 * @param	X				The initial X position of the sprite.
	 * @param	Y				The initial Y position of the sprite.
	 * @param	SimpleGraphic	The graphic you want to display (OPTIONAL - for simple stuff only, do NOT use for animated images!).
	 */
	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
	{
		super(X, Y, SimpleGraphic);
		
		_effectOffset = new Point();
		this.effects = [];
	}
	
	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen
	 */
	override public function draw():Void 
	{
		if (_frame == null || effectPixels == null)
		{
			super.draw();
			return;
		}
		
		if (alpha == 0 || _frame.type == FlxFrameType.EMPTY)
		{
			return;
		}
		
		if (dirty)	//rarely 
		{
			calcFrame();
		}
		
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
			{
				continue;
			}
			
			getScreenPosition(_point, camera).subtractPoint(offset);
			
			var cr:Float = colorTransform.redMultiplier;
			var cg:Float = colorTransform.greenMultiplier;
			var cb:Float = colorTransform.blueMultiplier;
			
			var simple:Bool = isSimpleRender(camera);
			if (simple)
			{
				if (isPixelPerfectRender(camera))
				{
					_point.floor();
				}
				
				_flashPoint = new Point(_point.x + _effectOffset.x, _point.y + _effectOffset.y);
				camera.copyPixels(_frame, effectPixels, effectPixels.rect, _flashPoint, cr, cg, cb, alpha, blend, antialiasing);
			}
			else
			{
				_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, flipX, flipY);
				_matrix.translate( -origin.x, -origin.y);
				_matrix.scale(scale.x, scale.y);
				
				if (bakedRotationAngle <= 0)
				{
					updateTrig();
					
					if (angle != 0)
					{
						_matrix.rotateWithTrig(_cosAngle, _sinAngle);
					}
				}
				
				_point.add(origin.x, origin.y);
				if (isPixelPerfectRender(camera))
				{
					_point.floor();
				}
				
				// Create a temporary frame and draw effect's bitmapData
				var frameEffect:FlxFrame = new FlxFrame(FlxGraphic.fromBitmapData(effectPixels, true, null, false));
				frameEffect.frame = new FlxRect(0, 0, effectPixels.width, effectPixels.height);
				
				_matrix.translate(_point.x + _effectOffset.x, _point.y + _effectOffset.y);
				camera.drawPixels(frameEffect, framePixels, _matrix, cr, cg, cb, alpha, blend, antialiasing);
			}
			
			#if !FLX_NO_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
		
		#if !FLX_NO_DEBUG
		if (FlxG.debugger.drawDebug)
		{
			drawDebug();
		}
		#end
	}
	
	/**
	 * WARNING: This will remove this sprite entirely. Use kill() if you want to disable it temporarily only and reset() it later to revive it.
	 * Used to clean up memory.
	 */
	override public function destroy():Void
	{
		for (effect in effects) 
		{
			effect.destroy();
		}
		
		effects = null;
		_effectOffset = null;
		effectPixels = FlxDestroyUtil.dispose(effectPixels);
		
		super.destroy();
	}
	
	/**
	 * Core update loop
	 */
	override public function update(elapsed:Float):Void
	{
		if (updateEffects)
		{
			#if !FLX_RENDER_BLIT
			getFlxFrameBitmapData();
			#end
			
			effectPixels = FlxDestroyUtil.dispose(effectPixels);
			effectPixels = framePixels.clone();
			_effectOffset.setTo(0, 0);
			
			effectPixels.lock();
			for (effect in effects) 
			{
				if (effect.active)
				{
					effect.update(elapsed);
					effectPixels = effect.apply(effectPixels);
					if (effect.offset != null)
					{
						_effectOffset.setTo(_effectOffset.x + effect.offset.x, _effectOffset.y + effect.offset.y);
					}
				}
			}
			effectPixels.unlock();
		}
		
		super.update(elapsed);
	}
	
	#if !FLX_NO_DEBUG
	override public function drawDebugOnCamera(camera:FlxCamera):Void
	{
		if (!camera.visible || !camera.exists || !isOnScreen(camera))
		{
			return;
		}
		
		var rect = getBoundingBox(camera);
		
		// Find the color to use
		var color:Null<Int> = debugBoundingBoxColor;
		if (color == null)
		{
			if (allowCollisions != FlxObject.NONE)
			{
				color = immovable ? FlxColor.GREEN : FlxColor.RED;
			}
			else
			{
				color = FlxColor.BLUE;
			}
		}
		
		//fill static graphics object with square shape
		var gfx:Graphics = beginDrawDebug(camera);
		gfx.lineStyle(1, color, 0.5);
		gfx.drawRect(rect.x, rect.y, rect.width, rect.height);
		
		//draw rect of effectPixels
		gfx.lineStyle(1, FlxColor.CYAN, 0.5);
		gfx.drawRect(rect.x + _effectOffset.x, rect.y + _effectOffset.y, effectPixels.rect.width, effectPixels.rect.height);
		endDrawDebug(camera);
	}
	#end
}