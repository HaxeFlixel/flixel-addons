package flixel.addons.display.shapes;

import flash.display.BitmapData;
import flash.filters.GlowFilter;
import flash.geom.Matrix;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxSpriteUtil.LineStyle;
import flixel.math.FlxVector;

/**
 * This creates a Lightning bolt drawn on top of a FlxSprite object.
 *
 * TODO:
 * I might not currently be adding enough border room to properly account for the filter effect
 */
class FlxShapeLightning extends FlxShapeLine
{
	public var lightningStyle(default, set):LightningStyle;

	// low number = higher detail
	var detail:Float;

	var magnitude:Float;

	var list_segs:Array<LineSegment>;
	var list_branch:Array<LineSegment>;

	/**
	 * Creates a lightning bolt!
	 *
	 * @param	X			X location of the sprite canvas
	 * @param	Y			Y location of the sprite canvas
	 * @param	A			start point, relative to canvas
	 * @param	B			end point, relative to canvas
	 * @param	Style		LightningStyle object
	 * @param	UseDefaults	use default settings to fill in style gaps?
	 */
	public function new(X:Float, Y:Float, A:FlxPoint, B:FlxPoint, Style:LightningStyle, UseDefaults:Bool = true)
	{
		lightningStyle = Style;

		var v = new FlxVector(A.x - B.x, A.y - B.y);
		magnitude = v.length;

		if (UseDefaults)
		{
			if (lightningStyle.displacement == null)
			{
				lightningStyle.displacement = 25.0;
			}
			if (lightningStyle.detail == null)
			{
				lightningStyle.detail = 1.0;
			}
			if (lightningStyle.halo_colors == null)
			{
				lightningStyle.halo_colors = [0xff88aaee, 0xff5555cc, 0xff334488]; // default colors
			}
		}

		list_segs = new Array<LineSegment>();
		list_branch = new Array<LineSegment>();

		super(X, Y, A, B, {thickness: lightningStyle.thickness, color: lightningStyle.color});

		// create the main lightning bolt
		calculate(A, B, lightningStyle.displacement, 0);

		shape_id = FlxShapeType.LIGHTNING;
	}

	inline function addSegment(Ax:Float, Ay:Float, Bx:Float, By:Float):Void
	{
		list_segs.push(new LineSegment(Ax, Ay, Bx, By));
	}

	function calculate(A:FlxPoint, B:FlxPoint, Displacement:Float, Iteration:Int):Void
	{
		if (Displacement < lightningStyle.detail)
		{
			addSegment(A.x, A.y, B.x, B.y);
		}
		else
		{
			var mid:FlxPoint = new FlxPoint();
			mid.x = (A.x + B.x) / 2;
			mid.y = (A.y + B.y) / 2;
			var dispX:Float = FlxG.random.float(-0.5, 0.5);
			var dispY:Float = FlxG.random.float(-0.5, 0.5);
			mid.x += dispX * Displacement;
			mid.y += dispY * Displacement;
			calculate(A, mid, Displacement / 2, Iteration);
			calculate(B, mid, Displacement / 2, Iteration);
		}
		shapeDirty = true;
	}

	inline function set_lightningStyle(Style:LightningStyle):LightningStyle
	{
		lightningStyle = Style;
		shapeDirty = true;
		return lightningStyle;
	}

	function copyLineStyle(ls:LineStyle):LineStyle
	{
		var ls2:LineStyle = {
			thickness: ls.thickness,
			color: ls.color,
			pixelHinting: ls.pixelHinting,
			scaleMode: ls.scaleMode,
			capsStyle: ls.capsStyle,
			jointStyle: ls.jointStyle,
			miterLimit: ls.miterLimit
		}
		return ls2;
	}

