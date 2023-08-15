package flixel.addons.display.shapes;

import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Matrix;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxSpriteUtil.LineStyle;

class FlxShapeBox extends FlxShape
{
	public function new(X:Float, Y:Float, W:Float, H:Float, LineStyle_:LineStyle, FillColor:FlxColor)
	{
		super(X, Y, 0, 0, LineStyle_, FillColor, W, H);

		shape_id = FlxShapeType.BOX;
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

	override public function drawSpecificShape(?matrix:Matrix):Void
	{
		FlxSpriteUtil.drawRect(this, lineStyle.thickness / 2, lineStyle.thickness / 2, shapeWidth, shapeHeight, fillColor, lineStyle);
	}
}
