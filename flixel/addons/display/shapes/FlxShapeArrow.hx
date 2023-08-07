package flixel.addons.display.shapes;

import openfl.geom.Matrix;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;
import flixel.util.FlxSpriteUtil;

class FlxShapeArrow extends FlxShape
{
	public var outlineStyle(default, set):LineStyle;
	public var arrowSize(default, set):Float;

	public var point(default, null):FlxPoint;
	public var point2(default, null):FlxPoint;

	var _matrix2:Matrix;
	var _vertices:Array<FlxPoint>;

	/**
	 * Creates a line with an arrowhead on the end point
	 *
	 * @param	X				X location of the sprite canvas
	 * @param	Y				Y location of the sprite canvas
	 * @param	Start			starting point of the arrow
	 * @param	End				ending point of the arrow (this is where the arrowhead is)
	 * @param	ArrowSize		how big the arrow is (height)
	 * @param	LineStyle_		line style for the line and arrowhead
	 * @param	OutlineStyle_	line style for the outer line (optional)
	 */
	public function new(X:Float, Y:Float, Start:FlxPoint, End:FlxPoint, ArrowSize:Float, LineStyle_:LineStyle, ?OutlineStyle_:LineStyle)
	{
		arrowSize = ArrowSize;
		outlineStyle = OutlineStyle_;

		point = new FlxCallbackPoint(onSetPoint);
		point2 = new FlxCallbackPoint(onSetPoint);

		point.copyFrom(Start);
		point2.copyFrom(End);

		Start.putWeak();
		End.putWeak();

		var trueWidth:Float = Math.abs(point.x - point2.x); // actual geometric size
		var trueHeight:Float = Math.abs(point.y - point2.y);

		super(X, Y, 0, 0, LineStyle_, FlxColor.TRANSPARENT, trueWidth, trueHeight);

		lineStyle = LineStyle_;

		shape_id = FlxShapeType.ARROW;
	}

	override function getStrokeOffsetX():Float
	{
		return strokeBuffer / 6;
	}

	override function getStrokeOffsetY():Float
	{
		return strokeBuffer / 6;
	}

	override function get_strokeBuffer():Float
	{
		return lineStyle.thickness * 3.0;
	}

	override function getStrokeOffsetMatrix(matrix:Matrix):Matrix
	{
		var buffer:Float = strokeBuffer / 3;
		matrix.identity();
		matrix.translate(buffer, buffer);
		return matrix;
	}

	override public function destroy():Void
	{
		point = null;
		point2 = null;
		FlxDestroyUtil.destroyArray(_vertices);
		_vertices = null;
		_matrix2 = null;
		_matrix = null;
		outlineStyle = null;
		super.destroy();
	}

	public override function drawSpecificShape(?matrix:Matrix):Void
	{
		if (_matrix2 == null)
		{
			_matrix2 = new Matrix();
		}

		// generate the arrowhead
		var vertices:Array<FlxPoint> = new Array<FlxPoint>();

		vertices.push(FlxPoint.get(0, -arrowSize));
		vertices.push(FlxPoint.get(-arrowSize, -arrowSize));
		vertices.push(FlxPoint.get(0, 0));
		vertices.push(FlxPoint.get(arrowSize, -arrowSize));
		vertices.push(FlxPoint.get(0, -arrowSize)); // close it up

		// get arrowhead rotation vector
		var fv = FlxPoint.get(point.x - point2.x, point.y - point2.y);

		var canvasWidth:Int = Std.int(Math.max(shapeWidth, arrowSize * 2) + strokeBuffer);
		var canvasHeight:Int = Std.int(Math.max(shapeHeight, arrowSize * 2) + strokeBuffer);

		if (pixels.width != canvasWidth || pixels.height != pixels.height)
		{
			makeGraphic(canvasWidth, canvasHeight, FlxColor.TRANSPARENT, true);
		}
		else
		{
			pixels.fillRect(pixels.rect, FlxColor.TRANSPARENT);
		}

		_matrix2.identity();

		// rotate so arrow tip is pointing towards point2
		_matrix2.rotate(fv.radians + Math.PI / 2);

		// translate so that origin is lined up with point2
		_matrix2.translate(lineStyle.thickness + point2.x, lineStyle.thickness + point2.y);

		var dw:Float = ((arrowSize * 2) - shapeWidth) / 2;
		var dh:Float = ((arrowSize * 2) - shapeHeight) / 2;

		dw = dw < 0 ? 0 : dw;
		dh = dh < 0 ? 0 : dh;

		_matrix.translate(dw, dh);
		_matrix2.translate(dw, dh);

		if (outlineStyle != null)
		{
			// draw the outline
			FlxSpriteUtil.drawLine(this, point.x, point.y, point2.x, point2.y, outlineStyle, {matrix: matrix});

			// draw the arrowhead outline
			FlxSpriteUtil.drawPolygon(this, vertices, outlineStyle.color, outlineStyle, {matrix: _matrix2});
		}

		// draw the line itself
		FlxSpriteUtil.drawLine(this, point.x, point.y, point2.x, point2.y, lineStyle, {matrix: matrix});

		// draw the arrowhead
		FlxSpriteUtil.drawPolygon(this, vertices, lineStyle.color, lineStyle, {matrix: _matrix2});

		fixBoundaries(Math.abs(point.x - point2.x), Math.abs(point.y - point2.y));
	}

	inline function onSetPoint(p:FlxPoint):Void
	{
		updatePoint();
	}

	function updatePoint():Void
	{
		shapeWidth = Math.abs(point.x - point2.x);
		shapeHeight = Math.abs(point.y - point2.y);
		if (shapeWidth <= 0)
			shapeWidth = 1;
		if (shapeHeight <= 0)
			shapeHeight = 1;
		shapeDirty = true;
	}

	inline function set_arrowSize(f:Float):Float
	{
		arrowSize = f;
		shapeDirty = true;
		return arrowSize;
	}

	inline function set_outlineStyle(ls:LineStyle):LineStyle
	{
		outlineStyle = ls;
		shapeDirty = true;
		return outlineStyle;
	}

	override function fixBoundaries(trueWidth:Float, trueHeight:Float):Void
	{
		var diffX = (pixels.width - trueWidth);
		var diffY = (pixels.height - trueHeight);

		width = trueWidth; // reset width/height to geometric reality
		height = trueHeight;

		if (width <= 0)
		{
			width = 1;
			diffX -= 1;
		}
		if (height <= 0)
		{
			height = 1;
			diffY -= 1;
		}

		offset.x = diffX / 2;
		offset.y = diffY / 2;

		shapeDirty = true; // redraw the shape next draw() command
	}
}
