package flixel.addons.tile;

import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.system.FlxAnim;
import flixel.util.FlxAngle;
import flixel.util.FlxColor;

class FlxTileSpecial extends FlxBasic
{
	public static var ROTATE_0 = 0;
	public static var ROTATE_90 = 1;
	public static var ROTATE_270 = 2;
	
	public var flipHorizontally:Bool = false;
	public var flipVertically:Bool = false;
	
	public var rotate:Int;
	
	#if flash
	private var _normalFrame:BitmapData;
	private var _flippedFrame:BitmapData;
	private var _point:Point;
	#end
	
	private var _matrix:Matrix;
	private var _animations:Map<String, FlxAnim>;
	
	public function new(FlipHorizontal:Bool, FlipVertical:Bool, Rotate:Int) 
	{
		super();
		this.flipHorizontally = FlipHorizontal;
		this.flipVertically = FlipVertical;
		this.rotate = Rotate;
		
		#if flash
		this._normalFrame = null;
		this._flippedFrame = null;
		this._point = new Point(0, 0);
		#end
		
		this._matrix = new Matrix();
		this._animations = new Map<String, FlxAnim>();
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		
		#if flash
		_normalFrame.dispose();
		_flippedFrame.dispose();
		_normalFrame = null;
		_flippedFrame = null;
		_point = null;
		#end
		
		
		if (_animations != null)
		{
			for (anim in _animations)
			{
				if (anim != null)
				{
					anim.destroy();
				}
			}
			_animations = null;
		}
		_matrix = null;
	}
	
	public function isSpecial():Bool {
		return ((flipHorizontally || flipVertically) || rotate != ROTATE_0);
	}
	
	#if flash
	public function getBitmapData(width:Int, height:Int, rect:Rectangle, bitmap:BitmapData):BitmapData {
		if (_flippedFrame == null) {
			_normalFrame = new BitmapData(width, height, true, FlxColor.TRANSPARENT);
			_flippedFrame = new BitmapData(width, height, true, FlxColor.TRANSPARENT);
			
			_normalFrame.copyPixels(bitmap, rect, _point, null, null, true);
			
			
			_flippedFrame.draw(_normalFrame, getMatrix(width, height));			
		}
	
		return _flippedFrame;
	}
	
	public function getBitmapDataRect():Rectangle {
		if (_flippedFrame == null) {
			throw "The is no flipped frame D: D: D:!!!";
		} else {
			return _flippedFrame.rect;
		}
	}
	#end
	
	public function getMatrix(width:Int, height:Int):Matrix {
		_matrix.identity();
		if(flipHorizontally) {
			_matrix.scale( -1, 1);
			_matrix.translate(width, 0);
		}
		if (flipVertically) {
			_matrix.scale(1, -1);
			_matrix.translate(0, height);
		}
		
		if (rotate != FlxTileSpecial.ROTATE_0) {
			switch(rotate) {
				case FlxTileSpecial.ROTATE_90:
					_matrix.rotate(90 * FlxAngle.TO_RAD);
					_matrix.translate(width, 0);

				case FlxTileSpecial.ROTATE_270:
					_matrix.rotate(270 * FlxAngle.TO_RAD);
					_matrix.translate(0, height);
			}
		}
		
		return _matrix;
	}
}