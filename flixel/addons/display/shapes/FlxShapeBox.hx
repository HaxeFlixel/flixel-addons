package flixel.addons.display.shapes;

import flash.display.BitmapData;
import flash.display.Shape;
import flash.geom.Matrix;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxSpriteUtil.LineStyle;

class FlxShapeBox extends FlxShape 
{
	//the actual boundaries of the underlying shape
	public var shapeWidth(default, set):Float;		
	public var shapeHeight(default, set):Float;
	
	/**
	 * Creates a FlxSprite with a circle drawn on top of it. 
	 * X/Y is where the SPRITE is, the circle's upper-left
	 */
	public function new(X:Float, Y:Float, W:Float, H:Float, LineStyle_:LineStyle, FillStyle_:FillStyle) 
	{
		shape_id = "box";
		
		var strokeBuffer:Float = (LineStyle_.thickness);
		shapeWidth = W;
		shapeHeight = H;
		
		var w:Float = shapeWidth + strokeBuffer;		//create buffer space for stroke
		var h:Float = shapeHeight + strokeBuffer;
		
		if (w <= 0)
			w = strokeBuffer;
		if (h <= 0) 
			h = strokeBuffer;
		
		super(X, Y, w, h, LineStyle_, FillStyle_, shapeWidth, shapeHeight);
	}
	
	override public function drawSpecificShape(?matrix:Matrix):Void 
	{
		FlxSpriteUtil.drawRect(this, lineStyle.thickness/2, lineStyle.thickness/2, shapeWidth, shapeHeight, fillStyle.color, lineStyle);
	}
	
	private inline function set_shapeWidth(f:Float):Float
	{
		shapeWidth = f;
		shapeDirty = true;
		return shapeWidth;
	}

	private inline function set_shapeHeight(f:Float):Float
	{
		shapeHeight = f;
		shapeDirty = true;
		return shapeHeight;
	}
}