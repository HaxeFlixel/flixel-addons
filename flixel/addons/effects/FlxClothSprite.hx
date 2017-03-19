package flixel.addons.effects;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxFrame.FlxFrameType;
import flixel.graphics.FlxTrianglesData;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.render.common.DrawItem.DrawData;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.geom.Point;

/**
 * A FlxSprite that draw it's frame in a mesh and behave like a cloth.
 * 
 * @author adrianulima
 */
class FlxClothSprite extends FlxSprite
{
	/**
	 * An extra velocity applied to mesh (in pixels per second). Use to simulate gravity or wind.
	 */
	public var meshVelocity(default, null):FlxPoint = FlxPoint.get();
	/**
	 * Determines how quickly the mesh points come to rest.
	 */
	public var meshFriction(default, null):FlxPoint = FlxPoint.get(0.99, 0.99);
	/**
	 * Change the size of the mesh related to the original frame. Need to call setMesh() to update.
	 */
	public var meshScale(default, null):FlxPoint = FlxPoint.get(1, 1);
	/**
	 * Bit field of flags (use with FlxObject.UP, DOWN, LEFT, RIGHT, NONE, ANY, etc) indicating pinned side. Use bitwise operators to check the values stored here.
	 */
	public var pinnedSide:Int;
	/**
	 * How many iterations will do on constraints for each update.
	 * Bigger number make constraint more strong and mesh more rigid.
	 */
	public var iterations:Int = 3;
	/**
	 * Adds two extra constraints crossing the squares to make the mesh more rigid. Need to call setMesh() to update.
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
	/**
	 * An array containing all vertices of the mesh, they are indexed row by row.
	 */
	public var points(default, null):Array<FlxClothPoint> = [];
	/**
	 * An array containing all vertices connections.
	 */
	public var constraints(default, null):Array<FlxClothConstraint> = [];
	
	/**
	 * Mesh arrays. Vertices, indices, uvtData and colors to drawTriangles().
	 */
	private var _data:FlxTrianglesData;
	
	public var colors(get, set):DrawData<Int>;
	
	/**
	 * Use to offset the drawing position of the mesh.
	 */
	private var _drawOffset:FlxPoint;
	/**
	 * The actual Flash BitmapData object representing the current display state of the modified framePixels.
	 */
	public var meshPixels(default, null):BitmapData;
	
