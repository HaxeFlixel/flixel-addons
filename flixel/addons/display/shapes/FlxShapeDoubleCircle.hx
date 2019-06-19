package flixel.addons.display.shapes;

import flash.geom.Matrix;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class FlxShapeDoubleCircle extends FlxShapeDonut
{
	/**
	 * Creates a FlxSprite with a double-circle drawn on top of it.
	 * X/Y is where the SPRITE is, the double-circle's upper-left
	 */
	public function new(X:Float, Y:Float, RadiusOut:Float, RadiusIn:Float, LineStyle_:LineStyle, FillColor:FlxColor)
	{
		super(X, Y, RadiusOut, RadiusIn, LineStyle_, FillColor);
		shape_id = FlxShapeType.DOUBLE_CIRCLE;
	}

	override public function drawSpecificShape(?matrix:Matrix):Void
	{
		var cx:Float = Math.ceil(width / 2);
		var cy:Float = Math.ceil(height / 2);
		FlxSpriteUtil.drawCircle(this, cx, cy, radius_out, fillColor, lineStyle, {matrix: matrix});
		FlxSpriteUtil.drawCircle(this, cx, cy, radius_in, 0x00000000, lineStyle, {matrix: matrix});
	}
}
