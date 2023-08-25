package flixel.addons.display.shapes;

import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.Shape;
import openfl.geom.Matrix;
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
		FlxSpriteUtil.drawCircle(this, cx, cy, radius_out, fillColor, lineStyle, {matrix: matrix});

		if (radius_in > 0)
		{
			#if (cpp || neko)
			// Temporary work-around until OpenFL properly supports ERASE blend mode on CPP targets
			var zpt = new Point();
			var temp = new FlxSprite(0, 0, new BitmapData(cast pixels.width, cast pixels.height, false, 0xFFFFFF));
			temp.pixels.copyChannel(this.pixels, this.pixels.rect, zpt, BitmapDataChannel.ALPHA, BitmapDataChannel.BLUE);
			FlxSpriteUtil.drawCircle(temp, cx, cy, radius_in, FlxColor.BLACK, null, {matrix: matrix, smoothing: true});
			this.pixels.copyChannel(temp.pixels, temp.pixels.rect, zpt, BitmapDataChannel.BLUE, BitmapDataChannel.ALPHA);
			temp.destroy();
			#else
			FlxSpriteUtil.drawCircle(this, cx, cy, radius_in, FlxColor.RED, null, {matrix: matrix, blendMode: BlendMode.ERASE, smoothing: true});
			#end

			FlxSpriteUtil.drawCircle(this, cx, cy, radius_in, FlxColor.TRANSPARENT, lineStyle, {matrix: matrix});
		}
	}

	static var helperSprite:FlxSprite;

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
