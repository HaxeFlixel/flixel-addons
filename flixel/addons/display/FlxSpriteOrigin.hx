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

@:bitmap("assets/images/logo/default.png")
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
		if (frame == null)
		{
			loadGraphic(FlxGraphic.fromClass(GraphicDefault));
		}
		
		if (alpha == 0 || frame.type == FlxFrameType.EMPTY)
		{
			return;
		}
		
		if (dirty)	//rarely 
		{
			calcFrame();
		}
		
	#if FLX_RENDER_TILE
		var drawItem:FlxDrawTilesItem;
		
		var ox:Float = origin.x;
		if (_facingHorizontalMult != 1)
		{
			ox = frameWidth - ox;
		}
		var oy:Float = origin.y;
		if (_facingVerticalMult != 1)
		{
			oy = frameHeight - oy;
		}
	#end
		
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
			{
				continue;
			}
			
			getScreenPosition(_point, camera).subtractPoint(offset);
			
#if FLX_RENDER_BLIT
			if (isSimpleRender(camera))
			{
				_point.subtractPoint(origin).floor().copyToFlash(_flashPoint);
				camera.buffer.copyPixels(framePixels, _flashRect, _flashPoint, null, null, true);
			}
			else
			{
				_matrix.identity();
				_matrix.translate(-origin.x, -origin.y);
				_matrix.scale(scale.x, scale.y);
				
				if ((angle != 0) && (bakedRotationAngle <= 0))
				{
					_matrix.rotate(angle * FlxAngle.TO_RAD);
				}
				
				_point.floor();
				
				_matrix.translate(_point.x, _point.y);
				camera.buffer.draw(framePixels, _matrix, null, blend, null, (antialiasing || camera.antialiasing));
			}
#else
			drawItem = camera.getDrawStackItem(frame.parent, isColored, _blendInt, antialiasing);
			
			_matrix.identity();
			
			if (frame.angle != FlxFrameAngle.ANGLE_0)
			{
				// handle rotated frames
				frame.prepareFrameMatrix(_matrix);
			}
			
			var x1:Float = (ox - frame.center.x);
			var y1:Float = (oy - frame.center.y);
			_matrix.translate(x1, y1);
			
			var sx:Float = scale.x * _facingHorizontalMult;
			var sy:Float = scale.y * _facingVerticalMult;
			_matrix.scale(sx * camera.totalScaleX, sy * camera.totalScaleY);
			
			// rotate matrix if sprite's graphic isn't prerotated
			if (!isSimpleRender(camera))
			{
				if (_angleChanged && (bakedRotationAngle <= 0))
				{
					var radians:Float = angle * FlxAngle.TO_RAD;
					_sinAngle = Math.sin(radians);
					_cosAngle = Math.cos(radians);
					_angleChanged = false;
				}
				
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
			}
			
			_point.x *= camera.totalScaleX;
			_point.y *= camera.totalScaleY;
			
			if (isPixelPerfectRender(camera))
			{
				_point.floor();
			}
			
			_point.subtract(_matrix.tx, _matrix.ty);
			
			setDrawData(drawItem, camera, _matrix);
#end
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