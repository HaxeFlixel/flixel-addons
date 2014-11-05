package flixel.addons.display.shapes;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Shape;
import flash.geom.Matrix;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxSpriteUtil.LineStyle;
import openfl.geom.Rectangle;
import openfl.display.BitmapDataChannel;
import openfl.geom.Point;

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
		super(X, Y, 0, 0, LineStyle_, FillColor, RadiusOut * 2, RadiusOut * 2);
		
		radius_out = RadiusOut;
		radius_in = RadiusIn;
		
		shape_id = FlxShapeType.DONUT;
	}
	
	override public function drawSpecificShape(?matrix:Matrix):Void 
	{
		var cx:Float = Math.ceil(width / 2);
		var cy:Float = Math.ceil(height / 2);
		FlxSpriteUtil.drawCircle(this, cx, cy, radius_out, fillColor, lineStyle, { matrix: matrix } );
		
		if (radius_in > 0)
		{
			FlxSpriteUtil.drawCircle(this, cx, cy, radius_in, FlxColor.RED, null, { matrix: matrix, blendMode:BlendMode.ERASE, smoothing: true });
			FlxSpriteUtil.drawCircle(this, cx, cy, radius_in, FlxColor.TRANSPARENT, lineStyle, { matrix: matrix } );
		}
	}
	
	private static var helperSprite:FlxSprite;
	
	private inline function set_radius_out(r:Float):Float
	{
		radius_out = r;
		shapeWidth = radius_out * 2;
		shapeHeight = radius_out * 2;
		shapeDirty = true;
		return radius_out;
	}

	private inline function set_radius_in(r:Float):Float
	{
		radius_in = r;
		shapeDirty = true;
		return radius_in;
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