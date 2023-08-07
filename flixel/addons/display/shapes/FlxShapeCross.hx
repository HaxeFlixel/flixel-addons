package flixel.addons.display.shapes;

import openfl.geom.Matrix;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxSpriteUtil.LineStyle;

/**
 * A cross shape drawn onto a FlxSprite. Useful for tactics games and stuff!
 */
class FlxShapeCross extends FlxShape
{
	public var horizontalLength(default, set):Float;
	public var horizontalThickness(default, set):Float;

	public var verticalLength(default, set):Float;
	public var verticalThickness(default, set):Float;

	/**
	 * Sets where the two arms intersect vertically.
	 * value (0-1): 0 makes a T, 1 makes inverted T, 0.5 makes a +; (if intersectionH is 0.5)
	 */
	public var intersectionV(default, set):Float;

	/**
	 * Sets where the two arms intersect horizontally.
	 * value (0-1): 0 makes a |-, 1 makes a -|, 0.5 makes a +; (if intersectionV is 0.5)
	 */
	public var intersectionH(default, set):Float;

	var vertices:Array<FlxPoint>;

	public function new(X:Float, Y:Float, HLength:Float, HThickness:Float, VLength:Float, VThickness:Float, IntersectionH:Float, IntersectionV:Float,
			LineStyle_:LineStyle, FillColor:FlxColor)
	{
		super(X, Y, 0, 0, LineStyle_, FillColor, HLength, VLength);

		horizontalLength = HLength;
		horizontalThickness = HThickness;
		verticalLength = VLength;
		verticalThickness = VThickness;
		intersectionH = IntersectionH;
		intersectionV = IntersectionV;

		shape_id = FlxShapeType.CROSS;
	}

	public override function destroy():Void
	{
		super.destroy();
		if (vertices != null)
		{
			while (vertices.length > 0)
				vertices.pop();
		}
		vertices = null;
	}

	public override function drawSpecificShape(?matrix:Matrix):Void
	{
		if (vertices == null)
		{
			vertices = new Array<FlxPoint>();
			var i:Int = 13;
			while (i > 0)
			{
				vertices.push(FlxPoint.get());
				i--;
			}
		}

		// For sanity/readability's sake, I worked out the math using two rectangles

		// fr == vertical rectangle
		_flashRect.x = (horizontalLength - verticalThickness) * intersectionH; // line up the vertical rectangle with center
		_flashRect.y = 0;
		_flashRect.width = verticalThickness;
		_flashRect.height = verticalLength;

		// fr2 == horizontal rectangle
		_flashRect2.x = 0;
		_flashRect2.y = (verticalLength - horizontalThickness) * intersectionV;
		_flashRect2.width = horizontalLength;
		_flashRect2.height = horizontalThickness;

		// Copy vertices from the two rectangles
		vertices[0].y = _flashRect.top;
		vertices[0].x = _flashRect.left; // top-left of vertical beam
		vertices[1].y = _flashRect.top;
		vertices[1].x = _flashRect.right; // top-right
		vertices[6].y = _flashRect.bottom;
		vertices[6].x = _flashRect.right; // bottom-right
		vertices[7].y = _flashRect.bottom;
		vertices[7].x = _flashRect.left; // bottom-left

		// Copy vertices from the two rectangles
		vertices[3].y = _flashRect2.top;
		vertices[3].x = _flashRect2.right; // top-right of horizontal beam
		vertices[4].y = _flashRect2.bottom;
		vertices[4].x = _flashRect2.right; // bottom-right
		vertices[9].y = _flashRect2.bottom;
		vertices[9].x = _flashRect2.left; // bottom-left
		vertices[10].y = _flashRect2.top;
		vertices[10].x = _flashRect2.left; // top-left

		// Create intersection points
		vertices[2].x = vertices[1].x; // NE intersection
		vertices[2].y = vertices[3].y;

		vertices[5].x = vertices[6].x; // SE intersection
		vertices[5].y = vertices[4].y;

		vertices[8].x = vertices[7].x; // SW intersection
		vertices[8].y = vertices[9].y;

		vertices[11].x = vertices[0].x; // NW intersection
		vertices[11].y = vertices[10].y;

		// close it up
		vertices[12].x = vertices[0].x;
		vertices[12].y = vertices[0].y;

		// reset these just in case that's important
		_flashRect.x = 0;
		_flashRect.y = 0;
		_flashRect2.x = 0;
		_flashRect2.y = 0;

		// I don't know why these next two lines are necessary, but without them only half of the object is drawn
		pixels.fillRect(pixels.rect, FlxColor.TRANSPARENT);
		pixels = pixels;

		_matrix.identity();
		_matrix.translate(lineStyle.thickness / 2, lineStyle.thickness / 2);

		FlxSpriteUtil.drawPolygon(this, vertices, fillColor, lineStyle, {matrix: _matrix});

		fixBoundaries(horizontalLength, verticalLength);
	}

	inline function set_horizontalLength(f:Float):Float
	{
		horizontalLength = f;
		shapeWidth = Math.max(horizontalLength, verticalThickness);
		shapeDirty = true;
		return horizontalLength;
	}

	inline function set_horizontalThickness(f:Float):Float
	{
		horizontalThickness = f;
		shapeHeight = Math.max(verticalLength, horizontalThickness);
		shapeDirty = true;
		return horizontalThickness;
	}

	inline function set_verticalLength(f:Float):Float
	{
		verticalLength = f;
		shapeHeight = Math.max(verticalLength, horizontalThickness);
		shapeDirty = true;
		return verticalLength;
	}

	inline function set_verticalThickness(f:Float):Float
	{
		verticalThickness = f;
		shapeWidth = Math.max(horizontalLength, verticalThickness);
		shapeDirty = true;
		return verticalThickness;
	}

	function set_intersectionV(f:Float):Float
	{
		if (f > 1)
		{
			f = 1;
		}
		if (f < 0)
		{
			f = 0;
		}
		intersectionV = f;
		shapeDirty = true;
		return intersectionV;
	}

	function set_intersectionH(f:Float):Float
	{
		if (f > 1)
		{
			f = 1;
		}
		if (f < 0)
		{
			f = 0;
		}
		intersectionH = f;
		shapeDirty = true;
		return intersectionH;
	}
}
