package flixel.addons.display;

import flash.geom.Matrix;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.system.layer.DrawStackItem;
import flixel.util.FlxAngle;
import flixel.util.FlxPoint;

/**
 * ...
 * @author Zaphod
 */
class FlxSkewedSprite extends FlxSprite
{
	public var skew(default, null):FlxPoint;
	
	private var _skewMatrix:Matrix;
	
	public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:Dynamic)
	{
		super(X, Y, SimpleGraphic);
		
		skew = new FlxPoint();
		_skewMatrix = new Matrix();
	}
	
	/**
	 * WARNING: This will remove this sprite entirely. Use kill() if you 
	 * want to disable it temporarily only and reset() it later to revive it.
	 * Used to clean up memory.
	 */
	override public function destroy():Void 
	{
		skew = null;
		_skewMatrix = null;
		
		super.destroy();
	}
	
	override public function draw():Void 
	{
		if (dirty)	//rarely 
		{
			calcFrame();
		}
		
		if (cameras == null)
		{
			cameras = FlxG.cameras.list;
		}
		
		#if !flash
		var drawItem:DrawStackItem;
		var currDrawData:Array<Float>;
		var currIndex:Int;
		#end
		
		var radians:Float;
		var cos:Float;
		var sin:Float;
		
		for (camera in cameras)
		{
			if (!isOnScreen(camera) || !camera.visible || !camera.exists)
			{
				continue;
			}
			
		#if !flash
			#if !js
			drawItem = camera.getDrawStackItem(cachedGraphics, isColored, _blendInt, antialiasing);
			#else
			var useAlpha:Bool = (alpha < 1);
			drawItem = camera.getDrawStackItem(cachedGraphics, useAlpha);
			#end
			currDrawData = drawItem.drawData;
			currIndex = drawItem.position;
			
			_point.x = x - (camera.scroll.x * scrollFactor.x) - (offset.x);
			_point.y = y - (camera.scroll.y * scrollFactor.y) - (offset.y);
			
			_point.x = (_point.x) + origin.x;
			_point.y = (_point.y) + origin.y;
			
			#if js
			_point.x = Math.floor(_point.x);
			_point.y = Math.floor(_point.y);
			#end
		#else
			_point.x = x - (camera.scroll.x * scrollFactor.x) - (offset.x);
			_point.y = y - (camera.scroll.y * scrollFactor.y) - (offset.y);
		#end
		
#if flash
			if (isSimpleRender())
			{
				_point.copyToFlash(_flashPoint);
				camera.buffer.copyPixels(framePixels, _flashRect, _flashPoint, null, null, true);
			}
			else
			{
				_matrix.identity();
				_matrix.translate( -origin.x, -origin.y);
				if ((angle != 0) && (bakedRotationAngle <= 0))
				{
					_matrix.rotate(angle * FlxAngle.TO_RAD);
				}
				_matrix.scale(scale.x, scale.y);
				
				updateSkewMatrix();
				
				_matrix.translate(_point.x + origin.x, _point.y + origin.y);
				camera.buffer.draw(framePixels, _matrix, null, blend, null, antialiasing);
			}
#else
			var csx:Float = 1;
			var ssy:Float = 0;
			var ssx:Float = 0;
			var csy:Float = 1;
			
			var x1:Float = (origin.x - frame.center.x);
			var y1:Float = (origin.y - frame.center.y);
			
			var x2:Float = x1;
			var y2:Float = y1;
			
			var isFlipped:Bool = (flipped != 0) && (facing == FlxObject.LEFT);
			
			if (isSimpleRender())
			{
				if (isFlipped)
				{
					csx = -csx;
				}
			}
			else
			{
				radians = -angle * FlxAngle.TO_RAD;
				
				_matrix.identity();
				_matrix.rotate( -radians);
				
				if (isFlipped)
				{
					_matrix.scale( -scale.x, scale.y);
				}
				else
				{
					_matrix.scale(scale.x, scale.y);
				}
				
				updateSkewMatrix();
				
				x2 = x1 * _matrix.a + y1 * _matrix.c + _matrix.tx;
				y2 = x1 * _matrix.b + y1 * _matrix.d + _matrix.ty;
				
				csx = _matrix.a;
				ssy = _matrix.b;
				ssx = _matrix.c;
				csy = _matrix.d;
			}
			
			currDrawData[currIndex++] = _point.x - x2;
			currDrawData[currIndex++] = _point.y - y2;
			
			currDrawData[currIndex++] = frame.tileID;
			
			currDrawData[currIndex++] = csx;
			currDrawData[currIndex++] = ssy;
			currDrawData[currIndex++] = ssx;
			currDrawData[currIndex++] = csy;
			
			#if !js
			if (isColored)
			{
				currDrawData[currIndex++] = _red;
				currDrawData[currIndex++] = _green;
				currDrawData[currIndex++] = _blue;
			}
			currDrawData[currIndex++] = alpha;
			#else 
			if (useAlpha)
			{
				currDrawData[currIndex++] = alpha;
			}
			#end
			
			drawItem.position = currIndex;
#end
			#if !FLX_NO_DEBUG
			FlxBasic._VISIBLECOUNT++;
			#end
		}
	}
	
	private function updateSkewMatrix():Void
	{
		if ((skew.x != 0) || (skew.y != 0))
		{
			_skewMatrix.identity();
			
			_skewMatrix.b = Math.tan(skew.y * FlxAngle.TO_RAD);
			_skewMatrix.c = Math.tan(skew.x * FlxAngle.TO_RAD);
			
			_matrix.concat(_skewMatrix);
		}
	}
	
	public override function isSimpleRender():Bool
	{
		#if !flash
		return (((angle == 0) || (bakedRotationAngle > 0)) && (scale.x == 1) && (scale.y == 1) && (skew.x == 0) && (skew.y == 0));
		#else
		return (((angle == 0) || (bakedRotationAngle > 0)) && (scale.x == 1) && (scale.y == 1) && (blend == null) && (skew.x == 0) && (skew.y == 0) && (forceComplexRender == false));
		#end
	}
}