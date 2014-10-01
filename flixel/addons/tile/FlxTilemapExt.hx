package flixel.addons.tile;

import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.addons.tile.FlxTilemapExt;
import flixel.addons.tile.FlxTileSpecial;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FrameType;
import flixel.system.layer.DrawStackItem;
import flixel.tile.FlxTile;
import flixel.tile.FlxTilemap;
import flixel.tile.FlxTilemapBuffer;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFramesCollection;

// TODO: add support for tilemap scaling
// TODO: try to make it cleaner (i mean rendering and animated tiles)

/**
 * Extended FlxTilemap class that provides collision detection against slopes
 * Based on the original by Dirk Bunk.
 * ---
 * Also add support to flipped / rotated tiles.
 * @author Peter Christiansen
 * @author MrCdK
 * @link https://github.com/TheTurnipMaster/SlopeDemo
 */
class FlxTilemapExt extends FlxTilemap
{
	public static inline var SLOPE_FLOOR_LEFT:Int = 0;
	public static inline var SLOPE_FLOOR_RIGHT:Int = 1;
	public static inline var SLOPE_CEIL_LEFT:Int = 2;
	public static inline var SLOPE_CEIL_RIGHT:Int = 3;
	
	// Slope related variables
	private var _snapping:Int = 2;
	private var _slopePoint:FlxPoint;
	private var _objPoint:FlxPoint;
	
	private var _slopeFloorLeft:Array<Int>;
	private var _slopeFloorRight:Array<Int>;
	private var _slopeCeilLeft:Array<Int>;
	private var _slopeCeilRight:Array<Int>;
	
	// Animated and flipped tiles related variables
	private var _specialTiles:Array<FlxTileSpecial>;
	
	public function new()
	{
		super();
		
		_slopePoint = FlxPoint.get();
		_objPoint = FlxPoint.get();
		
		_slopeFloorLeft = new Array<Int>();
		_slopeFloorRight = new Array<Int>();
		_slopeCeilLeft = new Array<Int>();
		_slopeCeilRight = new Array<Int>();
		
		// Flipped/rotated tiles variables
		_specialTiles = null;
	}
	
	override public function destroy():Void 
	{
		_slopePoint = FlxDestroyUtil.put(_slopePoint);
		_objPoint = FlxDestroyUtil.put(_objPoint);
		
		_slopeFloorLeft = null;
		_slopeFloorRight = null;
		_slopeCeilLeft = null;
		_slopeCeilRight = null;
		
		super.destroy();
		
		_specialTiles = FlxDestroyUtil.destroyArray(_specialTiles);
		MATRIX = null;
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		if (_specialTiles != null && _specialTiles.length > 0) 
		{
			for (t in _specialTiles) 
			{
				if (t != null && t.hasAnimation()) 
				{
					t.update(elapsed);
				}
			}
		}
	}
	
