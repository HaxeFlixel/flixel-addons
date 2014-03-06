package flixel.addons.display.shapes;

import flash.geom.Matrix;
import flixel.util.FlxSpriteUtil;

class FlxShapeDoubleCircle extends FlxShapeDonut
{
	/**
	 * Creates a FlxSprite with a double-circle drawn on top of it. 
	 * X/Y is where the SPRITE is, the double-circle's upper-left
	 */
	public function new(X:Float, Y:Float, RadiusOut:Float, RadiusIn:Float, LineStyle_:LineStyle, FillStyle_:FillStyle) 
	{
		super(X, Y, RadiusOut, RadiusIn, LineStyle_, FillStyle_);
	}
	
	override public function drawSpecificShape(?matrix:Matrix):Void 
	{
		var cx:Float = Math.ceil(width / 2);
		var cy:Float = Math.ceil(height / 2);
		FlxSpriteUtil.drawCircle(this, cx, cy, radius_out, fillStyle.color, lineStyle,  { matrix: matrix });
		FlxSpriteUtil.drawCircle(this, cx, cy, radius_in, 0x00000000, lineStyle,  { matrix: matrix });
	}
}