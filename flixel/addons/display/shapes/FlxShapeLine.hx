package flixel.addons.display.shapes;

import openfl.geom.Matrix;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil.LineStyle;
import flixel.util.FlxSpriteUtil;

class FlxShapeLine extends FlxShape
{
	public var point(default, null):FlxPoint;
	public var point2(default, null):FlxPoint;

	/**
	 * Creates a FlxSprite with a line drawn on top of it. X/Y is where the SPRITE is, and points a&b are RELATIVE to this object's origin.
	 * Points with negative values will not draw correctly since they'll appear beyond the sprite's canvas.
	 *
	 * @param	X x position of the canvas
	 * @param	Y y position of the canvas
	 * @param	a first point in the line (relative to the sprite's origin)
	 * @param	b second point in the line (relative to the sprite's origin)
	 * @param	LineStyle_ Drawing style for strokes -- see `flixel.util.FlxSpriteUtil.LineStyle`
	 */
	public function new(X:Float, Y:Float, a:FlxPoint, b:FlxPoint, LineStyle_:LineStyle)
	{
		var trueWidth:Float = Math.abs(a.x - b.x); // actual geometric size
		var trueHeight:Float = Math.abs(a.y - b.y);

		super(X, Y, 0, 0, LineStyle_, FlxColor.TRANSPARENT, trueWidth, trueHeight);

		point = new FlxCallbackPoint(onSetPoint);
		point2 = new FlxCallbackPoint(onSetPoint);

		point.copyFrom(a);
		point2.copyFrom(b);

		a.putWeak();
		b.putWeak();

		shape_id = FlxShapeType.LINE;
	}

	override public function destroy():Void
	{
		point = null;
		point2 = null;
		super.destroy();
	}

	override public function drawSpecificShape(?matrix:Matrix):Void
	{
		FlxSpriteUtil.drawLine(this, point.x, point.y, point2.x, point2.y, lineStyle, {matrix: matrix});
	}

	inline function onSetPoint(p:FlxPoint):Void
	{
		updatePoint();
	}

	function updatePoint():Void
	{
		shapeWidth = Math.abs(point.x - point2.x);
		shapeHeight = Math.abs(point.y - point2.y);
		if (shapeWidth <= 0)
			shapeWidth = 1;
		if (shapeHeight <= 0)
			shapeHeight = 1;
		shapeDirty = true;
	}

	override function get_strokeBuffer():Float
	{
		return lineStyle.thickness * 2.0;
	}

	override function getStrokeOffsetX():Float
	{
		return strokeBuffer / 2;
	}

	override function getStrokeOffsetY():Float
	{
		return strokeBuffer / 2;
	}
}
