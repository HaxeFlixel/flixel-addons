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
		shape_id = "circle";
		
		var strokeBuffer:Float = (LineStyle_.thickness);
		
		radius = Radius;
		
		var trueWidth:Float = radius * 2;
		var trueHeight:Float = trueWidth;
		
		var w:Float = trueWidth + strokeBuffer;		//create buffer space for stroke
		var h:Float = trueHeight + strokeBuffer;
		
		if (w <= 0)
			w = strokeBuffer;
		if (h <= 0) 
			h = strokeBuffer;
		
		super(X, Y, w, h, LineStyle_, FillColor, trueWidth, trueHeight);
	}
	
	override public inline function drawSpecificShape(?matrix:Matrix):Void 
	{
		FlxSpriteUtil.drawCircle(this, Math.ceil(width / 2), Math.ceil(height / 2), radius, fillColor, lineStyle, { matrix: matrix });
	}
	
	private inline function set_radius(r:Float):Float
	{
		radius = r;
		shapeDirty = true;
		return radius;
	}
}
