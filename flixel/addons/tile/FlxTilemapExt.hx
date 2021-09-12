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
import flixel.util.FlxDirectionFlags;

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
 * ---
 * Downward Slope fix
 * @author Early Melon
 */
class FlxTilemapExt extends FlxTilemap
{
	// Slope related variables
	var _snapping:Int = 2;
	var _slopePoint:FlxPoint = FlxPoint.get();
	var _objPoint:FlxPoint = FlxPoint.get();
	var _downwardsGlue:Bool = false;

	var _velocityYDownSlope:Float;
	var _slopeSlowDownFactor:Float = 0;

	var _slopeNorthwest:Array<Int> = [];
	var _slopeNortheast:Array<Int> = [];
	var _slopeSouthwest:Array<Int> = [];
	var _slopeSoutheast:Array<Int> = [];

	var _slopeThickGentle:Array<Int> = [];
	var _slopeThinGentle:Array<Int> = [];
	var _slopeThickSteep:Array<Int> = [];
	var _slopeThinSteep:Array<Int> = [];

	// Animated and flipped tiles related variables
	var _specialTiles:Array<FlxTileSpecial>;

	override public function destroy():Void
	{
		_slopePoint = FlxDestroyUtil.put(_slopePoint);
		_objPoint = FlxDestroyUtil.put(_objPoint);

		_slopeNorthwest = null;
		_slopeNortheast = null;
		_slopeSouthwest = null;
		_slopeSoutheast = null;

		_slopeThickGentle = null;
		_slopeThinGentle = null;
		_slopeThickSteep = null;
		_slopeThinSteep = null;

		super.destroy();

		_specialTiles = FlxDestroyUtil.destroyArray(_specialTiles);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		var dirty:Bool = false;

		if (_specialTiles != null && _specialTiles.length > 0)
		{
			for (tile in _specialTiles)
			{
				if (tile != null && tile.hasAnimation())
				{
					tile.update(elapsed);
					dirty = dirty || tile.dirty;
				}
			}
		}

		if (dirty)
			setDirty(true);
	}