	override public function drawSpecificShape(?matrix:Matrix):Void
	{
		var up:Float = Math.POSITIVE_INFINITY;
		var left:Float = Math.POSITIVE_INFINITY;
		var down:Float = 0;
		var right:Float = 0;

		for (l in list_segs)
		{
			if (l.ax < left)
			{
				left = l.ax;
			}
			if (l.bx < left)
			{
				left = l.bx;
			}
			if (l.ay < up)
			{
				up = l.ay;
			}
			if (l.by < up)
			{
				up = l.by;
			}
			if (l.ax > right)
			{
				right = l.ax;
			}
			if (l.bx > right)
			{
				right = l.bx;
			}
			if (l.ay > down)
			{
				down = l.ay;
			}
			if (l.by > down)
			{
				down = l.by;
			}
		}

		if (left < 0)
		{
			expandLeft = left * -1;
		}
		if (right > shapeWidth)
		{
			expandRight = shapeWidth - right;
		}
		if (up < 0)
		{
			expandUp = up * -1;
		}
		if (down > shapeHeight)
		{
			expandDown = shapeHeight - down;
		}

		// bbox size, unstroked
		var newWidth:Float = right - left;
		var newHeight:Float = down - up;

		// size of canvas, w/ borders to account for stroke
		var canvasWidth:Int = Std.int(newWidth + strokeBuffer);
		var canvasHeight:Int = Std.int(newHeight + strokeBuffer);

		offset.x = 0;
		offset.y = 0;

		if ((canvasWidth != pixels.width) || (canvasHeight != pixels.height))
		{
			makeGraphic(canvasWidth, canvasHeight, FlxColor.TRANSPARENT, true);
		}
		else
		{
			pixels.fillRect(pixels.rect, FlxColor.TRANSPARENT);
		}

		_matrix.identity();

		var dw:Int = 0;
		var dh:Int = 0;

		// if it's poking off the left or top, I need to adjust the drawing location
		dw = Std.int(strokeBuffer / 2);
		dh = Std.int(strokeBuffer / 2);

		if (left < 0)
		{
			dw = Std.int(-left + (strokeBuffer / 2));
		}
		if (up < 0)
		{
			dh = Std.int(-up + (strokeBuffer / 2));
		}

		for (l in list_segs)
		{
			FlxSpriteUtil.drawLine(this, l.ax + dw, l.ay + dh, l.bx + dw, l.by + dh, lineStyle);
		}

		redrawFilter();
		shapeDirty = true;
	}

	function redrawFilter():Void
	{
		var skip = false;
		if (lightningStyle.halo_colors == null)
		{
			return;
		}

		if (!skip)
		{
			var i:Int = 0;
			var a:Array<GlowFilter> = new Array<GlowFilter>();
			for (halo_color in lightningStyle.halo_colors)
			{
				a.push(new GlowFilter(halo_color, (1.0 - (0.15 * i)), 3, 3));
				i++;
			}

			for (gf in a)
			{
				var pixels2:BitmapData = pixels.clone();
				pixels2.applyFilter(pixels, pixels.rect, _flashPointZero, gf);

				// remember size settings
				var w:Float = width;
				var h:Float = height;
				var ox:Float = offset.x;
				var oy:Float = offset.y;

				// update pixels
				pixels = pixels2;

				// restore size settings
				width = w;
				height = h;
				offset.x = ox;
				offset.y = oy;
			}

			fixBoundaries(shapeWidth, shapeHeight);
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

	override inline function fixBoundaries(trueWidth:Float, trueHeight:Float):Void
	{
		width = shapeWidth;
		height = shapeHeight;
		offset.x = expandLeft + getStrokeOffsetX();
		offset.y = expandUp + getStrokeOffsetY();
		updateMotion(0);
	}

	override function get_strokeBuffer():Float
	{
		return lightningStyle.thickness * 2;
	}

	var expandLeft:Float = 0;
	var expandRight:Float = 0;
	var expandUp:Float = 0;
	var expandDown:Float = 0;

	override function getStrokeOffsetX():Float
	{
		return strokeBuffer / 2;
	}

	override function getStrokeOffsetY():Float
	{
		return strokeBuffer / 2;
	}
}

typedef LightningStyle =
{
	?thickness:Float,
	?color:FlxColor,
	?displacement:Float,
	?detail:Float,
	?halo_colors:Array<FlxColor>
}

/**
 * Helper for FlxShapeLightning
 * @author Lars A. Doucet
 */
class LineSegment
{
	public var ax:Float;
	public var ay:Float;
	public var bx:Float;
	public var by:Float;

	public function new(Ax:Float, Ay:Float, Bx:Float, By:Float)
	{
		ax = Ax;
		ay = Ay;
		bx = Bx;
		by = By;
	}

	public inline function copy():LineSegment
	{
		return new LineSegment(ax, ay, bx, by);
	}
}
