package flixel.addons.display;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxFrame.FlxFrameType;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.geom.Point;
import openfl.Vector;

@:keep @:bitmap("assets/images/logo/default.png")
private class GraphicDefault extends BitmapData {}

/**
 * A FlxSprite that draw it's frame in a mesh and behave like a cloth.
 * 
 * @author adrianulima
 */
class FlxClothSprite extends FlxSprite
{
	/**
	 * An extra speed applied to mesh (in pixels per second). Use to simulate gravity or wind.
	 */
	public var gravity(default, null):FlxPoint = FlxPoint.get();
	/**
	 * Determines how quickly the mesh points come to rest.
	 */
	public var friction(default, null):FlxPoint = FlxPoint.get(0.99, 0.99);
	/**
	 * Change the size of the mesh related to the original frame. Need to call setMesh() to update.
	 */
	public var meshScale(default, null):FlxPoint = FlxPoint.get(1, 1);
	/**
	 * Bit field of flags (use with FlxObject.UP, DOWN, LEFT, RIGHT, NONE, ANY, etc) indicating pinned side. Use bitwise operators to check the values stored here.
	 */
	public var pinSide:Int;
	/**
	 * How many iterations will do on constraints for each update. Need to call setMesh() to update.
	 * Bigger number make constraint more strong and mesh more rigid.
	 */
	public var iterations:Int = 3;
	/**
	 * Adds an extra constraint crossing the squares to make the mesh more rigid. Need to call setMesh() to update.
	 */
	public var crossingConstraints:Bool = false;
	/**
	 * Number of columns of the mesh. To set it you must use setMesh().
	 */
	public var columns(default, null):Int;
	/**
	 * Number of rows of the mesh. To set it you must use setMesh().
	 */
	public var rows(default, null):Int;
	/**
	 * The width of mesh squares. To set it you must use setMesh().
	 */
	public var widthInTiles(default, null):Float;
	/**
	 * The height of mesh squares. To set it you must use setMesh().
	 */
	public var heightInTiles(default, null):Float;
	
	public var points(default, null):Array<ClothPoint> = [];
	public var constraints(default, null):Array<ClothConstraint> = [];
	
	/**
	 * Mesh arrays. Vertices, indices and uvtData to drawTriangles().
	 */
	#if flash
	private var _vertices(default, null):Vector<Float>;
	private var _indices(default, null):Vector<Int>;
	private var _uvtData(default, null):Vector<Float>;
	#else
	private var _vertices(default, null):Array<Float>;
	private var _indices(default, null):Array<Int>;
	private var _uvtData(default, null):Array<Float>;
	#end
	
	/**
	 * Use to offset the drawing position of the mesh.
	 */
	private var _drawOffset:Point;
	/**
	 * The actual Flash BitmapData object representing the current display state of the modified framePixels.
	 */
	private var _meshPixels:BitmapData;
	
