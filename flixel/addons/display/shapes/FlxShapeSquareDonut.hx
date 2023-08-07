package flixel.addons.display.shapes;

import openfl.display.BlendMode;
import openfl.geom.Matrix;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class FlxShapeSquareDonut extends FlxShape
{
	public var radius_out(default, set):Float;
	public var radius_in(default, set):Float;

	/**
	 * Creates a FlxSprite with a square donut drawn on top of it.
	 * X/Y is where the SPRITE is, the square's upper-left
	 */
	public function new(X:Float, Y:Float, RadiusOut:Float, RadiusIn:Float, LineStyle_:LineStyle, FillColor:FlxColor)
	{
		super(X, Y, 0, 0, LineStyle_, FillColor, RadiusOut * 2, RadiusOut * 2);

		radius_out = RadiusOut;
		radius_in = RadiusIn;

		shape_id = FlxShapeType.SQUARE_DONUT;
	}

	override public function drawSpecificShape(?matrix:Matrix):Void
	{
		FlxSpriteUtil.drawRect(this, 0, 0, radius_out * 2, radius_out * 2, fillColor, lineStyle, {matrix: matrix});
		if (radius_in > 0)
		{
			FlxSpriteUtil.drawRect(this, (radius_out - radius_in), (radius_out - radius_in), radius_in * 2, radius_in * 2, FlxColor.RED, null,
				{matrix: matrix, blendMode: BlendMode.ERASE, smoothing: true});
		}
		FlxSpriteUtil.drawRect(this, (radius_out - radius_in), (radius_out - radius_in), radius_in * 2, radius_in * 2, FlxColor.TRANSPARENT, lineStyle,
			{matrix: matrix});
	}

	inline function set_radius_out(r:Float):Float
	{
		radius_out = r;
		shapeWidth = radius_out * 2;
		shapeHeight = radius_out * 2;
		shapeDirty = true;
		return radius_out;
	}

	inline function set_radius_in(r:Float):Float
	{
		radius_in = r;
		shapeDirty = true;
		return radius_in;
	}

	override function getStrokeOffsetX():Float
	{
		return strokeBuffer / 2;
	}

	override function getStrokeOffsetY():Float
	{
		return strokeBuffer / 2;
	}

	override function get_strokeBuffer():Float
	{
		return lineStyle.thickness * 1.0;
	}
}