	/**
	 * THIS IS A COPY FROM FlxTilemap BUT IT DEALS WITH FLIPPED AND ROTATED TILES
	 * Internal function that actually renders the tilemap to the tilemap buffer.  Called by draw().
	 * @param	Buffer		The FlxTilemapBuffer you are rendering to.
	 * @param	Camera		The related FlxCamera, mainly for scroll values.
	 */
	override private function drawTilemap(Buffer:FlxTilemapBuffer, Camera:FlxCamera):Void 
	{
		#if FLX_RENDER_BLIT
		Buffer.fill();
		#else
		getScreenPosition(_point, Camera).copyToFlash(_helperPoint);
		
		_helperPoint.x *= Camera.totalScaleX;
		_helperPoint.y *= Camera.totalScaleY;
		
		_helperPoint.x = isPixelPerfectRender(Camera) ? Math.floor(_helperPoint.x) : _helperPoint.x;
		_helperPoint.y = isPixelPerfectRender(Camera) ? Math.floor(_helperPoint.y) : _helperPoint.y;
		
		var scaledWidth:Float = _tileWidth * Camera.totalScaleX;
		var scaledHeight:Float = _tileHeight * Camera.totalScaleY;
		
		var tileID:Int = -1;
		var drawX:Float;
		var drawY:Float;
		
		var _tileTransformMatrix:Matrix = null;
		var drawItem:DrawStackItem;
		#end
		
		var isColored:Bool = ((alpha != 1) || (color != 0xffffff));
		
		// Copy tile images into the tile buffer
		_point.x = (Camera.scroll.x * scrollFactor.x) - x; //modified from getScreenXY()
		_point.y = (Camera.scroll.y * scrollFactor.y) - y;
		var screenXInTiles:Int = Math.floor(_point.x / _tileWidth);
		var screenYInTiles:Int = Math.floor(_point.y / _tileHeight);
		var screenRows:Int = Buffer.rows;
		var screenColumns:Int = Buffer.columns;
		
		// Bound the upper left corner
		if (screenXInTiles < 0)
		{
			screenXInTiles = 0;
		}
		if (screenXInTiles > widthInTiles - screenColumns)
		{
			screenXInTiles = widthInTiles - screenColumns;
		}
		if (screenYInTiles < 0)
		{
			screenYInTiles = 0;
		}
		if (screenYInTiles > heightInTiles - screenRows)
		{
			screenYInTiles = heightInTiles - screenRows;
		}
		
		var rowIndex:Int = screenYInTiles * widthInTiles + screenXInTiles;
		_flashPoint.y = 0;
		var columnIndex:Int;
		var tile:FlxTile;
		var frame:FlxFrame;
		var special:FlxTileSpecial;

		#if !FLX_NO_DEBUG
		var debugTile:BitmapData;
		#end 
		
		var isSpecial = false;
		
		for (row in 0...screenRows)
		{
			columnIndex = rowIndex;
			_flashPoint.x = 0;
			
			for (column in 0...screenColumns)
			{
				isSpecial = false;
				special = null;
				tile = _tileObjects[_data[columnIndex]];
				
				if (_specialTiles != null && _specialTiles[columnIndex] != null) 
				{
					special = _specialTiles[columnIndex];
					isSpecial = special.isSpecial();
				}
				
				#if FLX_RENDER_BLIT
				if (isSpecial) 
				{
					Buffer.pixels.copyPixels(special.getBitmapData(), _flashRect, _flashPoint, null, null, true);
					Buffer.dirty = (special.dirty || Buffer.dirty);
				}
				else if (tile != null && tile.visible && tile.frame.type != FrameType.EMPTY)
				{
					Buffer.pixels.copyPixels(tile.frame.getBitmap(), _flashRect, _flashPoint, null, null, true);
				}
				
			#if !FLX_NO_DEBUG
				if (FlxG.debugger.drawDebug && !ignoreDrawDebug) 
				{
					if (tile != null)
					{
						if (tile.allowCollisions <= FlxObject.NONE)
						{
							debugTile = _debugTileNotSolid; 
						}
						else if (tile.allowCollisions != FlxObject.ANY)
						{
							debugTile = _debugTilePartial; 
						}
						else
						{
							debugTile = _debugTileSolid; 
						}
						
						Buffer.pixels.copyPixels(debugTile, _debugRect, _flashPoint, null, null, true);
					}
				}
			#end
				#else
				frame = (isSpecial) ? special.currFrame : tile.frame;
				
				if (frame != null)
				{
					_matrix.identity();
					
					drawX = _helperPoint.x + (columnIndex % widthInTiles) * scaledWidth;
					drawY = _helperPoint.y + Math.floor(columnIndex / widthInTiles) * scaledHeight;
					
					if (isSpecial)
					{
						_tileTransformMatrix = special.getMatrix();
						_matrix.concat(_tileTransformMatrix);
						
						drawX += _matrix.tx * Camera.totalScaleX;
						drawY += _matrix.ty * Camera.totalScaleY;
					}
					else
					{
						if (frame.angle != 0)
						{
							frame.prepareFrameMatrix(_matrix);
						}
						
						drawX += frame.center.x * Camera.totalScaleX;
						drawY += frame.center.y * Camera.totalScaleY;
					}
					
					_matrix.scale(Camera.totalScaleX, Camera.totalScaleY);
					
					_point.set(drawX, drawY);
					
					drawItem = Camera.getDrawStackItem(graphic, isColored, _blendInt);
					drawItem.setMatrixDrawData(_point, frame.tileID, _matrix, isColored, color, alpha);
				}
				#end
				
				#if FLX_RENDER_BLIT
				_flashPoint.x += _tileWidth;
				#end
				columnIndex++;
			}
			
			rowIndex += widthInTiles;
			#if FLX_RENDER_BLIT
			_flashPoint.y += _tileHeight;
			#end
		}
		
		Buffer.x = screenXInTiles * _tileWidth;
		Buffer.y = screenYInTiles * _tileHeight;
		
		#if FLX_RENDER_BLIT
		if (isColored)
		{
			Buffer.colorTransform(colorTransform);
		}
		Buffer.blend = blend;
		#end
	}
	
