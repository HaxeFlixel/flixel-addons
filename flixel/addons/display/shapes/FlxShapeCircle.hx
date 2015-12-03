package flixel.addons.display.shapes;

import flash.geom.Matrix;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class FlxShapeCircle extends FlxShape 
{
	public var radius(default, set):Float;

	/**
	 * Creates a FlxSprite with a circle drawn on top of it. 
	 * X/Y is where the SPRITE is, the circle's upper-left
	 */
	public function new(X:Float, Y:Float, Radius:Float, LineStyle_:LineStyle, FillColor:FlxColor) 
	{
		super(X, Y, 0, 0, LineStyle_, FillColor, Radius*2, Radius*2);
		
		radius = Radius;
		
		shape_id = FlxShapeType.CIRCLE;
	}
	
	override public inline function drawSpecificShape(?matrix:Matrix):Void 
	{
		FlxSpriteUtil.drawCircle(this, Math.ceil(width / 2), Math.ceil(height / 2), radius, fillColor, lineStyle, { matrix: matrix });
	}
	
	private inline function set_radius(r:Float):Float
	{
		radius = r;
		shapeWidth = r * 2;
		shapeHeight = r * 2;
		shapeDirty = true;
		return radius;
	}
	
	private override function getStrokeOffsetX():Float
	{
		return strokeBuffer / 2;
	}
	
	private override function getStrokeOffsetY():Float
	{
		return strokeBuffer / 2;
	}
	
	private override function get_strokeBuffer():Float
	{
		return lineStyle.thickness * 1.0;
	}
}
