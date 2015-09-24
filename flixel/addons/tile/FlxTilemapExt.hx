package flixel.addons.tile;

import flash.display.BitmapData;
import flixel.addons.tile.FlxTilemapExt;
import flixel.addons.tile.FlxTileSpecial;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.tile.FlxTile;
import flixel.tile.FlxTilemap;
import flixel.tile.FlxTilemapBuffer;
import flixel.util.FlxDestroyUtil;

// TODO: add support for tilemap scaling
// TODO: try to make it cleaner (i mean rendering and animated tiles)

/**
 * Extended FlxTilemap class that provides collision detection against slopes
 * Based on the original by Dirk Bunk.
 * ---
 * Also add support to flipped / rotated tiles.
 * @author Peter Christiansen
 * @author MrCdK
 * @author adrianulima
 * @link https://github.com/TheTurnipMaster/SlopeDemo
 */
class FlxTilemapExt extends FlxTilemap
{
	// Slope related variables
	private var _snapping:Int = 2;
	private var _slopePoint:FlxPoint;
	private var _objPoint:FlxPoint;
	
	private var _slopeFloorLeft:Array<Int>;
	private var _slopeFloorRight:Array<Int>;
	private var _slopeCeilLeft:Array<Int>;
	private var _slopeCeilRight:Array<Int>;
	
	private var _slope22High:Array<Int>;
	private var _slope22Low:Array<Int>;
	private var _slope67High:Array<Int>;
	private var _slope67Low:Array<Int>;
	
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
		
		_slope22High = new Array<Int>();
		_slope22Low = new Array<Int>();
		_slope67High = new Array<Int>();
		_slope67Low = new Array<Int>();
		
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
		
		_slope22High = null;
		_slope22Low = null;
		_slope67High = null;
		_slope67Low = null;
		
		super.destroy();
		
