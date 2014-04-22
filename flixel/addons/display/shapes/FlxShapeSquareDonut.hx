package flixel.addons.display.shapes;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Shape;
import flash.geom.Matrix;
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
	public function new(X:Float, Y:Float, RadiusOut:Float, RadiusIn:Float, LineStyle_:LineStyle, FillStyle_:FillStyle) 
	{
		shape_id = "square_donut";
		
		var strokeBuffer:Float = (lineStyle.thickness);
		
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
		
		super(X, Y, w, h, LineStyle_, FillStyle_, trueWidth, trueHeight);
	}
	
	override public function drawSpecificShape(?matrix:Matrix):Void 
	{
		var cx:Float = Math.ceil(width / 2);
		var cy:Float = Math.ceil(height / 2);
		
		FlxSpriteUtil.drawRect(this, 0, 0, radius_out * 2, radius_out * 2, fillStyle.color, lineStyle, fillStyle, { matrix: matrix });
		if (radius_in > 0) {
			FlxSpriteUtil.drawRect(this, (radius_out - radius_in), (radius_out - radius_in), radius_in * 2, radius_in * 2, FlxColor.RED, null, fillStyle, { matrix: matrix, blendMode: BlendMode.ERASE, smoothing: true});
		}
		FlxSpriteUtil.drawRect(this, (radius_out - radius_in), (radius_out - radius_in), radius_in * 2, radius_in * 2, FlxColor.TRANSPARENT, lineStyle, null, { matrix: matrix });
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