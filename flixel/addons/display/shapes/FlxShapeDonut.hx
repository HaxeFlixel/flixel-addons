package flixel.addons.display.shapes;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Shape;
import flash.geom.Matrix;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxSpriteUtil.LineStyle;

class FlxShapeDonut extends FlxShape 
{
	public var radius_out(default, set):Float;
	public var radius_in(default, set):Float;

	/**
	 * Creates a FlxSprite with a donut drawn on top of it. 
	 * X/Y is where the SPRITE is, the donut's upper-left
	 */
	public function new(X:Float, Y:Float, RadiusOut:Float, RadiusIn:Float, LineStyle_:LineStyle, FillColor:FlxColor) 
	{
		shape_id = "donut";
		
		var strokeBuffer:Float = (LineStyle_.thickness);
		
		radius_out = RadiusOut;
		radius_in = RadiusIn;
		
		var trueWidth:Float = radius_out * 2;
		var trueHeight:Float = trueWidth;
		
		var w:Float = trueWidth + strokeBuffer;		//create buffer space for stroke
		var h:Float = trueHeight + strokeBuffer;
		
		if (w <= 0)
			w = strokeBuffer;
		if (h <= 0) 
			h = strokeBuffer;
		
		super(X, Y, w, h, LineStyle_, FillColor, trueWidth, trueHeight);
	}
	
	override public function drawSpecificShape(?matrix:Matrix):Void 
	{
		var cx:Float = Math.ceil(width / 2);
		var cy:Float = Math.ceil(height / 2);
		FlxSpriteUtil.drawCircle(this, cx, cy, radius_out, fillColor, lineStyle, { matrix: matrix } );
		
		if (radius_in > 0) 
			FlxSpriteUtil.drawCircle(this, cx, cy, radius_in, FlxColor.RED, null, { matrix: matrix, blendMode: BlendMode.ERASE, smoothing: true });
		
		FlxSpriteUtil.drawCircle(this, cx, cy, radius_in, FlxColor.TRANSPARENT, lineStyle, { matrix: matrix });
	}
	
	private inline function set_radius_out(r:Float):Float
	{
		radius_out = r;
		shapeDirty = true;
		return radius_out;
	}

	private inline function set_radius_in(r:Float):Float
	{
		radius_in = r;
		shapeDirty = true;
		return radius_in;
	}
}