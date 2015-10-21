package flixel.addons.display;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.Vector;

/**
 * ...
 * @author Adriano Lima
 */
class FlxClothSprite extends FlxSprite
{
	public var wind(default, null):FlxPoint = FlxPoint.get();
	
	public var iterations:Int = 3;
	
	public var columns(default, null):Int;
	public var rows(default, null):Int;
	public var widthInTiles(default, null):Float;
	public var heightInTiles(default, null):Float;
	public var points(default, null):Array<Point> = [];
	public var sticks(default, null):Array<Stick> = [];
	
	private var _v(default, null):Array<Float>;
	private var _i(default, null):Array<Int>;
	private var _u(default, null):Array<Float>;
	
	public var pinSide:Int;
	public var bitmapData:BitmapData;
	
	public function new(?X:Float = 0, ?Y:Float = 0, ?Graphic:FlxGraphicAsset, ?Columns:Int = 0, ?Rows:Int = 0, pinSide:Int = FlxObject.UP) 
	{
		super(X, Y);
		
		this.pinSide = pinSide;
		this.rows = Std.int(Math.max(2, Rows));
		this.columns = Std.int(Math.max(2, Columns));
		
		if (Graphic != null)
		{
			loadGraphic(Graphic);
		}
	}
	
	public function resetMesh(?Rows:Int = 0, ?Columns:Int = 0):Void
	{
		points = [];
		sticks = [];
		_v = [];
		_u = [];
		_i = [];
		
		if (bitmapData == null)
		{
			return;
		}
		
		this.rows = Std.int(Math.max(2, Rows));
		this.columns = Std.int(Math.max(2, Columns));
		this.widthInTiles = bitmapData.width / (columns - 1);
		this.heightInTiles = bitmapData.height / (rows - 1);
		
		for (r in 0...rows) 
		{
			for (c in 0...columns) 
			{
				points.push({
					x: c * widthInTiles,
					y: r * heightInTiles,
					oldx: c * widthInTiles,
					oldy: r * heightInTiles,
					pinned: ((r == 0 && pinSide & FlxObject.UP != 0) || (r == rows-1 && pinSide & FlxObject.DOWN != 0) || (c == 0 && pinSide & FlxObject.LEFT != 0) || (c == columns-1 && pinSide & FlxObject.RIGHT != 0))
				});
				
				_v.push(c * widthInTiles);
				_v.push(r * heightInTiles);
				
				_u.push((c) / (columns - 1));
				_u.push((r) / (rows - 1));
				
				if (c > 0)
				{
					sticks.push({
						p0: points[(r * columns) + c],
						p1: points[(r * columns) + c - 1],
						length: widthInTiles
					});
				}
				if (r > 0)
				{
					sticks.push({
						p0: points[(r * columns) + c],
						p1: points[((r - 1) * columns) + c],
						length: heightInTiles
					});
				}
				
				if (r > 0 && c > 0)
				{					
					_i.push((r * columns) + c);
					_i.push(((r - 1) * columns) + c - 1);
					_i.push(((r - 1) * columns) + c);
					
					_i.push((r * columns) + c);
					_i.push(((r - 1) * columns) + c - 1);
					_i.push((r * columns) + c - 1);
				}
			}
		}
	}
	
	function calcImage():Void
	{
		_v = [];
		
		var minX:Float = 0;
		var maxX:Float = 0;
		var minY:Float = 0;
		var maxY:Float = 0;
		
		for (p in points) 
		{
			_v.push(p.x);
			_v.push(p.y);
			
			minX = Math.min(minX, p.x);
			minY = Math.min(minY, p.y);
			maxX = Math.max(maxX, p.x);
			maxY = Math.max(maxY, p.y);
		}
		offset.x = -minX;
		offset.y = -minY;
		
		var i:Int = 0;
		while (i < _v.length - 1)
		{
			_v[i] = _v[i] - minX;
			_v[i + 1] = _v[i + 1] - minY;
			i+=2;
		}
		
		var w:Int = Std.int(Math.max(pixels.width, maxX - minX));
		var h:Int = Std.int(Math.max(pixels.height, maxY - minY));
		if (pixels.width < w || pixels.height < h)
		{
			trace("new BitmapData");
			pixels = new BitmapData(w, h, true, FlxColor.TRANSPARENT);
		}
		else
		{
			pixels.fillRect(pixels.rect, FlxColor.TRANSPARENT);
			dirty = true;
		}
	}
	
