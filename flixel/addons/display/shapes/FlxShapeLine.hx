package flixel.addons.display.shapes;

import flash.geom.Matrix;
import flixel.math.FlxPoint;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxSpriteUtil.LineStyle;

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
	 * @param	LineStyle_
	 */
	public function new(X:Float, Y:Float, a:FlxPoint, b:FlxPoint, LineStyle_:LineStyle) 
	{
		shape_id = "line";
		
		point = new FlxCallbackPoint(setPoint);
		point2 = new FlxCallbackPoint(setPoint);
		
		point.copyFrom(a);
		point2.copyFrom(b);
		
		a.putWeak();
		b.putWeak();
		
		var strokeBuffer:Float = (lineStyle.thickness);
		
		var trueWidth:Float = Math.abs(a.x - b.x);	//actual geometric size
		var trueHeight:Float = Math.abs(a.y - b.y);
		
		var w:Float = trueWidth + strokeBuffer;		//create buffer space for stroke
		var h:Float = trueHeight + strokeBuffer;
		
		if (w <= 0)
			w = strokeBuffer;
		if (h <= 0) 
			h = strokeBuffer;
		
		super(X, Y, w, h, LineStyle_, null, trueWidth, trueHeight);
	}

	override public function drawSpecificShape(?matrix:Matrix):Void 
	{
		FlxSpriteUtil.drawLine(this, point.x, point.y, point2.x, point2.y, lineStyle, { matrix: matrix });
	}
	
	private inline function setPoint(p:FlxPoint):Void 
	{
		shapeDirty = true;
	}
}