	/**
	 * Creates a FlxClothSprite at a specified position with a specified one-frame graphic. 
	 * If none is provided, a 16x16 image of the HaxeFlixel logo is used.
	 * 
	 * @param	X				The initial X position of the sprite.
	 * @param	Y				The initial Y position of the sprite.
	 * @param	SimpleGraphic	The graphic you want to display (OPTIONAL - for simple stuff only, do NOT use for animated images!).
	 * @param	Columns			Number of columns of the created mesh.
	 * @param	Rows			Number of rows of the created mesh.
	 * @param	PinnedSide		The pinned side that points are not affected by wind or velocity. Use FlxObject.UP, DOWN, LEFT, RIGHT, NONE, ANY, etc.
	 */
	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset, Columns:Int = 0, Rows:Int = 0, PinnedSide:Int = FlxObject.UP, CrossingConstraints:Bool = false) 
	{
		super(X, Y, SimpleGraphic);
		
		pinnedSide = PinnedSide;
		rows = Std.int(Math.max(2, Rows));
		columns = Std.int(Math.max(2, Columns));
		crossingConstraints = CrossingConstraints;
		
		_drawOffset = FlxPoint.get();
		_data = new FlxTrianglesData();
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
		
		_drawOffset = FlxDestroyUtil.put(_drawOffset);
		
		_data = FlxDestroyUtil.destroy(_data);
		meshVelocity = FlxDestroyUtil.put(meshVelocity);
		meshFriction = FlxDestroyUtil.put(meshFriction);
		meshPixels = FlxDestroyUtil.dispose(meshPixels);
		
		super.destroy();
	}
	
	/**
	 * Core update loop
	 */
	override public function update(elapsed:Float):Void
	{
		updatePoints(elapsed);
		
		for (i in 0...iterations) 
			updateConstraints(elapsed);
		
		super.update(elapsed);
	}
	
	override function drawSimple(camera:FlxCamera):Void 
	{
		calcImage();
		drawImage();
		
		if (isPixelPerfectRender(camera))
			_point.floor();
		
		_point.addPoint(_drawOffset).copyToFlash(_flashPoint);
		camera.copyPixels(_frame, meshPixels, meshPixels.rect, _flashPoint, colorTransform, blend, smoothing);
	}
	
	override function drawComplex(camera:FlxCamera):Void 
	{
		calcImage();
		drawFrame();
		
		_matrix.identity();
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);
		
		if (bakedRotationAngle <= 0)
		{
			updateTrig();
			
			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}
		
		_matrix.translate(origin.x, origin.y);
		_point.addPoint(_drawOffset);
		_matrix.translate(_point.x, _point.y);
		
		if (isPixelPerfectRender(camera))
			_point.floor();
		
		if (_frameGraphic == null)
			_frameGraphic = FlxGraphic.fromBitmapData(framePixels, false, null, false);
		
		camera.drawTriangles(_frameGraphic, _data, _matrix, colorTransform, blend, true, smoothing);
	}
	
	#if FLX_DEBUG	
	override public function drawDebugOnCamera(camera:FlxCamera):Void 
	{
		if (!camera.visible || !camera.exists || !isOnScreen(camera))
			return;
		
		var rect = getBoundingBox(camera);
		
		// Find the color to use
		var color:Null<Int> = debugBoundingBoxColor;
		if (color == null)
		{
			if (allowCollisions != FlxObject.NONE)
				color = immovable ? FlxColor.GREEN : FlxColor.RED;
			else
				color = FlxColor.BLUE;
		}
		
		//fill static graphics object with square shape
		var gfx:Graphics = beginDrawDebug(camera);
		gfx.lineStyle(1, color, 0.5);
		gfx.drawRect(rect.x, rect.y, rect.width, rect.height);
		
		//draw meshes and rect of pixels meshPixels
		gfx.lineStyle(1, FlxColor.CYAN, 0.5);
		gfx.drawRect(rect.x + _drawOffset.x, rect.y + _drawOffset.y, meshPixels.rect.width, meshPixels.rect.height);
		
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
	public function setMesh(columns:Int = 0, rows:Int = 0, meshPixelsWidth:Int = 0, meshPixelsHeight:Int = 0, ?pinned:Array<Int> = null):Void
	{
		meshPixelsWidth = Std.int(Math.max(meshPixelsWidth, frameWidth));
		meshPixelsHeight = Std.int(Math.max(meshPixelsHeight, frameHeight));
		
		if (meshPixelsWidth <= 0 || meshPixelsHeight <= 0)
		{
			return;
		}
		
		meshPixels = new BitmapData(meshPixelsWidth, meshPixelsHeight, true, FlxColor.TRANSPARENT);
		
		points = [];
		constraints = [];
		
		_data.clear();
		var vertices = _data.vertices;
		var indices = _data.indices;
		var uvtData = _data.uvs;
		
		rows = Std.int(Math.max(2, rows));
		columns = Std.int(Math.max(2, columns));
		widthInTiles = (frameWidth / (columns - 1)) * meshScale.x;
		heightInTiles = (frameHeight / (rows - 1)) * meshScale.y;
		
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
					pinned: ((r == 0 && pinnedSide & FlxObject.UP != 0)
							|| (r == rows - 1 && pinnedSide & FlxObject.DOWN != 0)
							|| (c == 0 && pinnedSide & FlxObject.LEFT != 0)
							|| (c == columns-1 && pinnedSide & FlxObject.RIGHT != 0))
				});
				
				vertices.push(c * widthInTiles);
				vertices.push(r * heightInTiles);
				
				uvtData.push((c) / (columns - 1));
				uvtData.push((r) / (rows - 1));
				
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
					indices.push((r * columns) + c);
					indices.push(((r - 1) * columns) + c - 1);
					indices.push(((r - 1) * columns) + c);
					
					indices.push((r * columns) + c);
					indices.push(((r - 1) * columns) + c - 1);
					indices.push((r * columns) + c - 1);
					
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
				points[i].pinned = true;
		}
	}
	
	/**
	 * Called by update, applies meshVelocity, meshFriction and velocity for each point.
	 */
	private function updatePoints(elapsed:Float) 
	{
		for (p in points) 
		{
			if (!p.pinned)
			{
				var vx = (p.x - p.oldx) * meshFriction.x;
				var vy = (p.y - p.oldy) * meshFriction.y;
				
				p.oldx = p.x;
				p.oldy = p.y;
				p.x += vx;
				p.y += vy;
				
				p.x += meshVelocity.x * elapsed;
				p.y += meshVelocity.y * elapsed;
				p.x -= velocity.x * elapsed;
				p.y -= velocity.y * elapsed;
			}
		}
	}
	
	/**
	 * Called by update, applies velocity for each constraints points.
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
	 * Called by draw, calculate triangles, drawOffset and bitmapData dimensions.
	 */
	private function calcImage():Void
	{
		var vertices = _data.vertices;
		vertices.splice(0, vertices.length);
		_data.verticesDirty = true;
		
		// Get the bounds of the mesh
		var minX:Float = 0;
		var maxX:Float = 0;
		var minY:Float = 0;
		var maxY:Float = 0;
		
		for (p in points) 
		{
			vertices.push(p.x);
			vertices.push(p.y);
			
			minX = Math.min(minX, p.x);
			minY = Math.min(minY, p.y);
			maxX = Math.max(maxX, p.x);
			maxY = Math.max(maxY, p.y);
		}
		
		// Apply an offset to keep image positioned in the origin
		_drawOffset.set(minX, minY);
		
		var i:Int = 0;
		while (i < vertices.length - 1)
		{
			vertices[i] = vertices[i] - minX;
			vertices[i + 1] = vertices[i + 1] - minY;
			i += 2;
		}
		
		if (meshPixels == null)
			return;
		
		// Check if the bitmapData is smaller than the current image and create new one if needed
		var w:Int = Std.int(Math.max(meshPixels.width, maxX - minX));
		var h:Int = Std.int(Math.max(meshPixels.height, maxY - minY));
		
		if (meshPixels.width < w || meshPixels.height < h)
			meshPixels = new BitmapData(w, h, true, FlxColor.TRANSPARENT);
		else
			meshPixels.fillRect(meshPixels.rect, FlxColor.TRANSPARENT);
	}
	
	/**
	 * Called by draw, draw calculated triangles to meshPixels bitmapData.
	 */
	private function drawImage():Void
	{
		if (meshPixels != null)
		{
			FlxSpriteUtil.flashGfx.clear();
			FlxSpriteUtil.flashGfx.beginBitmapFill(framePixels, null, false, true);
			FlxSpriteUtil.flashGfx.drawTriangles(_data.vertices, _data.indices, _data.uvs);
			FlxSpriteUtil.flashGfx.endFill();
			
			meshPixels.draw(FlxSpriteUtil.flashGfxSprite);
		}
	}
	
	private function get_colors():DrawData<FlxColor>
	{
		return _data.colors;
	}
	
	private function set_colors(value:DrawData<FlxColor>):DrawData<FlxColor>
	{
		return _data.colors = value;
	}
}

typedef FlxClothPoint = {
	x: Float,
	y: Float,
	oldx: Float,
	oldy: Float,
	?pinned:Bool
}

typedef FlxClothConstraint = {
	p0: FlxClothPoint,
	p1: FlxClothPoint,
	length: Float
}