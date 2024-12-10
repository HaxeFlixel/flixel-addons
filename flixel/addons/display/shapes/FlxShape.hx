package flixel.addons.display.shapes;

import openfl.display.BlendMode;
import openfl.geom.Matrix;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil.DrawStyle;
import flixel.util.FlxSpriteUtil.LineStyle;

/**
 * A convenience class for wrapping vector shape drawing in FlxSprites, all ready to go.
 * Don't use this class by itself -- use things like FlxLine, FlxCircle, that extend it
 * @author Lars A. Doucet
 */
class FlxShape extends FlxSprite
{
	public var lineStyle(default, set):LineStyle; // stroke settings
	public var fillColor(default, set):FlxColor; // fill color, FlxColor.TRANSPARENT means no fill

	// the actual boundaries of the underlying shape
	public var shapeWidth(default, set):Float;
	public var shapeHeight(default, set):Float;

	public var shape_id:FlxShapeType = FlxShapeType.UNKNOWN; // what kind of shape
	public var shapeDirty:Bool = false; // flag to flip to force it to redraw the shape

	/**
	 * (You should never instantiate this directly, only call it as a super)
	 * Creates a Shape wrapped in a FlxSprite
	 *
	 * @param	X				X location
	 * @param	Y				Y location
	 * @param	CanvasWidth		Width of pixel canvas
	 * @param	CanvasHeight	Height of pixel canvas
	 * @param	LineStyle_		Drawing style for strokes -- see `flixel.util.FlxSpriteUtil.LineStyle`
	 * @param	FillColor		Color of the fill. FlxColor.TRANSPARENT means no fill.
	 * @param	TrueWidth		Width of raw unstyled geometric object, ignoring line thickness, filters, etc
	 * @param	TrueHeight		Height of raw unstyled geometric object, ignoring line thickness, filters, etc
	 */
	public function new(X:Float, Y:Float, CanvasWidth:Float, CanvasHeight:Float, LineStyle_:LineStyle, FillColor:FlxColor, TrueWidth:Float = 0,
			TrueHeight:Float = 0)
	{
		super(X, Y);

		lineStyle = LineStyle_;
		fillColor = FillColor;

		if (CanvasWidth == 0 && TrueWidth != 0)
		{
			CanvasWidth = TrueWidth + strokeBuffer;
		}
		if (CanvasHeight == 0 && TrueHeight != 0)
		{
			CanvasHeight = TrueHeight + strokeBuffer;
		}

		if (CanvasWidth < 1)
		{
			CanvasWidth = 1;
		}
		if (CanvasHeight < 1)
		{
			CanvasHeight = 1;
		}

		shapeWidth = TrueWidth;
		shapeHeight = TrueHeight;

		width = CanvasWidth;
		height = CanvasHeight;

		makeGraphic(Std.int(width), Std.int(height), FlxColor.TRANSPARENT, true);

		// we'll eventually want a public drawStyle parameter, but we'll also need an internval _drawStyle to do
		// some specific tricks for various shapes (special matrices, punching holes in Donut shapes by using ERASE blend mode, etc)
		_drawStyle = {
			matrix: null,
			colorTransform: null,
			blendMode: BlendMode.NORMAL,
			clipRect: null,
			smoothing: true
		};

		if (shapeWidth != 0 && shapeHeight != 0)
		{
			if (shapeWidth < CanvasWidth && shapeHeight < CanvasHeight)
			{
				fixBoundaries(shapeWidth, shapeHeight);
			}
		}

		shapeDirty = true; // draw the shape next draw() command
	}

	override public function destroy():Void
	{
		lineStyle = null;
		super.destroy();
	}

	public function drawSpecificShape(?matrix:Matrix):Void
	{
		// override per subclass
		// put your actual drawing function here
	}

	public function redrawShape():Void
	{
		var diffX:Int = Std.int(shapeWidth) - pixels.width;
		var diffY:Int = Std.int(shapeHeight) - pixels.height;

		if (diffX != 0 || diffY != 0)
		{
			var trueWidth:Float = shapeWidth;
			var trueHeight:Float = shapeHeight;
			makeGraphic(Std.int(width + strokeBuffer), Std.int(height + strokeBuffer), FlxColor.TRANSPARENT, true);
			fixBoundaries(trueWidth, trueHeight);
		}
		else
		{
			pixels.fillRect(pixels.rect, FlxColor.TRANSPARENT);
		}
		if (lineStyle.thickness > 1)
		{
			var matrix:Matrix = getStrokeOffsetMatrix(_matrix);
			drawSpecificShape(matrix);
		}
		else
		{
			drawSpecificShape();
		}
	}

	override public function draw():Void
	{
		if (shapeDirty)
		{
			redrawShape();
			shapeDirty = false; // call this AFTER incase redrawShape() sets shapeDirty = true
		}
		super.draw();
	}

	/********PRIVATE*********/
	var strokeBuffer(get, never):Float;

	var _drawStyle:DrawStyle;

	/**
	 * Fixes boundaries so that the sprite's bbox & origin line up with the underlying geometric object's
	 *
	 * @param	trueWidth	width of geometric object (ignoring strokes, etc)
	 * @param	trueHeight	height of geometric object (ignoring strokes, etc)
	 */
	function fixBoundaries(trueWidth:Float, trueHeight:Float):Void
	{
		width = trueWidth; // reset width/height to geometric reality
		height = trueHeight;

		offset.x = getStrokeOffsetX();
		offset.y = getStrokeOffsetY();

		shapeDirty = true; // redraw the shape next draw() command
	}

	function getStrokeOffsetX():Float
	{
		return strokeBuffer / 4;
	}

	function getStrokeOffsetY():Float
	{
		return strokeBuffer / 4;
	}

	function get_strokeBuffer():Float
	{
		return lineStyle.thickness * 2.0;
	}

	function getStrokeOffsetMatrix(matrix:Matrix):Matrix
	{
		var buffer:Float = strokeBuffer / 2;
		matrix.identity();
		matrix.translate(buffer, buffer);
		return matrix;
	}

	inline function set_fillColor(fc:FlxColor):FlxColor
	{
		fillColor = fc;
		shapeDirty = true;
		return fillColor;
	}

	inline function set_lineStyle(ls:LineStyle):LineStyle
	{
		lineStyle = ls;
		shapeDirty = true;
		return lineStyle;
	}

	inline function set_shapeWidth(f:Float):Float
	{
		shapeWidth = f;
		shapeDirty = true;
		return shapeWidth;
	}

	inline function set_shapeHeight(f:Float):Float
	{
		shapeHeight = f;
		shapeDirty = true;
		return shapeHeight;
	}
}