	/**
	 * THIS IS A COPY FROM FlxTilemap BUT IT DEALS WITH FLIPPED AND ROTATED TILES
	 * Internal function that actually renders the tilemap to the tilemap buffer.  Called by draw().
	 * @param	Buffer		The FlxTilemapBuffer you are rendering to.
	 * @param	Camera		The related FlxCamera, mainly for scroll values.
	 */
	@:access(flixel.FlxCamera)
	override function drawTilemap(Buffer:FlxTilemapBuffer, Camera:FlxCamera):Void
	{
		var isColored:Bool = ((alpha != 1) || (color != 0xffffff));

		var drawX:Float = 0;
		var drawY:Float = 0;
		var scaledWidth:Float = _tileWidth;
		var scaledHeight:Float = _tileHeight;

		var _tileTransformMatrix:FlxMatrix = null;
		var matrixToUse:FlxMatrix;

		if (FlxG.renderBlit)
		{
			Buffer.fill();
		}
		else
		{
			getScreenPosition(_point, Camera).copyToFlash(_helperPoint);

			_helperPoint.x = isPixelPerfectRender(Camera) ? Math.floor(_helperPoint.x) : _helperPoint.x;
			_helperPoint.y = isPixelPerfectRender(Camera) ? Math.floor(_helperPoint.y) : _helperPoint.y;
		}

		// Copy tile images into the tile buffer
		_point.x = (Camera.scroll.x * scrollFactor.x) - x - offset.x + Camera.viewOffsetX; // modified from getScreenPosition()
		_point.y = (Camera.scroll.y * scrollFactor.y) - y - offset.y + Camera.viewOffsetY;

		var screenXInTiles:Int = Math.floor(_point.x / _tileWidth);
		var screenYInTiles:Int = Math.floor(_point.y / _tileHeight);
		var screenRows:Int = Buffer.rows;
		var screenColumns:Int = Buffer.columns;

		// Bound the upper left corner
		screenXInTiles = Std.int(FlxMath.bound(screenXInTiles, 0, widthInTiles - screenColumns));
		screenYInTiles = Std.int(FlxMath.bound(screenYInTiles, 0, heightInTiles - screenRows));

		var rowIndex:Int = screenYInTiles * widthInTiles + screenXInTiles;
		_flashPoint.y = 0;
		var columnIndex:Int;
		var tile:FlxTile;
		var frame:FlxFrame;
		var special:FlxTileSpecial;

		#if FLX_DEBUG
		var debugTile:BitmapData;
		#end

		var isSpecial:Bool = false;

		for (row in 0...screenRows)
		{
			columnIndex = rowIndex;
			_flashPoint.x = 0;

			for (column in 0...screenColumns)
			{
				tile = _tileObjects[_data[columnIndex]];
				special = null;
				isSpecial = false;

				if (_specialTiles != null && _specialTiles[columnIndex] != null)
				{
					special = _specialTiles[columnIndex];
					isSpecial = special.isSpecial();
				}

				if (FlxG.renderBlit)
				{
					if (isSpecial)
					{
						special.paint(Buffer.pixels, _flashPoint);
						Buffer.dirty = (special.dirty || Buffer.dirty);
					}
					else if (tile != null && tile.visible && tile.frame.type != FlxFrameType.EMPTY)
					{
						tile.frame.paint(Buffer.pixels, _flashPoint, true);
					}

					#if FLX_DEBUG
					if (FlxG.debugger.drawDebug && !ignoreDrawDebug)
					{
						if (tile != null)
						{
							if (tile.allowCollisions <= NONE)
							{
								debugTile = _debugTileNotSolid;
							}
							else if (tile.allowCollisions != ANY)
							{
								debugTile = _debugTilePartial;
							}
							else
							{
								debugTile = _debugTileSolid;
							}

							offset.addToFlash(_flashPoint);
							Buffer.pixels.copyPixels(debugTile, _debugRect, _flashPoint, null, null, true);
							offset.subtractFromFlash(_flashPoint);
						}
					}
					#end
				}
				else
				{
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
						Camera.drawPixels(frame, matrixToUse, colorTransform, blend);
					}
				}

				if (FlxG.renderBlit)
				{
					_flashPoint.x += _tileWidth;
				}
				columnIndex++;
			}

			rowIndex += widthInTiles;
			if (FlxG.renderBlit)
			{
				_flashPoint.y += _tileHeight;
			}
		}

		Buffer.x = screenXInTiles * _tileWidth;
		Buffer.y = screenYInTiles * _tileHeight;

		if (FlxG.renderBlit)
		{
			if (isColored)
				Buffer.colorTransform(colorTransform);
			Buffer.blend = blend;
		}

