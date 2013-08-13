package flixel.addons.tile;

import flash.geom.Matrix;
import flixel.FlxSprite;
import flixel.util.FlxAngle;

class FlxTileSpecial
{
	public static var ROTATE_0 = 0;
	public static var ROTATE_90 = 1;
	public static var ROTATE_270 = 2;
	
	public var flipHorizontally:Bool = false;
	public var flipVertically:Bool = false;
	
	public var rotate:Int;
	
	private var MATRIX:Matrix;
	
	public function new(FlipHorizontal:Bool, FlipVertical:Bool, Rotate:Int) 
	{
		this.flipHorizontally = FlipHorizontal;
		this.flipVertically = FlipVertical;
		this.rotate = Rotate;
		
		this.MATRIX = new Matrix();
	}
	
	public function isSpecial():Bool {
		return ((flipHorizontally || flipVertically) || rotate != ROTATE_0);
	}
	
	public function getMatrix(width:Float, height:Float):Matrix {
		MATRIX.identity();
		if(flipHorizontally) {
			MATRIX.scale( -1, 1);
			MATRIX.translate(width, 0);
		}
		if (flipVertically) {
			MATRIX.scale(1, -1);
			MATRIX.translate(0, height);
		}
		
		if (rotate != FlxTileSpecial.ROTATE_0) {
			switch(rotate) {
				case FlxTileSpecial.ROTATE_90:
					MATRIX.rotate(90 * FlxAngle.TO_RAD);
					MATRIX.translate(width, 0);

				case FlxTileSpecial.ROTATE_270:
					MATRIX.rotate(270 * FlxAngle.TO_RAD);
					MATRIX.translate(0, height);
			}
		}
		
		return MATRIX;
	}
}