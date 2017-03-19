package flixel.addons.display;

import flixel.FlxStrip;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.render.common.DrawItem.DrawData;
import flixel.util.FlxColor;

class FlxRope extends FlxStrip
{
	/**
	 * Points of the rope.
	 */
	public var points(default, set):Array<FlxPoint>;
	
	/**
	 * Rope sprite constructor.
	 * @param	X				x position of the sprite.
	 * @param	Y				y position of the sprite.
	 * @param	SimpleGraphic	texture for this sprite.
	 * @param	Points			points of the rope.
	 */
	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset, Points:Array<FlxPoint>) 
	{
		super(X, Y, SimpleGraphic);
		
		vertices = new DrawData<Float>();
		uvtData = new DrawData<Float>();
		indices = new DrawData<Int>();
		
		this.points = Points;
	}
	
	override public function destroy():Void 
	{
		points = null;
		
		super.destroy();
	}
	
	/**
	 * Updates indices and uv coordinates of the sprite.
	 * You should call this method is you manually add new points to this rope by directly adding new point objects.
	 */
	public function refresh():Void
	{
		if (points.length < 1)
			return;
		
		var uvs:DrawData<Float> = uvtData;
		uvs.splice(0, uvs.length);
		
		uvs[0] = 0.0;
		uvs[1] = 0.0;
		uvs[2] = 0.0;
		uvs[3] = 1.0;
		
		var indexes:DrawData<Int> = this.indices;
		indexes.splice(0, indexes.length);
		
		indexes[0] = 0;
		indexes[1] = 1;
		
		var total:Int = points.length;
		var point:FlxPoint;
		var index:Int;
		var amount:Float;
		
		for (i in 1...total)
		{
			point = points[i];
			index = i * 4;
			
			// time to do some smart drawing!
			amount = i / (total - 1);
			
			uvs[index] = amount;
			uvs[index + 1] = 0.0;
			
			uvs[index + 2] = amount;
			uvs[index + 3] = 1.0;
		}
		
		var indexPos:Int = 0;
		
		for (i in 0...(total - 1))
		{
			index = i * 2;
			
			indexes[indexPos] = index;
			indexes[indexPos + 1] = index + 1;
			indexes[indexPos + 2] = index + 2;
			indexes[indexPos + 3] = index + 1;
			indexes[indexPos + 4] = index + 3;
			indexes[indexPos + 5] = index + 2;
			
			indexPos += 6;
		}
		
		dirty = true;
	}
	
	/**
	 * Updates positions of vertices of this sprite.
	 * You should call this method after manually changing positons of `points` in this sprite.
	 */
	public function updateVertices():Void
	{
		if (points == null || points.length < 2)
			return;
		
		var numPoints:Int = points.length;
		
		var lastPoint:FlxPoint = points[0];
		var nextPoint:FlxPoint;
		var perpX:Float = 0;
		var perpY:Float = 0;
		
		var vertices:DrawData<Float> = data.vertices;
		vertices.splice(0, vertices.length);
		
		var total:Int = points.length;
		var point:FlxPoint;
		var index:Int;
		var perpLength:Float;
		var num:Float = this.graphic.height / 2;
		
		for (i in 0...total)
		{
			point = points[i];
			index = i * 4;
			
			if (i < numPoints - 1)
				nextPoint = points[i + 1];
			else
				nextPoint = point;
			
			perpY = -(nextPoint.x - lastPoint.x);
			perpX = nextPoint.y - lastPoint.y;
			
			perpLength = Math.sqrt(perpX * perpX + perpY * perpY);
			perpX /= perpLength;
			perpY /= perpLength;
			
			perpX *= num;
			perpY *= num;
			
			vertices[index] = point.x + perpX;
			vertices[index + 1] = point.y + perpY;
			vertices[index + 2] = point.x - perpX;
			vertices[index + 3] = point.y - perpY;
			
			lastPoint = point;
		}
		
		data.verticesDirty = true;
	}
	
	private function set_points(value:Array<FlxPoint>):Array<FlxPoint>
	{
		points = value;
		
		if (value != null)
		{
			refresh();
			updateVertices();
		}
		
		return value;
	}
	
	override function set_graphic(Value:FlxGraphic):FlxGraphic 
	{
		super.set_graphic(Value);
		
		if (Value != null)
			updateVertices();
		
		return Value;
	}
	
}