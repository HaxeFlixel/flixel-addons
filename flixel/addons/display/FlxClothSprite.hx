package flixel.addons.display;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxFrame.FlxFrameType;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.geom.Point;
import openfl.Vector;

/**
 * ...
 * @author Adriano Lima
 */
class FlxClothSprite extends FlxSprite
{
	public var wind(default, null):FlxPoint = FlxPoint.get();
	
	public var pinSide:Int;
	public var iterations:Int = 3;
	
	public var columns(default, null):Int;
	public var rows(default, null):Int;
	public var widthInTiles(default, null):Float;
	public var heightInTiles(default, null):Float;
	public var points(default, null):Array<ClothPoint> = [];
	public var constraints(default, null):Array<ClothConstraint> = [];
	
	private var _v(default, null):Array<Float>;
	private var _i(default, null):Array<Int>;
	private var _u(default, null):Array<Float>;
	private var _drawOffset:Point;
	private var _meshPixels:BitmapData;
	
	public function new(?X:Float = 0, ?Y:Float = 0, ?Graphic:FlxGraphicAsset, ?Columns:Int = 0, ?Rows:Int = 0, pinSide:Int = FlxObject.UP) 
	{
		super(X, Y, Graphic);
		
		this.pinSide = pinSide;
		this.rows = Std.int(Math.max(2, Rows));
		this.columns = Std.int(Math.max(2, Columns));
		_drawOffset = new Point();
		
		resetMesh(rows, columns);
	}
	
