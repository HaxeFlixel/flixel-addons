package flixel.addons.display.shapes;

import openfl.geom.Matrix;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class FlxShapeGrid extends FlxShapeBox
{
	public var cellWidth(default, set):Float;
	public var cellHeight(default, set):Float;
	public var cellsWide(default, set):Int;
	public var cellsTall(default, set):Int;

	/**
	 * Creates a FlxSprite with a grid drawn on top of it.
	 * X/Y is where the SPRITE is, the grid upper-left
	 */
	public function new(X:Float, Y:Float, CellWidth:Float, CellHeight:Float, CellsWide:Int, CellsTall:Int, LineStyle_:LineStyle, FillColor:FlxColor)
	{
		var w:Float = CellWidth * CellsWide;
		var h:Float = CellHeight * CellsTall;

		cellsWide = CellsWide;
		cellsTall = CellsTall;
		cellWidth = CellWidth;
		cellHeight = CellHeight;

		super(X, Y, w, h, LineStyle_, FillColor);

		shape_id = FlxShapeType.GRID;
	}

	override public function drawSpecificShape(?matrix:Matrix):Void
	{
		var ox:Float = (lineStyle.thickness / 2);
		var oy:Float = (lineStyle.thickness / 2);

		// draw the fill
		FlxSpriteUtil.drawRect(this, ox, oy, shapeWidth, shapeHeight, fillColor);

		// draw vertical lines
		for (iw in 0...cellsWide + 1)
			FlxSpriteUtil.drawLine(this, ox + (cellWidth * iw), oy, ox + (cellWidth * iw), oy + shapeHeight, lineStyle);

		// draw horizontal lines
		for (ih in 0...cellsTall + 1)
			FlxSpriteUtil.drawLine(this, ox, oy + (cellHeight * ih), ox + shapeWidth, oy + (cellHeight * ih), lineStyle);
	}

	inline function set_cellWidth(f:Float):Float
	{
		cellWidth = f;
		shapeDirty = true;
		return cellWidth;
	}

	inline function set_cellHeight(f:Float):Float
	{
		cellHeight = f;
		shapeDirty = true;
		return cellHeight;
	}

	inline function set_cellsWide(i:Int):Int
	{
		cellsWide = i;
		shapeDirty = true;
		return cellsWide;
	}

	inline function set_cellsTall(i:Int):Int
	{
		cellsTall = i;
		shapeDirty = true;
		return cellsTall;
	}
}