	/**
	 * Creates a FlxClothSprite at a specified position with a specified one-frame graphic. 
	 * If none is provided, a 16x16 image of the HaxeFlixel logo is used.
	 * 
	 * @param	X				The initial X position of the sprite.
	 * @param	Y				The initial Y position of the sprite.
	 * @param	SimpleGraphic	The graphic you want to display (OPTIONAL - for simple stuff only, do NOT use for animated images!).
	 * @param	Columns			Number of columns of the created mesh.
	 * @param	Rows			Number of rows of the created mesh.
	 * @param	pinSide			The pinned side that points are not affected by wind or velocity. Use FlxObject.UP, DOWN, LEFT, RIGHT, NONE, ANY, etc.
	 */
	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset, ?Columns:Int = 0, ?Rows:Int = 0, pinSide:Int = FlxObject.UP, crossingConstraints:Bool = false) 
	{
		super(X, Y, SimpleGraphic);
		
		this.pinSide = pinSide;
		this.rows = Std.int(Math.max(2, Rows));
		this.columns = Std.int(Math.max(2, Columns));
		this.crossingConstraints = crossingConstraints;
		
		_drawOffset = new Point();
		setMesh(columns, rows);
	}
	
	/**
	 * WARNING: This will remove this sprite entirely. Use kill() if you want to disable it temporarily only and reset() it later to revive it.
	 * Used to clean up memory.
	 */
	override public function destroy():Void
	{
		points = null;
		constraints = null;
		_vertices = null;
		_indices = null;
		_uvtData = null;
		_drawOffset = null;
		
		gravity = FlxDestroyUtil.put(gravity);
		friction = FlxDestroyUtil.put(friction);
		_meshPixels = FlxDestroyUtil.dispose(_meshPixels);
		
		super.destroy();
	}
	
	/**
	 * Core update loop
	 */
	override public function update(elapsed:Float):Void
	{
		updatePoints(elapsed);
		for (i in 0...iterations) 
		{
			updateConstraints(elapsed);
		}
		
		super.update(elapsed);
	}
	
	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen
	 */
	override public function draw():Void 
	{
		if (_frame == null || _meshPixels == null)
		{
			#if !FLX_NO_DEBUG
			loadGraphic(FlxGraphic.fromClass(GraphicDefault));
			#else
			return;
			#end
		}
		
		calcImage();
		drawImage();
		
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
				
				// Create a temporary frame and draw mesh's bitmapData
				var frameMesh:FlxFrame = new FlxFrame(FlxGraphic.fromBitmapData(_meshPixels, true, null, false));
				frameMesh.frame = new FlxRect(0, 0, _meshPixels.width, _meshPixels.height);
				
				_matrix.translate(_point.x + _drawOffset.x, _point.y + _drawOffset.y);
				camera.drawPixels(frameMesh, framePixels, _matrix, cr, cg, cb, alpha, blend, antialiasing);
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
	
	/**
	 * Sets mesh points and constraints.
	 * 
	 * @param	columns				Number of columns of the created mesh.
	 * @param	rows				Number of rows of the created mesh.
	 * @param   meshPixelsWidth		Optional, specify the width of the bitmapData where the mesh will be drawn.
	 * 								It uses frameWidth by default, but when mesh state is bigger, a new BitmapData is created.
	 * @param   meshPixelsHeight	Optional, specify the height of the bitmapData where the mesh will be drawn.
	 * 								It uses frameHeight by default, but when mesh state is bigger, a new BitmapData is created.
	 * @param   pinned				Indices of pinned points that are not affected by wind or velocity.
	 */
	public function setMesh(?columns:Int = 0, ?rows:Int = 0, ?meshPixelsWidth:Int = 0, ?meshPixelsHeight:Int = 0, ?pinned:Array<Int> = null):Void
	{
		meshPixelsWidth = Std.int(Math.max(meshPixelsWidth, frameWidth));
		meshPixelsHeight = Std.int(Math.max(meshPixelsHeight, frameHeight));
		
		if (meshPixelsWidth <= 0 || meshPixelsHeight <= 0)
		{
			return;
		}
		
		this._meshPixels = new BitmapData(meshPixelsWidth, meshPixelsHeight, true, FlxColor.TRANSPARENT);
		
		points = [];
		constraints = [];
		_vertices = [];
		_uvtData = [];
		_indices = [];
		
		this.rows = Std.int(Math.max(2, rows));
		this.columns = Std.int(Math.max(2, columns));
		this.widthInTiles = (frameWidth / (columns - 1)) * meshScale.x;
		this.heightInTiles = (frameHeight / (rows - 1)) * meshScale.y;
		
		var hyp = Math.sqrt(heightInTiles * heightInTiles + widthInTiles * widthInTiles);
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
				
				_vertices.push(c * widthInTiles);
				_vertices.push(r * heightInTiles);
				
				_uvtData.push((c) / (columns - 1));
				_uvtData.push((r) / (rows - 1));
				
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
					_indices.push((r * columns) + c);
					_indices.push(((r - 1) * columns) + c - 1);
					_indices.push(((r - 1) * columns) + c);
					
					_indices.push((r * columns) + c);
					_indices.push(((r - 1) * columns) + c - 1);
					_indices.push((r * columns) + c - 1);
					
					if (crossingConstraints)
					{
						constraints.push({
							p0: points[(r * columns) + c - 1],
							p1: points[((r - 1) * columns) + c],
							length: hyp
						});
						constraints.push({
							p0: points[(r * columns) + c],
							p1: points[((r - 1) * columns) + c - 1],
							length: hyp
						});
					}
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
	
	/**
	 * Called by update, applies gravity, friction and velocity for each point
	 */
	private function updatePoints(elapsed:Float) 
	{
		for (p in points) 
		{
			if (!p.pinned)
			{
				var vx = (p.x - p.oldx) * friction.x;
				var vy = (p.y - p.oldy) * friction.y;
				
				p.oldx = p.x;
				p.oldy = p.y;
				p.x += vx;
				p.y += vy;
				
				p.x += gravity.x * elapsed;
				p.y += gravity.y * elapsed;
				p.x -= this.velocity.x * elapsed;
				p.y -= this.velocity.y * elapsed;
			}
		}
	}
	
	/**
	 * Called by update, applies velocity for each constraints points
	 */
	private function updateConstraints(elapsed:Float) 
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
	
	/**
	 * Called by draw, calculate triangles, drawOffset and bitmapData dimensions
	 */
	private function calcImage():Void
	{
		_vertices = [];
		
		// Get the bounds of the mesh
		var minX:Float = 0;
		var maxX:Float = 0;
		var minY:Float = 0;
		var maxY:Float = 0;
		
		for (p in points) 
		{
			_vertices.push(p.x);
			_vertices.push(p.y);
			
			minX = Math.min(minX, p.x);
			minY = Math.min(minY, p.y);
			maxX = Math.max(maxX, p.x);
			maxY = Math.max(maxY, p.y);
		}
		
		// Apply an offset to keep image positioned in the origin
		_drawOffset.x = minX;
		_drawOffset.y = minY;
		
		var i:Int = 0;
		while (i < _vertices.length - 1)
		{
			_vertices[i] = _vertices[i] - minX;
			_vertices[i + 1] = _vertices[i + 1] - minY;
			i+=2;
		}
		
		// Check if the bitmapData is smaller than the current image and create new one if needed
		var w:Int = Std.int(Math.max(_meshPixels.width, maxX - minX));
		var h:Int = Std.int(Math.max(_meshPixels.height, maxY - minY));
		if (_meshPixels.width < w || _meshPixels.height < h)
		{
			_meshPixels = new BitmapData(w, h, true, FlxColor.TRANSPARENT);
		}
		else
		{
			_meshPixels.fillRect(_meshPixels.rect, FlxColor.TRANSPARENT);
		}
	}
	
	/**
	 * Called by draw, draw calculated triangles to _meshPixels bitmapData
	 */
	private function drawImage():Void
	{
		#if !FLX_RENDER_BLIT
		getFlxFrameBitmapData();
		#end
		FlxSpriteUtil.flashGfx.clear();
		FlxSpriteUtil.flashGfx.beginBitmapFill(framePixels, null, false, true);
		FlxSpriteUtil.flashGfx.drawTriangles(_vertices, _indices, _uvtData);
		FlxSpriteUtil.flashGfx.endFill();
		
		this._meshPixels.draw(FlxSpriteUtil.flashGfxSprite);
	}
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