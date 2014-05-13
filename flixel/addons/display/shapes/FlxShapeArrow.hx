package flixel.addons.display.shapes;

import flash.geom.Matrix;
import flixel.FlxG;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;
import flixel.util.FlxSpriteUtil;
import flixel.math.FlxVector;

class FlxShapeArrow extends FlxShape
{
	public var outlineStyle(default, set):LineStyle;
	public var arrowSize(default, set):Float;
	
	public var point(default, null):FlxPoint;
	public var point2(default, null):FlxPoint;
	
	private var _matrix2:Matrix;
	private var _vertices:Array<FlxPoint>;
	
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
		
		shape_id = "arrow";
		
		point = new FlxCallbackPoint(setPointCallback);
		point2 = new FlxCallbackPoint(setPointCallback);
		
		point.copyFrom(Start);
		point.copyFrom(End);
		
		Start.putWeak();
		End.putWeak();
		
		var strokeBuffer:Float = (LineStyle_.thickness);
		
		var trueWidth:Float = Math.abs(point.x - point2.x);	//actual geometric size
		var trueHeight:Float = Math.abs(point.y - point2.y);
		
		var w:Float = trueWidth + strokeBuffer;		//create buffer space for stroke
		var h:Float = trueHeight + strokeBuffer;
		
		if (w <= 0)
			w = strokeBuffer;
		if (h <= 0) 
			h = strokeBuffer;
		
		super(X, Y, w, h, LineStyle_, null, trueWidth, trueHeight);
	}
	
	override public function destroy():Void
	{
		super.destroy();
		point = FlxDestroyUtil.destroy(point);
		point2 = FlxDestroyUtil.destroy(point2);
	}
	
	public override function drawSpecificShape(?matrix:Matrix):Void 
	{
		if (_matrix2 == null) 
			_matrix2 = new Matrix();
		
		//generate the arrowhead
		var vertices:Array<FlxPoint> = new Array<FlxPoint>();
		vertices.push(FlxPoint.get(0, arrowSize));
		vertices.push(FlxPoint.get(arrowSize*2, arrowSize));
		vertices.push(FlxPoint.get(arrowSize, 0));
		vertices.push(FlxPoint.get(0, arrowSize));		//close it up
		
		//get arrowhead rotation vector
		var fv = FlxVector.get(point.x - point2.x, point.y - point2.y);
		
		_matrix2.identity();
		_matrix2.translate( -arrowSize, 0);		//translate so origin is the tip of arrow
		
		//rotate so arrow tip is pointing towards point2
		_matrix2.rotate(fv.radians - Math.PI/2);
		
		//translate so that origin is lined up with point2
		_matrix2.translate(lineStyle.thickness/2+point2.x, lineStyle.thickness/2+point2.y);
		
		var buffer:Float = 0;
		
		if (outlineStyle != null) 
		{
			//draw the outline
			FlxSpriteUtil.drawLine(this, point.x, point.y, point2.x, point2.y, outlineStyle, { matrix: matrix });
			//draw the arrowhead outline
			FlxSpriteUtil.drawPolygon(this, vertices, outlineStyle.color, outlineStyle, { matrix: _matrix2 });
		}
		
		//draw the line itself
		FlxSpriteUtil.drawLine(this, point.x, point.y, point2.x, point2.y, lineStyle, { matrix: matrix });
		
		//draw the arrowhead
		FlxSpriteUtil.drawPolygon(this, vertices, lineStyle.color, lineStyle, { matrix: _matrix2 });
		
		fixBoundaries(Math.abs(point.x - point2.x), Math.abs(point.y - point2.y));
	}
	
	private inline function setPointCallback(p:FlxPoint):Void 
	{
		shapeDirty = true;
	}
	
	private inline function set_arrowSize(f:Float):Float 
	{
		arrowSize = f;
		shapeDirty = true;
		return arrowSize;
	}
	
	private inline function set_outlineStyle(ls:LineStyle):LineStyle 
	{
		outlineStyle = ls;
		shapeDirty = true;
		return outlineStyle;
	}
}