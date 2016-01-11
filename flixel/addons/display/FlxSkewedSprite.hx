package flixel.addons.display;

import flash.geom.Matrix;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxFrame.FlxFrameType;
import flixel.graphics.tile.FlxDrawTilesItem;
import flixel.system.FlxAssets;
import flixel.math.FlxAngle;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;

/**
 * ...
 * @author Zaphod
 */
class FlxSkewedSprite extends FlxSprite
{
	public var skew(default, null):FlxPoint;
	
	/**
	 * Tranformation matrix for this sprite.
	 * Used only when matrixExposed is set to true
	 */
	public var transformMatrix(default, null):Matrix;
	
	/**
	 * Bool flag showing whether transformMatrix is used for rendering or not.
	 * False by default, which means that transformMatrix isn't used for rendering
	 */
	public var matrixExposed:Bool = false;
	
	/**
	 * Internal helper matrix object. Used for rendering calculations when matrixExposed is set to false
	 */
	private var _skewMatrix:Matrix;
	
	public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
	{
		super(X, Y, SimpleGraphic);
		
		skew = FlxPoint.get();
		_skewMatrix = new Matrix();
		transformMatrix = new Matrix();
	}
	
	/**
	 * WARNING: This will remove this sprite entirely. Use kill() if you 
	 * want to disable it temporarily only and reset() it later to revive it.
	 * Used to clean up memory.
	 */
	override public function destroy():Void 
	{
		skew = FlxDestroyUtil.put(skew);
		_skewMatrix = null;
		transformMatrix = null;
		
		super.destroy();
	}
	
	override public function draw():Void 
	{
		if (alpha == 0 || frame.type == FlxFrameType.EMPTY)
		{
			return;
		}
		
		if (dirty)	//rarely 
		{
			calcFrame();
		}
		
		for (camera in cameras)
		{
			if (!isOnScreen(camera) || !camera.visible || !camera.exists)
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
			}
			
			_matrix.identity();
			_matrix.translate( -origin.x, -origin.y);
			
			if (matrixExposed)
			{
				_matrix.concat(transformMatrix);
			}
			else
			{
				_matrix.scale(scale.x, scale.y);
				if (bakedRotationAngle <= 0)
				{
					updateTrig();
					
					if (angle != 0)
					{
						_matrix.rotateWithTrig(_cosAngle, _sinAngle);
					}
				}
				
				updateSkewMatrix();
				_matrix.concat(_skewMatrix);
			}
			
			_point.add(origin.x, origin.y);
			if (isPixelPerfectRender(camera))
			{
				_point.floor();
			}
			
			_matrix.translate(_point.x, _point.y);
			camera.drawPixels(_frame, framePixels, _matrix, cr, cg, cb, alpha, blend, antialiasing);
			
			#if !FLX_NO_DEBUG
			FlxBasic.activeCount++;
			#end
		}
	}
	
	private function updateSkewMatrix():Void
	{
		_skewMatrix.identity();
		
		if ((skew.x != 0) || (skew.y != 0))
		{
			_skewMatrix.b = Math.tan(skew.y * FlxAngle.TO_RAD);
			_skewMatrix.c = Math.tan(skew.x * FlxAngle.TO_RAD);
		}
	}
	
	override public function isSimpleRender(?camera:FlxCamera):Bool
	{
		if (FlxG.renderBlit)
		{
			return super.isSimpleRender(camera) && (skew.x == 0) && (skew.y == 0) && (!matrixExposed);
		}
		else
		{
			return false;
		}
	}
}