		Buffer.dirty = false;
	}

	/**
	 * Set the special tiles (rotated or flipped)
	 * @param	tiles	An Array with all the FlxTileSpecial
	 */
	public function setSpecialTiles(tiles:Array<FlxTileSpecial>):Void
	{
		_specialTiles = new Array<FlxTileSpecial>();

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
	override public function overlapsWithCallback(Object:FlxObject, ?Callback:FlxObject->FlxObject->Bool, FlipCallbackParams:Bool = false,
			?Position:FlxPoint):Bool
	{
		var results:Bool = false;

		var X:Float = x;
		var Y:Float = y;

		if (Position != null)
		{
			X = Position.x;
			Y = Position.y;
		}

		// Figure out what tiles we need to check against
		var selectionX:Int = Math.floor((Object.x - X) / _tileWidth);
		var selectionY:Int = Math.floor((Object.y - Y) / _tileHeight);
		var selectionWidth:Int = selectionX + (Math.ceil(Object.width / _tileWidth)) + 1;
		var selectionHeight:Int = selectionY + Math.ceil(Object.height / _tileHeight) + 1;

		// Then bound these coordinates by the map edges
		selectionX = FlxMath.maxInt(selectionX, 0);
		selectionY = FlxMath.maxInt(selectionY, 0);
		selectionWidth = FlxMath.minInt(selectionWidth, widthInTiles);
		selectionHeight = FlxMath.minInt(selectionHeight, heightInTiles);

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
						overlapFound = (Object.x + Object.width > tile.x) && (Object.x < tile.x + tile.width) && (Object.y + Object.height > tile.y)
							&& (Object.y < tile.y + tile.height);
					}

					// New generalized slope collisions
					if (overlapFound || (!overlapFound && checkArrays(tile.index)))
					{
						if ((tile.callbackFunction != null)
							&& ((tile.filter == null) || #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end (Object, tile.filter)))
						{
							tile.mapIndex = rowStart + column;
							tile.callbackFunction(tile, Object);
						}
						results = true;
					}
				}
				else if ((tile.callbackFunction != null)
					&& ((tile.filter == null) || #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end (Object, tile.filter)))
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
	 * Set glue to force contact with slopes and a slow down factor while climbing
	 *
	 * @param 	downwardsGlue  Activate/Deactivate glue on slopes on the
	 * @param 	slopeSlowDownFactor  A slowing down factor while climbing slopes, from 0.0 to 1.0, By default 0.0, no slow down.
	 * @param 	velocityYDownSlope The maximum velocity Y down a slope, it should be high enough to be able to use downwardsGlue. Default to 200.
	 *
	 * @since 2.9.0
	 */
	public function setDownwardsGlue(downwardsGlue:Bool, slopeSlowDownFactor:Float = 0.0, velocityYDownSlope:Float = 200):Void
	{
		_downwardsGlue = downwardsGlue;
		_slopeSlowDownFactor = 1 - slopeSlowDownFactor / 10;
		_velocityYDownSlope = velocityYDownSlope;
	}

	/**
	 * Sets the slope arrays, which define which tiles are treated as slopes.
	 *
	 * @param 	Northwest 	An array containing the numbers of the tiles facing Northwest to be treated as floor tiles with a slope on the left.
	 * @param 	Northeast	An array containing the numbers of the tiles facing Northeast to be treated as floor tiles with a slope on the right.
	 * @param 	Southwest	An array containing the numbers of the tiles facing Southwest to be treated as ceiling tiles with a slope on the left.
	 * @param 	Southeast	An array containing the numbers of the tiles facing Southeast to be treated as ceiling tiles with a slope on the right.
	 */
	public function setSlopes(?Northwest:Array<Int>, ?Northeast:Array<Int>, ?Southwest:Array<Int>, ?Southeast:Array<Int>):Void
	{
		if (Northwest != null)
		{
			_slopeNorthwest = Northwest;
		}
		if (Northeast != null)
		{
			_slopeNortheast = Northeast;
		}
		if (Southwest != null)
		{
			_slopeSouthwest = Southwest;
		}
		if (Southeast != null)
		{
			_slopeSoutheast = Southeast;
		}
		setSlopeProperties();
	}

	/**
	 * Sets the gentle slopes. About 26.5 degrees.
	 *
	 * @param 	ThickTiles 	An array containing the numbers of the tiles to be treated as thick slope.
	 * @param 	ThinTiles	An array containing the numbers of the tiles to be treated as thin slope.
	 */
	public function setGentle(ThickTiles:Array<Int>, ThinTiles:Array<Int>)
	{
		if (ThickTiles != null)
		{
			_slopeThickGentle = ThickTiles;
		}

		if (ThinTiles != null)
		{
			_slopeThinGentle = ThinTiles;
			for (tile in _slopeThinGentle)
			{
				_tileObjects[tile].allowCollisions = (_slopeSouthwest.indexOf(tile) >= 0 || _slopeSoutheast.indexOf(tile) >= 0) ? CEILING : FLOOR;
			}
		}
	}

	/**
	 * Sets the steep slopes. About 63.5 degrees.
	 *
	 * @param 	ThickTiles 	An array containing the numbers of the tiles to be treated as thick slope.
	 * @param 	ThinTiles	An array containing the numbers of the tiles to be treated as thin slope.
	 */
	public function setSteep(ThickTiles:Array<Int>, ThinTiles:Array<Int>)
	{
		if (ThickTiles != null)
		{
			_slopeThickSteep = ThickTiles;
		}

		if (ThinTiles != null)
		{
			_slopeThinSteep = ThinTiles;
			for (tile in _slopeThinSteep)
			{
				_tileObjects[tile].allowCollisions = (_slopeSouthwest.indexOf(tile) >= 0 || _slopeNorthwest.indexOf(tile) >= 0) ? RIGHT : LEFT;
			}
		}
	}

	/**
	 * Internal helper functions for comparing a tile to the slope arrays to see if a tile should be treated as STEEP or GENTLE slope.
	 *
	 * @param 	TileIndex	The Tile Index number of the Tile you want to check.
	 * @return	Returns true if the tile is listed in one of the slope arrays. Otherwise returns false.
	 */
	function checkThickGentle(TileIndex:Int):Bool
	{
		return _slopeThickGentle.indexOf(TileIndex) >= 0;
	}

	function checkThinGentle(TileIndex:Int):Bool
	{
		return _slopeThinGentle.indexOf(TileIndex) >= 0;
	}

	function checkThickSteep(TileIndex:Int):Bool
	{
		return _slopeThickSteep.indexOf(TileIndex) >= 0;
	}

	function checkThinSteep(TileIndex:Int):Bool
	{
		return _slopeThinSteep.indexOf(TileIndex) >= 0;
	}

	/**
	 * Bounds the slope point to the slope
	 *
	 * @param 	Slope 	The slope to fix the slopePoint for
	 */
	function fixSlopePoint(Slope:FlxTile):Void
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
	function onCollideFloorSlope(Slope:FlxObject, Object:FlxObject):Void
	{
		// Set the object's touching flag
		Object.touching = FLOOR;

		// Adjust the object's velocity
		if (_downwardsGlue)
			Object.velocity.y = _velocityYDownSlope;
		else
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
	function onCollideCeilSlope(Slope:FlxObject, Object:FlxObject):Void
	{
		// Set the object's touching flag
		Object.touching = CEILING;

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
	function solveCollisionSlopeNorthwest(Slope:FlxObject, Object:FlxObject):Void
	{
		if (Object.x + Object.width > Slope.x + Slope.width + _snapping)
		{
			return;
		}
		// Calculate the corner point of the object
		_objPoint.x = Math.floor(Object.x + Object.width + _snapping);
		_objPoint.y = Math.floor(Object.y + Object.height);

		// Calculate position of the point on the slope that the object might overlap
		// this would be one side of the object projected onto the slope's surface
		_slopePoint.x = _objPoint.x;
		_slopePoint.y = (Slope.y + _tileHeight) - (_slopePoint.x - Slope.x);

		var tileId:Int = cast(Slope, FlxTile).index;
		if (checkThinSteep(tileId))
		{
			if (_slopePoint.x - Slope.x <= _tileWidth / 2)
			{
				return;
			}
			else
			{
				_slopePoint.y = Slope.y + _tileHeight * (2 - (2 * (_slopePoint.x - Slope.x) / _tileWidth)) + _snapping;
				if (_downwardsGlue && Object.velocity.x > 0)
					Object.velocity.x *= 1 - (1 - _slopeSlowDownFactor) * 3;
			}
		}
		else if (checkThickSteep(tileId))
		{
			_slopePoint.y = Slope.y + _tileHeight * (1 - (2 * ((_slopePoint.x - Slope.x) / _tileWidth))) + _snapping;
			if (_downwardsGlue && Object.velocity.x > 0)
				Object.velocity.x *= 1 - (1 - _slopeSlowDownFactor) * 3;
		}
		else if (checkThickGentle(tileId))
		{
			_slopePoint.y = Slope.y + (_tileHeight - _slopePoint.x + Slope.x) / 2;
			if (_downwardsGlue && Object.velocity.x > 0)
				Object.velocity.x *= _slopeSlowDownFactor;
		}
		else if (checkThinGentle(tileId))
		{
			_slopePoint.y = Slope.y + _tileHeight - (_slopePoint.x - Slope.x) / 2;
			if (_downwardsGlue && Object.velocity.x > 0)
				Object.velocity.x *= _slopeSlowDownFactor;
		}
		else
		{
			if (_downwardsGlue && Object.velocity.x > 0)
				Object.velocity.x *= _slopeSlowDownFactor;
		}
		// Fix the slope point to the slope tile
		fixSlopePoint(cast(Slope, FlxTile));

		// Check if the object is inside the slope
		if (_objPoint.x > Slope.x + _snapping
			&& _objPoint.x < Slope.x + _tileWidth + Object.width + _snapping
			&& _objPoint.y >= _slopePoint.y
			&& _objPoint.y <= Slope.y + _tileHeight)
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
	function solveCollisionSlopeNortheast(Slope:FlxObject, Object:FlxObject):Void
	{
		if (Object.x < Slope.x - _snapping)
		{
			return;
		}
		// Calculate the corner point of the object
		_objPoint.x = Math.floor(Object.x - _snapping);
		_objPoint.y = Math.floor(Object.y + Object.height);

		// Calculate position of the point on the slope that the object might overlap
		// this would be one side of the object projected onto the slope's surface
		_slopePoint.x = _objPoint.x;
		_slopePoint.y = (Slope.y + _tileHeight) - (Slope.x - _slopePoint.x + _tileWidth);

		var tileId:Int = cast(Slope, FlxTile).index;
		if (checkThinSteep(tileId))
		{
			if (_slopePoint.x - Slope.x >= _tileWidth / 2)
			{
				return;
			}
			else
			{
				_slopePoint.y = Slope.y + _tileHeight * 2 * ((_slopePoint.x - Slope.x) / _tileWidth) + _snapping;
			}
			if (_downwardsGlue && Object.velocity.x < 0)
				Object.velocity.x *= 1 - (1 - _slopeSlowDownFactor) * 3;
		}
		else if (checkThickSteep(tileId))
		{
			_slopePoint.y = Slope.y - _tileHeight * (1 + (2 * ((Slope.x - _slopePoint.x) / _tileWidth))) + _snapping;
			if (_downwardsGlue && Object.velocity.x < 0)
				Object.velocity.x *= 1 - (1 - _slopeSlowDownFactor) * 3;
		}
		else if (checkThickGentle(tileId))
		{
			_slopePoint.y = Slope.y + (_tileHeight - Slope.x + _slopePoint.x - _tileWidth) / 2;
			if (_downwardsGlue && Object.velocity.x < 0)
				Object.velocity.x *= _slopeSlowDownFactor;
		}
		else if (checkThinGentle(tileId))
		{
			_slopePoint.y = Slope.y + _tileHeight - (Slope.x - _slopePoint.x + _tileWidth) / 2;
			if (_downwardsGlue && Object.velocity.x < 0)
				Object.velocity.x *= _slopeSlowDownFactor;
		}
		else
		{
			if (_downwardsGlue && Object.velocity.x < 0)
				Object.velocity.x *= _slopeSlowDownFactor;
		}
		// Fix the slope point to the slope tile
		fixSlopePoint(cast(Slope, FlxTile));

		// Check if the object is inside the slope
		if (_objPoint.x > Slope.x - Object.width - _snapping
			&& _objPoint.x < Slope.x + _tileWidth + _snapping
			&& _objPoint.y >= _slopePoint.y
			&& _objPoint.y <= Slope.y + _tileHeight)
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
	function solveCollisionSlopeSouthwest(Slope:FlxObject, Object:FlxObject):Void
	{
		// Calculate the corner point of the object
		_objPoint.x = Math.floor(Object.x + Object.width + _snapping);
		_objPoint.y = Math.ceil(Object.y);

		// Calculate position of the point on the slope that the object might overlap
		// this would be one side of the object projected onto the slope's surface
		_slopePoint.x = _objPoint.x;
		_slopePoint.y = Slope.y + (_slopePoint.x - Slope.x);

		var tileId:Int = cast(Slope, FlxTile).index;
		if (checkThinSteep(tileId))
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
		else if (checkThickSteep(tileId))
		{
			_slopePoint.y = Slope.y + _tileHeight * 2 * ((_slopePoint.x - Slope.x) / _tileWidth) - _snapping;
		}
		else if (checkThickGentle(tileId))
		{
			_slopePoint.y = Slope.y + _tileHeight - (Slope.x - _slopePoint.x + _tileWidth) / 2;
		}
		else if (checkThinGentle(tileId))
		{
			_slopePoint.y = Slope.y + (_tileHeight - Slope.x + _slopePoint.x - _tileWidth) / 2;
		}

		// Fix the slope point to the slope tile
		fixSlopePoint(cast(Slope, FlxTile));

		// Check if the object is inside the slope
		if (_objPoint.x > Slope.x + _snapping
			&& _objPoint.x < Slope.x + _tileWidth + Object.width + _snapping
			&& _objPoint.y <= _slopePoint.y
			&& _objPoint.y >= Slope.y)
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
	function solveCollisionSlopeSoutheast(Slope:FlxObject, Object:FlxObject):Void
	{
		// Calculate the corner point of the object
		_objPoint.x = Math.floor(Object.x - _snapping);
		_objPoint.y = Math.ceil(Object.y);

		// Calculate position of the point on the slope that the object might overlap
		// this would be one side of the object projected onto the slope's surface
		_slopePoint.x = _objPoint.x;
		_slopePoint.y = (Slope.y) + (Slope.x - _slopePoint.x + _tileWidth);

		var tileId:Int = cast(Slope, FlxTile).index;
		if (checkThinSteep(tileId))
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
		else if (checkThickSteep(tileId))
		{
			_slopePoint.y = Slope.y + _tileHeight * (2 - (2 * (_slopePoint.x - Slope.x) / _tileWidth)) - _snapping;
		}
		else if (checkThickGentle(tileId))
		{
			_slopePoint.y = Slope.y + _tileHeight - (_slopePoint.x - Slope.x) / 2;
		}
		else if (checkThinGentle(tileId))
		{
			_slopePoint.y = Slope.y + (_tileHeight - _slopePoint.x + Slope.x) / 2;
		}

		// Fix the slope point to the slope tile
		fixSlopePoint(cast(Slope, FlxTile));

		// Check if the object is inside the slope
		if (_objPoint.x > Slope.x - Object.width - _snapping
			&& _objPoint.x < Slope.x + _tileWidth + _snapping
			&& _objPoint.y <= _slopePoint.y
			&& _objPoint.y >= Slope.y)
		{
			// Call the collide function for the floor slope
			onCollideCeilSlope(Slope, Object);
		}
	}

	/**
	 * Internal helper function for setting the tiles currently held in the slope arrays to use slope collision.
	 * Note that if you remove items from a slope, this function will not unset the slope property.
	 */
	function setSlopeProperties():Void
	{
		for (tile in _slopeNorthwest)
		{
			setTileProperties(tile, RIGHT | FLOOR, solveCollisionSlopeNorthwest);
		}
		for (tile in _slopeNortheast)
		{
			setTileProperties(tile, LEFT | FLOOR, solveCollisionSlopeNortheast);
		}
		for (tile in _slopeSouthwest)
		{
			setTileProperties(tile, RIGHT | CEILING, solveCollisionSlopeSouthwest);
		}
		for (tile in _slopeSoutheast)
		{
			setTileProperties(tile, LEFT | CEILING, solveCollisionSlopeSoutheast);
		}
	}

	/**
	 * Internal helper function for comparing a tile to the slope arrays to see if a tile should be treated as a slope.
	 *
	 * @param 	TileIndex	The Tile Index number of the Tile you want to check.
	 * @return	Returns true if the tile is listed in one of the slope arrays. Otherwise returns false.
	 */
	function checkArrays(TileIndex:Int):Bool
	{
		return _slopeNorthwest.indexOf(TileIndex) >= 0
			|| _slopeNortheast.indexOf(TileIndex) >= 0
			|| _slopeSouthwest.indexOf(TileIndex) >= 0
			|| _slopeSoutheast.indexOf(TileIndex) >= 0;
	}

	override function set_frames(value:FlxFramesCollection):FlxFramesCollection
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