		_specialTiles = FlxDestroyUtil.destroyArray(_specialTiles);
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		if (_specialTiles != null && _specialTiles.length > 0) 
		{
			for (tile in _specialTiles) 
			{
				if (tile != null && tile.hasAnimation()) 
				{
					tile.update(elapsed);
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
		
		_helperPoint.x = isPixelPerfectRender(Camera) ? Math.floor(_helperPoint.x) : _helperPoint.x;
		_helperPoint.y = isPixelPerfectRender(Camera) ? Math.floor(_helperPoint.y) : _helperPoint.y;
		
		var scaledWidth:Float = _tileWidth;
		var scaledHeight:Float = _tileHeight;
		
		var drawX:Float;
		var drawY:Float;
		
		var _tileTransformMatrix:FlxMatrix = null;
		var matrixToUse:FlxMatrix;
		
		var cr:Float = color.redFloat;
		var cg:Float = color.greenFloat;
		var cb:Float = color.blueFloat;
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
					special.paint(Buffer.pixels, _flashPoint);
					Buffer.dirty = (special.dirty || Buffer.dirty);
				}
				else if (tile != null && tile.visible && tile.frame.type != FlxFrameType.EMPTY)
				{
					tile.frame.paint(Buffer.pixels, _flashPoint, true);
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
					drawX = _helperPoint.x + (columnIndex % widthInTiles) * scaledWidth;
					drawY = _helperPoint.y + Math.floor(columnIndex / widthInTiles) * scaledHeight;
					
					if (isSpecial)
					{
						_tileTransformMatrix = special.getMatrix();
						matrixToUse = _tileTransformMatrix;
					}
					else
					{
						frame.prepareMatrix(_matrix);
						matrixToUse = _matrix;
					}
					
					matrixToUse.translate(drawX, drawY);
					Camera.drawPixels(frame, matrixToUse, cr, cg, cb, alpha, blend);
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
		var tile:FlxTileSpecial;
		for (i in 0...tiles.length) 
		{
			tile = tiles[i];
			if (tile != null && tile.isSpecial())
			{
				_specialTiles[i] = tile;
				
				tile.currTileId -= _startingIndex;
				tile.frames = this.frames;
				
				if (tile.hasAnimation()) 
				{
					var animFrames:Array<Int> = tile.animation.frames;
					var preparedFrames:Array<Int> = [];
					
					for (j in 0...animFrames.length)
					{
						preparedFrames[j] = animFrames[j] - _startingIndex;
					}
					
					tile.animation.frames = preparedFrames;
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
	 * Sets the slope arrays, which define which tiles are treated as slopes of 22.5 degrees.
	 * 
	 * @param 	HighSlopes 	An array containing the numbers of the tiles to be treated as high slope tiles with a slope on the left.
	 * @param 	LowSlopes	An array containing the numbers of the tiles to be treated as low slope tiles with a slope on the right.
	 */
	public function setSlopes22(?HighSlopes:Array<Int>, ?LowSlopes:Array<Int>) 
	{
		if (HighSlopes != null)
		{
			_slope22High = HighSlopes;
		}
		
		if (LowSlopes != null)
		{
			_slope22Low = LowSlopes;
			for (tile in _slope22Low)
			{
				_tileObjects[tile].allowCollisions = (_slopeCeilLeft.indexOf(tile) >= 0 || _slopeCeilRight.indexOf(tile) >= 0 )? FlxObject.CEILING : FlxObject.FLOOR;
			}
		}
	}
	
	/**
	 * Sets the slope arrays, which define which tiles are treated as slopes of 67.5 degrees.
	 * 
	 * @param 	HighSlopes 	An array containing the numbers of the tiles to be treated as high slope tiles with a slope on the left.
	 * @param 	LowSlopes	An array containing the numbers of the tiles to be treated as low slope tiles with a slope on the right.
	 */
	public function setSlopes67(?HighSlopes:Array<Int>, ?LowSlopes:Array<Int>) 
	{
		if (HighSlopes != null)
		{
			_slope67High = HighSlopes;
		}
		
		if (LowSlopes != null)
		{
			_slope67Low = LowSlopes;
			for (tile in _slope67Low)
			{
				_tileObjects[tile].allowCollisions = (_slopeCeilLeft.indexOf(tile) >= 0 || _slopeFloorLeft.indexOf(tile) >= 0 )? FlxObject.RIGHT : FlxObject.LEFT;
			}
		}
	}
	
	
	/**
	 * Internal helpers function for comparing a tile to the slope arrays to see if a tile should be treated as a slope of 22.5 degrees.
	 * 
	 * @param 	TileIndex	The Tile Index number of the Tile you want to check.
	 * @return	Returns true if the tile is listed in one of the slope arrays. Otherwise returns false.
	 */
	private function checkHighSlope22(TileIndex:Int):Bool
	{
		return _slope22High.indexOf(TileIndex) >= 0;
	}
	
	private function checkLowSlope22(TileIndex:Int):Bool
	{
		return _slope22Low.indexOf(TileIndex) >= 0;
	}
	
	private function checkHighSlope67(TileIndex:Int):Bool
	{
		return _slope67High.indexOf(TileIndex) >= 0;
	}
	
	private function checkLowSlope67(TileIndex:Int):Bool
	{
		return _slope67Low.indexOf(TileIndex) >= 0;
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
		Object.velocity.y = Math.min(Object.velocity.y, 0);
		
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
		Object.velocity.y = Math.max(Object.velocity.y, 0);
		
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
		
		var tileId:Int = cast(Slope, FlxTile).index;
		if (checkLowSlope67(tileId))
		{
			if (_slopePoint.x - Slope.x <= _tileWidth / 2)
			{
				return;
			}
			else
			{
				_slopePoint.y = Slope.y + _tileHeight * (2 - (2 * (_slopePoint.x - Slope.x) / _tileWidth)) + _snapping;
			}
		}
		else if (checkHighSlope67(tileId))
		{
			_slopePoint.y = Slope.y + _tileHeight * (1 - (2 * ((_slopePoint.x - Slope.x) / _tileWidth))) + _snapping;
		}
		else if (checkHighSlope22(tileId))
		{
			_slopePoint.y = Slope.y + (_tileHeight - _slopePoint.x + Slope.x) / 2;
		}
		else if (checkLowSlope22(tileId))
		{
			_slopePoint.y = Slope.y + _tileHeight - (_slopePoint.x - Slope.x) / 2;
		}
		
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
		
		var tileId:Int = cast(Slope, FlxTile).index;
		if (checkLowSlope67(tileId))
		{
			if (_slopePoint.x - Slope.x >= _tileWidth / 2)
			{
				return;
			}
			else
			{
				_slopePoint.y = Slope.y + _tileHeight * 2 * ((_slopePoint.x - Slope.x) / _tileWidth) + _snapping;
			}
		}
		else if (checkHighSlope67(tileId))
		{
			_slopePoint.y = Slope.y - _tileHeight * (1 + (2 * ((Slope.x - _slopePoint.x) / _tileWidth))) + _snapping;
		}
		else if (checkHighSlope22(tileId))
		{
			_slopePoint.y = Slope.y + (_tileHeight - Slope.x + _slopePoint.x - _tileWidth) / 2;
		}
		else if (checkLowSlope22(tileId))
		{
			_slopePoint.y = Slope.y + _tileHeight - (Slope.x - _slopePoint.x + _tileWidth) / 2;
		}
		
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
	 * @param 	Object 	The object that collides with the slope
	 */
	private function solveCollisionSlopeCeilLeft(Slope:FlxObject, Object:FlxObject):Void
	{
		// Calculate the corner point of the object
		_objPoint.x = Math.floor(Object.x + Object.width + _snapping);
		_objPoint.y = Math.ceil(Object.y);
		
		// Calculate position of the point on the slope that the object might overlap
		// this would be one side of the object projected onto the slope's surface
		_slopePoint.x = _objPoint.x;
		_slopePoint.y = Slope.y + (_slopePoint.x - Slope.x);
		
		var tileId:Int = cast(Slope, FlxTile).index;
		if (checkLowSlope67(tileId))
		{
			if (_slopePoint.x - Slope.x <= _tileWidth / 2)
			{
				return;
			}
			else
			{
				_slopePoint.y = Slope.y - _tileHeight * (1 + (2 * ((Slope.x - _slopePoint.x) / _tileWidth))) - _snapping;
			}
		}
		else if (checkHighSlope67(tileId))
		{
			_slopePoint.y = Slope.y + _tileHeight * 2 * ((_slopePoint.x - Slope.x) / _tileWidth) - _snapping;
		}
		else if (checkHighSlope22(tileId))
		{
			_slopePoint.y = Slope.y + _tileHeight - (Slope.x - _slopePoint.x + _tileWidth) / 2;
		}
		else if (checkLowSlope22(tileId))
		{
			_slopePoint.y = Slope.y + (_tileHeight - Slope.x + _slopePoint.x - _tileWidth) / 2;
		}
		
		// Fix the slope point to the slope tile
		fixSlopePoint(cast(Slope, FlxTile));
		
		// Check if the object is inside the slope
		if (_objPoint.x > Slope.x + _snapping && _objPoint.x < Slope.x + _tileWidth + Object.width + _snapping && _objPoint.y <= _slopePoint.y && _objPoint.y >= Slope.y)
		{
			// Call the collide function for the floor slope
			onCollideCeilSlope(Slope, Object);
		}
	}
	
	/**
	 * Solves collision against a right-sided ceiling slope
	 * 
	 * @param 	Slope 	The slope to check against
	 * @param 	Object 	The object that collides with the slope
	 */
	private function solveCollisionSlopeCeilRight(Slope:FlxObject, Object:FlxObject):Void
	{
		// Calculate the corner point of the object
		_objPoint.x = Math.floor(Object.x - _snapping);
		_objPoint.y = Math.ceil(Object.y);
		
		// Calculate position of the point on the slope that the object might overlap
		// this would be one side of the object projected onto the slope's surface
		_slopePoint.x = _objPoint.x;
		_slopePoint.y = (Slope.y) + (Slope.x - _slopePoint.x + _tileWidth);
		
		var tileId:Int = cast(Slope, FlxTile).index;
		if (checkLowSlope67(tileId))
		{
			if (_slopePoint.x - Slope.x >= _tileWidth / 2)
			{
				return;
			}
			else
			{
				_slopePoint.y = Slope.y + _tileHeight * (1 - (2 * ((_slopePoint.x - Slope.x) / _tileWidth))) - _snapping;
			}
		}
		else if (checkHighSlope67(tileId))
		{
			_slopePoint.y = Slope.y + _tileHeight * (2 - (2 * (_slopePoint.x - Slope.x) / _tileWidth)) - _snapping;
		}
		else if (checkHighSlope22(tileId))
		{
			_slopePoint.y = Slope.y + _tileHeight - (_slopePoint.x - Slope.x) / 2;
		}
		else if (checkLowSlope22(tileId))
		{
			_slopePoint.y = Slope.y + (_tileHeight - _slopePoint.x + Slope.x) / 2;
		}
		
		// Fix the slope point to the slope tile
		fixSlopePoint(cast(Slope, FlxTile));
		
		// Check if the object is inside the slope
		if (_objPoint.x > Slope.x - Object.width - _snapping && _objPoint.x < Slope.x + _tileWidth + _snapping && _objPoint.y <= _slopePoint.y && _objPoint.y >= Slope.y)
		{
			// Call the collide function for the floor slope
			onCollideCeilSlope(Slope, Object);
		}
	}
	
	/**
	 * Internal helper function for setting the tiles currently held in the slope arrays to use slope collision.
	 * Note that if you remove items from a slope, this function will not unset the slope property.
	 */
	private function setSlopeProperties():Void
	{
		for (tile in _slopeFloorLeft)
		{
			setTileProperties(tile, FlxObject.RIGHT | FlxObject.FLOOR, solveCollisionSlopeFloorLeft);
		}
		for (tile in _slopeFloorRight)
		{
			setTileProperties(tile, FlxObject.LEFT | FlxObject.FLOOR, solveCollisionSlopeFloorRight);
		}
		for (tile in _slopeCeilLeft)
		{
			setTileProperties(tile, FlxObject.RIGHT | FlxObject.CEILING, solveCollisionSlopeCeilLeft);
		}
		for (tile in _slopeCeilRight)
		{
			setTileProperties(tile, FlxObject.LEFT | FlxObject.CEILING, solveCollisionSlopeCeilRight);
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
		return _slopeFloorLeft.indexOf(TileIndex) >= 0 || _slopeFloorRight.indexOf(TileIndex) >= 0 || _slopeCeilLeft.indexOf(TileIndex) >= 0 || _slopeCeilRight.indexOf(TileIndex) >= 0;
	}
	
	override private function set_frames(value:FlxFramesCollection):FlxFramesCollection
	{
		super.set_frames(value);
		
		if (value != null && _specialTiles != null && _specialTiles.length > 0)
		{
			for (tile in _specialTiles) 
			{
				if (tile != null) 
				{
					tile.frames = frames;
				}
			}
		}
		
		return value;
	}
}