	function drawImage(vertices:Vector<Float>, indices:Vector<Int>, uvtData:Vector<Float>):Void
	{
		FlxSpriteUtil.flashGfx.clear();
		FlxSpriteUtil.flashGfx.beginBitmapFill(bitmapData, null, false, true);
		FlxSpriteUtil.flashGfx.drawTriangles(vertices, indices, uvtData);
		FlxSpriteUtil.flashGfx.endFill();
		this.pixels.draw(FlxSpriteUtil.flashGfxSprite);
	}
	
	function updatePoints(elapsed:Float) 
	{
		for (p in points) 
		{
			if (!p.pinned)
			{
				var vx = (p.x - p.oldx) * 0.99;
				var vy = (p.y - p.oldy) * 0.99;
				
				p.oldx = p.x;
				p.oldy = p.y;
				p.x += vx;
				p.y += vy;
				
				p.x += wind.x * elapsed;
				p.y += wind.y * elapsed;
				p.x -= this.velocity.x * elapsed;
				p.y -= this.velocity.y * elapsed;
			}
		}
	}
	
	function updateSticks(elapsed:Float) 
	{
		for (s in sticks) 
		{
			var dx = s.p1.x - s.p0.x;
			var dy = s.p1.y - s.p0.y;
			var distance = Math.sqrt(dx * dx + dy * dy);
			var difference = (s.length - distance) / distance;
			var offsetX = dx * 0.5 * difference;
			var offsetY = dy * 0.5 * difference;
			
			if (!s.p0.pinned)
			{
				s.p0.x -= offsetX;
				s.p0.y -= offsetY;
			}
			if (!s.p1.pinned)
			{
				s.p1.x += offsetX;
				s.p1.y += offsetY;
			}
		}
	}
	
	override public function destroy():Void
	{
		points = null;
		sticks = null;
		_v = null;
		_i = null;
		_u = null;
		
		wind = FlxDestroyUtil.put(wind);
		bitmapData = FlxDestroyUtil.dispose(bitmapData);
		
		super.destroy();
	}
	
	override public function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String):FlxSprite 
	{
		var graph:FlxGraphic = FlxG.bitmap.add(Graphic, Unique, Key);
		this.bitmapData = graph.bitmap;
		if (bitmapData != null)
		{
			pixels = new BitmapData(bitmapData.width, bitmapData.height, true, 0x00000000);
			resetMesh(rows, columns);
		}
		
		return this;
	}
	
	override public function draw():Void 
	{
		if (bitmapData != null)
		{
			calcImage();
			drawImage(_v, _i, _u);
		}
		
		super.draw();
	}
	
	override public function update(elapsed:Float):Void
	{
		updatePoints(elapsed);
		for (i in 0...iterations) 
		{
			updateSticks(elapsed);
		}
		
		super.update(elapsed);
	}
	
	#if !FLX_NO_DEBUG	
	override public function drawDebugOnCamera(camera:FlxCamera):Void 
	{
		if (!camera.visible || !camera.exists || !isOnScreen(camera))
		{
			return;
		}
		
		var rect = getBoundingBox(camera);
		
		// Find the color to use
		var color:Null<Int> = debugBoundingBoxColor;
		if (color == null)
		{
			if (allowCollisions != FlxObject.NONE)
			{
				color = immovable ? FlxColor.GREEN : FlxColor.RED;
			}
			else
			{
				color = FlxColor.BLUE;
			}
		}
		
		//fill static graphics object with square shape
		var gfx:Graphics = beginDrawDebug(camera);
		gfx.lineStyle(1, color, 0.5);
		gfx.drawRect(rect.x, rect.y, rect.width, rect.height);
		
		//draw meshes and rect of pixels bitmapData
		gfx.lineStyle(1, FlxColor.CYAN, 0.5);
		gfx.drawRect(rect.x - offset.x, rect.y - offset.y, rect.width, rect.height);
		for (p in points) 
		{
			gfx.drawCircle(rect.x + p.x, rect.y + p.y, 2);
		}
		for (s in sticks) 
		{
			gfx.moveTo(rect.x + s.p0.x, rect.y + s.p0.y);
			gfx.lineTo(rect.x + s.p1.x, rect.y + s.p1.y);
		}
		endDrawDebug(camera);
	}
	#end
}

typedef Point = {
	x: Float,
	y: Float,
	oldx: Float,
	oldy: Float,
	?pinned:Bool
}

typedef Stick = {
	p0: Point,
	p1: Point,
	length: Float
}