	public function resetMesh(?Rows:Int = 0, ?Columns:Int = 0, ?pinned:Array<Int> = null):Void
	{
		if (frameWidth <= 0 || frameHeight <= 0)
		{
			return;
		}
		
		points = [];
		constraints = [];
		_v = [];
		_u = [];
		_i = [];
		
		this._meshPixels = new BitmapData(frameWidth, frameHeight, true, FlxColor.TRANSPARENT);
		this.rows = Std.int(Math.max(2, Rows));
		this.columns = Std.int(Math.max(2, Columns));
		this.widthInTiles = frameWidth / (columns - 1);
		this.heightInTiles = frameHeight / (rows - 1);
		
		for (r in 0...rows) 
		{
			for (c in 0...columns) 
			{
				points.push({
					x: c * widthInTiles,
					y: r * heightInTiles,
					oldx: c * widthInTiles,
					oldy: r * heightInTiles,
					pinned: ((r == 0 && pinSide & FlxObject.UP != 0)
							|| (r == rows - 1 && pinSide & FlxObject.DOWN != 0)
							|| (c == 0 && pinSide & FlxObject.LEFT != 0)
							|| (c == columns-1 && pinSide & FlxObject.RIGHT != 0))
				});
				
				_v.push(c * widthInTiles);
				_v.push(r * heightInTiles);
				
				_u.push((c) / (columns - 1));
				_u.push((r) / (rows - 1));
				
				if (c > 0)
				{
					constraints.push({
						p0: points[(r * columns) + c],
						p1: points[(r * columns) + c - 1],
						length: widthInTiles
					});
				}
				if (r > 0)
				{
					constraints.push({
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
		
		if (pinned != null)
		{
			for (i in pinned) 
			{
				points[i].pinned = true;
			}
		}
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
	
	function updateConstraints(elapsed:Float) 
	{
		for (s in constraints) 
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
		
		_drawOffset.x = minX;
		_drawOffset.y = minY;
		
		var i:Int = 0;
		while (i < _v.length - 1)
		{
			_v[i] = _v[i] - minX;
			_v[i + 1] = _v[i + 1] - minY;
			i+=2;
		}
		
		var w:Int = Std.int(Math.max(_meshPixels.width, maxX - minX));
		var h:Int = Std.int(Math.max(_meshPixels.height, maxY - minY));
		if (_meshPixels.width < w || _meshPixels.height < h)
		{
			//trace("new BitmapData");
			_meshPixels = new BitmapData(w, h, true, FlxColor.TRANSPARENT);
		}
		else
		{
			_meshPixels.fillRect(_meshPixels.rect, FlxColor.TRANSPARENT);
		}
	}
	
	function drawImage(vertices:Vector<Float>, indices:Vector<Int>, uvtData:Vector<Float>):Void
	{
		FlxSpriteUtil.flashGfx.clear();
		FlxSpriteUtil.flashGfx.beginBitmapFill(framePixels, null, false, true);
		FlxSpriteUtil.flashGfx.drawTriangles(vertices, indices, uvtData);
		FlxSpriteUtil.flashGfx.endFill();
		
		this._meshPixels.draw(FlxSpriteUtil.flashGfxSprite);
	}
	
	override public function destroy():Void
	{
		points = null;
		constraints = null;
		_v = null;
		_i = null;
		_u = null;
		_drawOffset = null;
		
		wind = FlxDestroyUtil.put(wind);
		_meshPixels = FlxDestroyUtil.dispose(_meshPixels);
		
		super.destroy();
	}
	
	override public function draw():Void 
	{
		
		if (_meshPixels != null)
		{
			calcImage();
			drawImage(_v, _i, _u);
		}
		
		if (_frame == null)
		{
			return;
		}
		
		if (alpha == 0 || _frame.type == FlxFrameType.EMPTY)
		{
			return;
		}
		
		if (dirty)	//rarely 
		{
			calcFrame();
		}
		
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
			{
				continue;
			}
			
			getScreenPosition(_point, camera).subtractPoint(offset);
			
			var cr:Float = colorTransform.redMultiplier;
			var cg:Float = colorTransform.greenMultiplier;
			var cb:Float = colorTransform.blueMultiplier;
			
			var simple:Bool = isSimpleRender(camera);
			if (simple)
			{
				if (isPixelPerfectRender(camera))
				{
					_point.floor();
				}
				
				_point.copyToFlash(_flashPoint);
				camera.copyPixels(_frame, _meshPixels, _meshPixels.rect, new Point(_flashPoint.x + _drawOffset.x,_flashPoint.y + _drawOffset.y), cr, cg, cb, alpha, blend, antialiasing);
			}
			else
			{
				//TODO: ask about this case
				_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, flipX, flipY);
				_matrix.translate( -origin.x, -origin.y);
				_matrix.scale(scale.x, scale.y);
				
				if (bakedRotationAngle <= 0)
				{
					updateTrig();
					
					if (angle != 0)
					{
						_matrix.rotateWithTrig(_cosAngle, _sinAngle);
					}
				}
				
				_point.add(origin.x, origin.y);
				if (isPixelPerfectRender(camera))
				{
					_point.floor();
				}
				
				_matrix.translate(_point.x, _point.y);
				camera.drawPixels(_frame, _meshPixels, _matrix, cr, cg, cb, alpha, blend, antialiasing);
			}
			
			#if !FLX_NO_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
		
		#if !FLX_NO_DEBUG
		if (FlxG.debugger.drawDebug)
		{
			drawDebug();
		}
		#end
	}
	
	override public function update(elapsed:Float):Void
	{
		updatePoints(elapsed);
		for (i in 0...iterations) 
		{
			updateConstraints(elapsed);
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
		
		//draw meshes and rect of pixels _meshPixels
		gfx.lineStyle(1, FlxColor.CYAN, 0.5);
		gfx.drawRect(rect.x + _drawOffset.x, rect.y + _drawOffset.y, _meshPixels.rect.width, _meshPixels.rect.height);
		for (p in points) 
		{
			gfx.drawCircle(rect.x + p.x, rect.y + p.y, 2);
		}
		for (s in constraints) 
		{
			gfx.moveTo(rect.x + s.p0.x, rect.y + s.p0.y);
			gfx.lineTo(rect.x + s.p1.x, rect.y + s.p1.y);
		}
		endDrawDebug(camera);
	}
	#end
}

typedef ClothPoint = {
	x: Float,
	y: Float,
	oldx: Float,
	oldy: Float,
	?pinned:Bool
}

typedef ClothConstraint = {
	p0: ClothPoint,
	p1: ClothPoint,
	length: Float
}