	/**
	 * Set the special tiles (rotated or flipped)
	 * @param	tiles	An Array with all the FlxTileSpecial
	 */
	public function setSpecialTiles(tiles:Array<FlxTileSpecial>):Void 
	{
		_specialTiles = new Array<FlxTileSpecial>();

		#if FLX_RENDER_BLIT
		var animIds:Array<Int>;
		#end
		var t:FlxTileSpecial;
		for (i in 0...tiles.length) 
		{
			t = tiles[i];
			if (t != null && t.isSpecial())
			{
				_specialTiles[i] = t;
				
				t.currTileId -= _startingIndex;
				t.frames = this.frames;
				
				if (t.hasAnimation()) 
				{
					var animFrames:Array<Int> = t.animation.frames;
					var preparedFrames:Array<Int> = [];
					
					for (j in 0...animFrames.length)
					{
						preparedFrames[j] = animFrames[j] - _startingIndex;
					}
					
					t.animation.frames = preparedFrames;
				}
			} 
			else 
			{
				_specialTiles[i] = null;
			}
		}
	}
	
	/**
	 * THIS IS A COPY FROM FlxTilemap
	 * I've only swapped lines 386 and 387 to give DrawTilemap() a chance to set the buffer dirty
	 * ---
	 * Draws the tilemap buffers to the cameras.
	 */
	override public function draw():Void
	{
		var cameras = cameras;
		var camera:FlxCamera;
		var buffer:FlxTilemapBuffer;
		var i:Int = 0;
		var l:Int = cameras.length;
		
		while (i < l)
		{
			camera = cameras[i];
			if (!camera.visible || !camera.exists)
			{
				continue;
			}
			
			if (_buffers[i] == null)
			{
				_buffers[i] = new FlxTilemapBuffer(_tileWidth, _tileHeight, widthInTiles, heightInTiles, camera);
				_buffers[i].pixelPerfectRender = pixelPerfectRender;
			}
			
			buffer = _buffers[i++];
			
			#if FLX_RENDER_BLIT
			if (!buffer.dirty)
			{
				// Copied from getScreenXY()
				_point.x = x - (camera.scroll.x * scrollFactor.x) + buffer.x; 
				_point.y = y - (camera.scroll.y * scrollFactor.y) + buffer.y;
				buffer.dirty = (_point.x > 0) || (_point.y > 0) || (_point.x + buffer.width < camera.width) || (_point.y + buffer.height < camera.height);
			}
			
			if (buffer.dirty)
			{
				buffer.dirty = false;
				drawTilemap(buffer, camera);
			}
			
			// Copied from getScreenXY()
			_flashPoint.x = x - (camera.scroll.x * scrollFactor.x) + buffer.x; 
			_flashPoint.y = y - (camera.scroll.y * scrollFactor.y) + buffer.y;
			buffer.draw(camera, _flashPoint);
			
			#else
			drawTilemap(buffer, camera);
			#end
			
			#if !FLX_NO_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
	}

	/**
	 * THIS IS A COPY FROM FlxTilemap BUT IT SOLVES SLOPE COLLISION TOO
	 * Checks if the Object overlaps any tiles with any collision flags set,
	 * and calls the specified callback function (if there is one).
	 * Also calls the tile's registered callback if the filter matches.
	 *
	 * @param 	Object 				The FlxObject you are checking for overlaps against.
	 * @param 	Callback 			An optional function that takes the form "myCallback(Object1:FlxObject,Object2:FlxObject)", where Object1 is a FlxTile object, and Object2 is the object passed in in the first parameter of this method.
	 * @param 	FlipCallbackParams 	Used to preserve A-B list ordering from FlxObject.separate() - returns the FlxTile object as the second parameter instead.
	 * @param 	Position 			Optional, specify a custom position for the tilemap (useful for overlapsAt()-type funcitonality).
	 *
	 * @return Whether there were overlaps, or if a callback was specified, whatever the return value of the callback was.
	 */
	override public function overlapsWithCallback(Object:FlxObject, ?Callback:FlxObject->FlxObject->Bool, FlipCallbackParams:Bool = false, ?Position:FlxPoint):Bool
	{
		var results:Bool = false;
		
		var X:Float = x;
		var Y:Float = y;
		
		if (Position != null)
		{
			X = Position.x;
			Y = Position.y;
		}
		
		//Figure out what tiles we need to check against
		var selectionX:Int = Math.floor((Object.x - X) / _tileWidth);
		var selectionY:Int = Math.floor((Object.y - Y) / _tileHeight);
		var selectionWidth:Int = selectionX + (Math.ceil(Object.width / _tileWidth)) + 1;
		var selectionHeight:Int = selectionY + Math.ceil(Object.height / _tileHeight) + 1;
		
		//Then bound these coordinates by the map edges
		if (selectionX < 0)
		{
			selectionX = 0;
		}
		if (selectionY < 0)
		{
			selectionY = 0;
		}
		if (selectionWidth > widthInTiles)
		{
			selectionWidth = widthInTiles;
		}
		if (selectionHeight > heightInTiles)
		{
			selectionHeight = heightInTiles;
		}
		
		// Then loop through this selection of tiles and call FlxObject.separate() accordingly
		var rowStart:Int = selectionY * widthInTiles;
		var row:Int = selectionY;
		var column:Int;
		var tile:FlxTile;
		var overlapFound:Bool;
		var deltaX:Float = X - last.x;
		var deltaY:Float = Y - last.y;
		
		while (row < selectionHeight)
		{
			column = selectionX;
			
			while (column < selectionWidth)
			{
				overlapFound = false;
				tile = _tileObjects[_data[rowStart + column]];
				
				if (tile.allowCollisions != 0)
				{
					tile.x = X + column * _tileWidth;
					tile.y = Y + row * _tileHeight;
					tile.last.x = tile.x - deltaX;
					tile.last.y = tile.y - deltaY;
					
					if (Callback != null)
					{
						if (FlipCallbackParams)
						{
							overlapFound = Callback(Object, tile);
						}
						else
						{
							overlapFound = Callback(tile, Object);
						}
					}
					else
					{
						overlapFound = (Object.x + Object.width > tile.x) && (Object.x < tile.x + tile.width) && (Object.y + Object.height > tile.y) && (Object.y < tile.y + tile.height);
					}
					
					// Solve slope collisions if no overlap was found
					/*
					if (overlapFound
						|| (!overlapFound && (tile.index == SLOPE_FLOOR_LEFT || tile.index == SLOPE_FLOOR_RIGHT || tile.index == SLOPE_CEIL_LEFT || tile.index == SLOPE_CEIL_RIGHT)))
					*/
					
					// New generalized slope collisions
					if (overlapFound || (!overlapFound && checkArrays(tile.index)))
					{
						if ((tile.callbackFunction != null) && ((tile.filter == null) || Std.is(Object, tile.filter)))
						{
							tile.mapIndex = rowStart + column;
							tile.callbackFunction(tile, Object);
						}
						results = true;
					}
				}
				else if ((tile.callbackFunction != null) && ((tile.filter == null) || Std.is(Object, tile.filter)))
				{
					tile.mapIndex = rowStart + column;
					tile.callbackFunction(tile, Object);
				}
				column++;
			}
			
			rowStart += widthInTiles;
			row++;
		}
		
		return results;
	}
	
	/**
	 * Sets the tiles that are treated as "clouds" or blocks that are only solid from the top.
	 * 
	 * @param 	Clouds	An array containing the numbers of the tiles to be treated as clouds.
	 */
	public function setClouds(?Clouds:Array<Int>):Void
	{
		if (Clouds != null)
		{
			for (i in 0...(Clouds.length))
			{
				setTileProperties(Clouds[i], FlxObject.CEILING);			
			}
		}
	}
	
	/**
	 * Sets the slope arrays, which define which tiles are treated as slopes.
	 * 
	 * @param 	LeftFloorSlopes 	An array containing the numbers of the tiles to be treated as floor tiles with a slope on the left.
	 * @param 	RightFloorSlopes	An array containing the numbers of the tiles to be treated as floor tiles with a slope on the right.
	 * @param 	LeftCeilSlopes		An array containing the numbers of the tiles to be treated as ceiling tiles with a slope on the left.
	 * @param 	RightCeilSlopes		An array containing the numbers of the tiles to be treated as ceiling tiles with a slope on the right.
	 */
	public function setSlopes(?LeftFloorSlopes:Array<Int>, ?RightFloorSlopes:Array<Int>, ?LeftCeilSlopes:Array<Int>, ?RightCeilSlopes:Array<Int>):Void
	{
		if (LeftFloorSlopes != null)
		{
			_slopeFloorLeft = LeftFloorSlopes;
		}
		if (RightFloorSlopes != null)
		{
			_slopeFloorRight = RightFloorSlopes;
		}
		if (LeftCeilSlopes != null)
		{
			_slopeCeilLeft = LeftCeilSlopes;
		}
		if (RightCeilSlopes != null)
		{
			_slopeCeilRight = RightCeilSlopes;
		}
		
		setSlopeProperties();
	}
	
	/**
	 * Bounds the slope point to the slope
	 * 
	 * @param 	Slope 	The slope to fix the slopePoint for
	 */
	private function fixSlopePoint(Slope:FlxTile):Void
	{
		_slopePoint.x = FlxMath.bound(_slopePoint.x, Slope.x, Slope.x + _tileWidth);
		_slopePoint.y = FlxMath.bound(_slopePoint.y, Slope.y, Slope.y + _tileHeight);
	}
	
	/**
	 * Ss called if an object collides with a floor slope
	 * 
	 * @param 	Slope	The floor slope
	 * @param	Object 	The object that collides with that slope
	 */
	private function onCollideFloorSlope(Slope:FlxObject, Object:FlxObject):Void
	{
		// Set the object's touching flag
		Object.touching = FlxObject.FLOOR;
		
		// Adjust the object's velocity
		Object.velocity.y = 0;
		
		// Reposition the object
		Object.y = _slopePoint.y - Object.height;
		
		if (Object.y < Slope.y - Object.height) 
		{ 
			Object.y = Slope.y - Object.height; 
		}
	}
	
	/**
	 * Is called if an object collides with a ceiling slope
	 * 
	 * @param 	Slope 	The ceiling slope
	 * @param 	Object 	The object that collides with that slope
	 */
	private function onCollideCeilSlope(Slope:FlxObject, Object:FlxObject):Void
	{
		// Set the object's touching flag
		Object.touching = FlxObject.CEILING;
		
		// Adjust the object's velocity
		Object.velocity.y = 0;
		
		// Reposition the object
		Object.y = _slopePoint.y;
		
		if (Object.y > Slope.y + _tileHeight) 
		{ 
			Object.y = Slope.y + _tileHeight; 
		}
	}
	
	/**
	 * Solves collision against a left-sided floor slope
	 * 
	 * @param 	Slope 	The slope to check against
	 * @param 	Object 	The object that collides with the slope
	 */
	private function solveCollisionSlopeFloorLeft(Slope:FlxObject, Object:FlxObject):Void
	{
		// Calculate the corner point of the object
		_objPoint.x = Math.floor(Object.x + Object.width + _snapping);
		_objPoint.y = Math.floor(Object.y + Object.height);
		
		// Calculate position of the point on the slope that the object might overlap
		// this would be one side of the object projected onto the slope's surface
		_slopePoint.x = _objPoint.x;
		_slopePoint.y = (Slope.y + _tileHeight) - (_slopePoint.x - Slope.x);
		
		// Fix the slope point to the slope tile
		fixSlopePoint(cast(Slope, FlxTile));
		
		// Check if the object is inside the slope
		if (_objPoint.x > Slope.x + _snapping && _objPoint.x < Slope.x + _tileWidth + Object.width + _snapping && _objPoint.y >= _slopePoint.y && _objPoint.y <= Slope.y + _tileHeight)
		{
			// Call the collide function for the floor slope
			onCollideFloorSlope(Slope, Object);
		}
	}
	
	/**
	 * Solves collision against a right-sided floor slope
	 * 
	 * @param 	Slope 	The slope to check against
	 * @param 	Object 	The object that collides with the slope
	 */
	private function solveCollisionSlopeFloorRight(Slope:FlxObject, Object:FlxObject):Void
	{
		// Calculate the corner point of the object
		_objPoint.x = Math.floor(Object.x - _snapping);
		_objPoint.y = Math.floor(Object.y + Object.height);
		
		// Calculate position of the point on the slope that the object might overlap
		// this would be one side of the object projected onto the slope's surface
		_slopePoint.x = _objPoint.x;
		_slopePoint.y = (Slope.y + _tileHeight) - (Slope.x - _slopePoint.x + _tileWidth);
		
		// Fix the slope point to the slope tile
		fixSlopePoint(cast(Slope, FlxTile));
		
		// Check if the object is inside the slope
		if (_objPoint.x > Slope.x - Object.width - _snapping && _objPoint.x < Slope.x + _tileWidth + _snapping && _objPoint.y >= _slopePoint.y && _objPoint.y <= Slope.y + _tileHeight)
		{
			// Call the collide function for the floor slope
			onCollideFloorSlope(Slope, Object);
		}
	}
	
	/**
	 * Solves collision against a left-sided ceiling slope
	 * 
	 * @param 	Slope 	The slope to check against
	 * @param 	Obj 	The object that collides with the slope
	 */
	private function solveCollisionSlopeCeilLeft(Slope:FlxObject, Obj:FlxObject):Void
	{
		// Calculate the corner point of the object
		_objPoint.x = Math.floor(Obj.x + Obj.width + _snapping);
		_objPoint.y = Math.ceil(Obj.y);
		
		// Calculate position of the point on the slope that the object might overlap
		// this would be one side of the object projected onto the slope's surface
		_slopePoint.x = _objPoint.x;
		_slopePoint.y = (Slope.y) + (_slopePoint.x - Slope.x);
		
		// Fix the slope point to the slope tile
		fixSlopePoint(cast(Slope, FlxTile));
		
		// Check if the object is inside the slope
		if (_objPoint.x > Slope.x + _snapping && _objPoint.x < Slope.x + _tileWidth + Obj.width + _snapping && _objPoint.y <= _slopePoint.y && _objPoint.y >= Slope.y)
		{
			// Call the collide function for the floor slope
			onCollideCeilSlope(Slope, Obj);
		}
	}
	
	/**
	 * Solves collision against a right-sided ceiling slope
	 * 
	 * @param 	Slope 	The slope to check against
	 * @param 	Obj 	The object that collides with the slope
	 */
	private function solveCollisionSlopeCeilRight(Slope:FlxObject, Obj:FlxObject):Void
	{
		// Calculate the corner point of the object
		_objPoint.x = Math.floor(Obj.x - _snapping);
		_objPoint.y = Math.ceil(Obj.y);
		
		// Calculate position of the point on the slope that the object might overlap
		// this would be one side of the object projected onto the slope's surface
		_slopePoint.x = _objPoint.x;
		_slopePoint.y = (Slope.y) + (Slope.x - _slopePoint.x + _tileWidth);
		
		// Fix the slope point to the slope tile
		fixSlopePoint(cast(Slope, FlxTile));
		
		// Check if the object is inside the slope
		if (_objPoint.x > Slope.x - Obj.width - _snapping && _objPoint.x < Slope.x + _tileWidth + _snapping && _objPoint.y <= _slopePoint.y && _objPoint.y >= Slope.y)
		{
			// Call the collide function for the floor slope
			onCollideCeilSlope(Slope, Obj);
		}
	}
	
	/**
	 * Internal helper function for setting the tiles currently held in the slope arrays to use slope collision.
	 * Note that if you remove items from a slope, this function will not unset the slope property.
	 */
	private function setSlopeProperties():Void
	{
		for (i in 0..._slopeFloorLeft.length)
		{
			setTileProperties(_slopeFloorLeft[i], FlxObject.RIGHT | FlxObject.FLOOR, solveCollisionSlopeFloorLeft);			
		}
		for (i in 0..._slopeFloorRight.length)
		{
			setTileProperties(_slopeFloorRight[i], FlxObject.LEFT | FlxObject.FLOOR, solveCollisionSlopeFloorRight);
		}
		for (i in 0..._slopeCeilLeft.length)
		{
			setTileProperties(_slopeCeilLeft[i], FlxObject.RIGHT | FlxObject.CEILING, solveCollisionSlopeCeilLeft);			
		}
		for (i in 0..._slopeCeilRight.length)
		{
			setTileProperties(_slopeCeilRight[i], FlxObject.LEFT | FlxObject.CEILING, solveCollisionSlopeCeilRight);
		}
	}
	
	/**
	 * Internal helper function for comparing a tile to the slope arrays to see if a tile should be treated as a slope.
	 * 
	 * @param 	TileIndex	The Tile Index number of the Tile you want to check.
	 * @return	Returns true if the tile is listed in one of the slope arrays. Otherwise returns false.
	 */
	private function checkArrays(TileIndex:Int):Bool
	{
		for (i in 0..._slopeFloorLeft.length)
		{
			if (_slopeFloorLeft[i] == TileIndex)
			{
				return true;
			}
		}	
		for (i in 0..._slopeFloorRight.length)
		{
			if (_slopeFloorRight[i] == TileIndex)
			{
				return true;
			}
		}	
		for (i in 0..._slopeCeilLeft.length)
		{
			if (_slopeCeilLeft[i] == TileIndex)
			{
				return true;
			}
		}	
		for (i in 0..._slopeCeilRight.length)
		{
			if (_slopeCeilRight[i] == TileIndex)
			{
				return true;
			}
		}	
		
		return false;
	}
	
	override private function set_frames(value:FlxFramesCollection):FlxFramesCollection
	{
		super.set_frames(value);
		
		if (value != null && _specialTiles != null && _specialTiles.length > 0)
		{
			for (t in _specialTiles) 
			{
				if (t != null) 
				{
					t.frames = frames;
				}
			}
		}
		
		return value;
	}
}