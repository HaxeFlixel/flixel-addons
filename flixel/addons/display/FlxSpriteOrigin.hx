package flixel.addons.display;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxFrame.FlxFrameType;
import flixel.graphics.tile.FlxDrawTilesItem;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;

@:keep @:bitmap("assets/images/logo/default.png")
private class GraphicDefault extends BitmapData {}

/**
 * FlxSprite with "centered" origin, so collisions are broken for this type of objects.
 */
class FlxSpriteOrigin extends FlxSprite
{
	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen
	 */
	override public function draw():Void
	{
		if (_frame == null)
		{
			#if !FLX_NO_DEBUG
			loadGraphic(FlxGraphic.fromClass(GraphicDefault));
			#else
			return;
			#end
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
			var croff:Float = colorTransform.redOffset;
			var cgoff:Float = colorTransform.greenOffset;
			var cboff:Float = colorTransform.blueOffset;
			var caoff:Float = colorTransform.alphaOffset;
			
			var simple:Bool = isSimpleRender(camera);
			if (simple)
			{
				if (isPixelPerfectRender(camera))
				{
					_point.floor();
				}
				
				_point.copyToFlash(_flashPoint);
				camera.copyPixels(_frame, framePixels, _flashRect, _flashPoint, cr, cg, cb, alpha, croff, cgoff, cboff, caoff, blend, antialiasing);
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
				
				if (isPixelPerfectRender(camera))
				{
					_point.floor();
				}
				
				_matrix.translate(_point.x, _point.y);
				camera.drawPixels(_frame, framePixels, _matrix, cr, cg, cb, alpha, blend, antialiasing);
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
	 * Check and see if this object is currently on screen. Differs from FlxObject's implementation
	 * in that it takes the actual graphic into account, not just the hitbox or bounding box or whatever.
	 * 
	 * @param	Camera		Specify which game camera you want.  If null getScreenXY() will just grab the first global camera.
	 * @return	Whether the object is on screen or not.
	 */
	override public function isOnScreen(?Camera:FlxCamera):Bool
	{
		if (Camera == null)
		{
			Camera = FlxG.camera;
		}
		
		var centerX:Float = x - offset.x - Camera.scroll.x * scrollFactor.x;
		var centerY:Float = y - offset.y - Camera.scroll.y * scrollFactor.y;
		
		var minX:Float = 0;
		var minY:Float = 0;
		var maxX:Float = 0;
		var maxY:Float = 0;
		
		var radiusX:Float = _halfSize.x;
		var radiusY:Float = _halfSize.y;
		
		if (origin.x == radiusX)
		{
			radiusX = Math.abs(radiusX * scale.x);
		}
		else
		{
			var sox:Float = scale.x * origin.x;
			var sfw:Float = scale.x * frameWidth;
			var x1:Float = Math.abs(sox);
			var x2:Float = Math.abs(sfw - sox);
			radiusX = Math.max(x2, x1);
		}
		
		if (origin.y == radiusY)
		{
			radiusY = Math.abs(radiusY * scale.y);
		}
		else
		{
			var soy:Float = scale.y * origin.y;
			var sfh:Float = scale.y * frameHeight;
			var y1:Float = Math.abs(soy);
			var y2:Float = Math.abs(sfh - soy);
			radiusY = Math.max(y2, y1);
		}
		
		var radius:Float = Math.max(radiusX, radiusY);
		radius *= FlxMath.SQUARE_ROOT_OF_TWO;
		
		minX = centerX - radius;
		maxX = centerX + radius;
		
		minY = centerY - radius;
		maxY = centerY + radius;
		
		if (maxX < 0 || minX > Camera.width)
			return false;
		
		if (maxY < 0 || minY > Camera.height)
			return false;
		
		return true;
	}	
}