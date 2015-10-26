package flixel.addons.effects;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.geom.Point;

class FlxEffectSprite extends FlxSprite
{
	/**
	 * Effects applied to frames
	 */
	public var effects(default, null):Array<IFlxEffect>;
	
	/**
	 * Use to offset the drawing position of the mesh.
	 */
	private var _drawOffset:Point;
	/**
	 * The actual Flash BitmapData object representing the current display state of the modified framePixels.
	 */
	private var _effectPixels:BitmapData;
	
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
		
		_drawOffset = new Point();
		this.effects = [];
	}
	
	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen
	 */
	override public function draw():Void 
	{
		if (_frame == null || _effectPixels == null)
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
				
				_flashPoint = new Point(_point.x + _drawOffset.x, _point.y + _drawOffset.y);
				camera.copyPixels(_frame, _effectPixels, _effectPixels.rect, _flashPoint, cr, cg, cb, alpha, blend, antialiasing);
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
				var frameEffect:FlxFrame = new FlxFrame(FlxGraphic.fromBitmapData(_effectPixels, true, null, false));
				frameEffect.frame = new FlxRect(0, 0, _effectPixels.width, _effectPixels.height);
				
				_matrix.translate(_point.x + _drawOffset.x, _point.y + _drawOffset.y);
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
		effects = null;
		_drawOffset = null;
		_effectPixels = FlxDestroyUtil.dispose(_effectPixels);
		
		for (effect in effects) 
		{
			effect.destroy();
		}
		
		super.destroy();
	}
	
	/**
	 * Core update loop
	 */
	override public function update(elapsed:Float):Void
	{
		#if !FLX_RENDER_BLIT
		getFlxFrameBitmapData();
		#end
		_effectPixels = framePixels.clone();
		_drawOffset.setTo(0, 0);
		
		for (effect in effects) 
		{
			if (effect.active)
			{
				effect.update(elapsed);
				_effectPixels = effect.apply(_effectPixels);
				_drawOffset.setTo(_drawOffset.x + effect.offsetDraw.x, _drawOffset.y + effect.offsetDraw.y);
			}
		}
		
		super.update(elapsed);
	}
}