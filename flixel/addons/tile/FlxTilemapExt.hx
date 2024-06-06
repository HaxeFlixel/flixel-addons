package flixel.addons.tile;

import openfl.display.BitmapData;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.addons.tile.FlxTileSpecial;
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

using flixel.util.FlxColorTransformUtil;

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
	 * Internal function that actually renders the tilemap to the tilemap buffer. Called by draw().
	 *
	 * @param   buffer  The FlxTilemapBuffer you are rendering to.
	 * @param   camera  The related FlxCamera, mainly for scroll values.
	 */
	@:access(flixel.FlxCamera)
	override function drawTilemap(buffer:FlxTilemapBuffer, camera:FlxCamera):Void
	{
		var isColored:Bool = (alpha != 1) || (color != 0xffffff);

		// only used for renderTile
		var drawX:Float = 0;
		var drawY:Float = 0;
		var scaledWidth:Float = 0;
		var scaledHeight:Float = 0;
		var drawItem = null;

		var _tileTransformMatrix:FlxMatrix = null;
		var matrixToUse:FlxMatrix;

		if (FlxG.renderBlit)
		{
			buffer.fill();
		}
		else
		{
			getScreenPosition(_point, camera).subtractPoint(offset).copyToFlash(_helperPoint);

			_helperPoint.x = isPixelPerfectRender(camera) ? Math.floor(_helperPoint.x) : _helperPoint.x;
			_helperPoint.y = isPixelPerfectRender(camera) ? Math.floor(_helperPoint.y) : _helperPoint.y;

			scaledWidth = scaledTileWidth;
			scaledHeight = scaledTileHeight;

			var hasColorOffsets:Bool = (colorTransform != null && colorTransform.hasRGBAOffsets());
			drawItem = camera.startQuadBatch(graphic, isColored, hasColorOffsets, blend, antialiasing, shader);
		}

		// Copy tile images into the tile buffer
		#if (flixel < "5.2.0")
		_point.x = (camera.scroll.x * scrollFactor.x) - x - offset.x + camera.viewOffsetX; // modified from getScreenPosition()
		_point.y = (camera.scroll.y * scrollFactor.y) - y - offset.y + camera.viewOffsetY;
		#else
		_point.x = (camera.scroll.x * scrollFactor.x) - x - offset.x + camera.viewMarginX; // modified from getScreenPosition()
		_point.y = (camera.scroll.y * scrollFactor.y) - y - offset.y + camera.viewMarginY;
		#end

		var screenXInTiles:Int = Math.floor(_point.x / scaledTileWidth);
		var screenYInTiles:Int = Math.floor(_point.y / scaledTileHeight);
		var screenRows:Int = buffer.rows;
		var screenColumns:Int = buffer.columns;

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
						special.paint(buffer.pixels, _flashPoint);
						buffer.dirty = (special.dirty || buffer.dirty);
					}
					else if (tile != null && tile.visible && tile.frame.type != FlxFrameType.EMPTY)
					{
						tile.frame.paint(buffer.pixels, _flashPoint, true);
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
							buffer.pixels.copyPixels(debugTile, _debugRect, _flashPoint, null, null, true);
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

						_matrix.identity();

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

						var scaleX:Float = scale.x;
						var scaleY:Float = scale.y;

						matrixToUse.scale(scaleX, scaleY);
						matrixToUse.translate(drawX, drawY);
						camera.drawPixels(frame, matrixToUse, colorTransform, blend);

						drawItem.addQuad(frame, matrixToUse, colorTransform);
					}
				}

				if (FlxG.renderBlit)
				{
					_flashPoint.x += tileWidth;
				}
				columnIndex++;
			}

			if (FlxG.renderBlit)
			{
				_flashPoint.y += tileHeight;
			}
			rowIndex += widthInTiles;
		}

		buffer.x = screenXInTiles * scaledTileWidth;
		buffer.y = screenYInTiles * scaledTileHeight;

		if (FlxG.renderBlit)
		{
			if (isColored)
				buffer.colorTransform(colorTransform);
			buffer.blend = blend;
		}

		buffer.dirty = false;
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

	#if (flixel < "5.9.0")
	/**
	 * THIS IS A COPY FROM FlxTilemap BUT IT SOLVES SLOPE COLLISION TOO
	 * Checks if the Object overlaps any tiles with any collision flags set,
	 * and calls the specified callback function (if there is one).
	 * Also calls the tile's registered callback if the filter matches.
	 *
	 * @param   object              The FlxObject you are checking for overlaps against.
	 * @param   callback            An optional function that takes the form "myCallback(Object1:FlxObject,Object2:FlxObject)", where Object1 is a FlxTile object, and Object2 is the object passed in in the first parameter of this method.
	 * @param   flipCallbackParams  Used to preserve A-B list ordering from FlxObject.separate() - returns the FlxTile object as the second parameter instead.
	 * @param   position            Optional, specify a custom position for the tilemap (useful for overlapsAt()-type functionality).
	 * @return  Whether there were overlaps, or if a callback was specified, whatever the return value of the callback was.
	 */
	override function overlapsWithCallback(object:FlxObject, ?callback:FlxObject->FlxObject->Bool, flipCallbackParams:Bool = false,
			?position:FlxPoint):Bool
	{
		var results:Bool = false;

		var xPos:Float = x;
		var yPos:Float = y;

		if (position != null)
		{
			xPos = position.x;
			yPos = position.y;
			position.putWeak();
		}
		
		inline function bindInt(value:Int, min:Int, max:Int)
		{
			return Std.int(FlxMath.bound(value, min, max));
		}

		// Figure out what tiles we need to check against, and bind them by the map edges
		final minTileX:Int = bindInt(Math.floor((object.x - xPos) / scaledTileWidth), 0, widthInTiles);
		final minTileY:Int = bindInt(Math.floor((object.y - yPos) / scaledTileHeight), 0, heightInTiles);
		final maxTileX:Int = bindInt(Math.ceil((object.x + object.width - xPos) / scaledTileWidth), 0, widthInTiles);
		final maxTileY:Int = bindInt(Math.ceil((object.y + object.height - yPos) / scaledTileHeight), 0, heightInTiles);

		// Cache tilemap movement
		final deltaX:Float = xPos - last.x;
		final deltaY:Float = yPos - last.y;

		// Loop through the range of tiles and call the callback on them, accordingly
		for (row in minTileY...maxTileY)
		{
			for (column in minTileX...maxTileX)
			{
				final mapIndex:Int = (row * widthInTiles) + column;
				final dataIndex:Int = _data[mapIndex];
				if (dataIndex < 0)
					continue;

				final tile = _tileObjects[dataIndex];
				if (tile.solid)
				{
					var overlapFound = false;

					tile.width = scaledTileWidth;
					tile.height = scaledTileHeight;
					tile.x = xPos + column * tile.width;
					tile.y = yPos + row * tile.height;
					tile.last.x = tile.x - deltaX;
					tile.last.y = tile.y - deltaY;

					if (callback != null)
					{
						if (flipCallbackParams)
						{
							overlapFound = callback(object, tile);
						}
						else
						{
							overlapFound = callback(tile, object);
						}
					}
					else
					{
						overlapFound
							=  (object.x + object.width > tile.x)
							&& (object.x < tile.x + tile.width)
							&& (object.y + object.height > tile.y)
							&& (object.y < tile.y + tile.height);
					}

					// New generalized slope collisions
					if (overlapFound || (!overlapFound && checkArrays(tile.index)))
					{
						if ((tile.callbackFunction != null) && ((tile.filter == null) || Std.isOfType(object, tile.filter)))
						{
							tile.mapIndex = mapIndex;
							tile.callbackFunction(tile, object);
						}
						results = true;
					}
				}
				else if ((tile.callbackFunction != null) && ((tile.filter == null) || Std.isOfType(object, tile.filter)))
				{
					tile.mapIndex = mapIndex;
					tile.callbackFunction(tile, object);
				}
			}
		}

		return results;
	}
	#else
	/**
	 * Hacky fix for `FlxTilemapExt`, with all the new changes to 5.9.0 it's better to perfectly
	 * recreate the old behavior, here and then make a new tilemap with slopes that uses the new
	 * features to eventually replace it
	 */
	override function objectOverlapsTiles<TObj:FlxObject>(object:TObj, ?callback:(FlxTile, TObj)->Bool, ?position:FlxPoint, isCollision = true):Bool
	{
		var results = false;
		function each(tile:FlxTile)
		{
			if (tile.solid)
			{
				var overlapFound = false;
				if (callback != null)
				{
					overlapFound = callback(tile, object);
				}
				else
				{
					overlapFound = tile.overlapsObject(object);
				}

				// New generalized slope collisions
				if (overlapFound || checkArrays(tile.index))
				{
					if (tile.callbackFunction != null)
					{
						tile.callbackFunction(tile, object);
						tile.onCollide.dispatch(tile, object);
					}
					results = true;
				}
			}
			else if ((tile.callbackFunction != null) && ((tile.filter == null) || Std.isOfType(object, tile.filter)))
			{
				tile.callbackFunction(tile, object);
				tile.onCollide.dispatch(tile, object);
			}
		}
		
		forEachOverlappingTile(object, each, position);
		
		return results;
	}
	#end

	/**
	 * Set glue to force contact with slopes and a slow down factor while climbing
	 *
	 * @param 	downwardsGlue  Activate/Deactivate glue on slopes
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
	 * @param 	northwest 	An array containing the numbers of the tiles facing northwest to be treated as floor tiles with a slope on the left.
	 * @param 	northeast	An array containing the numbers of the tiles facing northeast to be treated as floor tiles with a slope on the right.
	 * @param 	southwest	An array containing the numbers of the tiles facing southwest to be treated as ceiling tiles with a slope on the left.
	 * @param 	southeast	An array containing the numbers of the tiles facing southeast to be treated as ceiling tiles with a slope on the right.
	 */
	public function setSlopes(?northwest:Array<Int>, ?northeast:Array<Int>, ?southwest:Array<Int>, ?southeast:Array<Int>):Void
	{
		if (northwest != null)
		{
			_slopeNorthwest = northwest;
		}
		if (northeast != null)
		{
			_slopeNortheast = northeast;
		}
		if (southwest != null)
		{
			_slopeSouthwest = southwest;
		}
		if (southeast != null)
		{
			_slopeSoutheast = southeast;
		}
		setSlopeProperties();
	}

	/**
	 * Sets the gentle slopes. About 26.5 degrees.
	 *
	 * @param 	thickTiles 	An array containing the numbers of the tiles to be treated as thick slope.
	 * @param 	thinTiles	An array containing the numbers of the tiles to be treated as thin slope.
	 */
	public function setGentle(thickTiles:Array<Int>, thinTiles:Array<Int>)
	{
		if (thickTiles != null)
		{
			_slopeThickGentle = thickTiles;
		}

		if (thinTiles != null)
		{
			_slopeThinGentle = thinTiles;
			for (tile in _slopeThinGentle)
			{
				_tileObjects[tile].allowCollisions = (_slopeSouthwest.indexOf(tile) >= 0 || _slopeSoutheast.indexOf(tile) >= 0) ? CEILING : FLOOR;
			}
		}
	}

	/**
	 * Sets the steep slopes. About 63.5 degrees.
	 *
	 * @param 	thickTiles 	An array containing the numbers of the tiles to be treated as thick slope.
	 * @param 	thinTiles	An array containing the numbers of the tiles to be treated as thin slope.
	 */
	public function setSteep(thickTiles:Array<Int>, thinTiles:Array<Int>)
	{
		if (thickTiles != null)
		{
			_slopeThickSteep = thickTiles;
		}

		if (thinTiles != null)
		{
			_slopeThinSteep = thinTiles;
			for (tile in _slopeThinSteep)
			{
				_tileObjects[tile].allowCollisions = (_slopeSouthwest.indexOf(tile) >= 0 || _slopeNorthwest.indexOf(tile) >= 0) ? RIGHT : LEFT;
			}
		}
	}

	/**
	 * Internal helper functions for comparing a tile to the slope arrays to see if a tile should be treated as STEEP or GENTLE slope.
	 *
	 * @param 	tileIndex	The Tile Index number of the Tile you want to check.
	 * @return	True if the tile is listed in one of the slope arrays. Otherwise false.
	 */
	function checkThickGentle(tileIndex:Int):Bool
	{
		return _slopeThickGentle.indexOf(tileIndex) >= 0;
	}

	function checkThinGentle(tileIndex:Int):Bool
	{
		return _slopeThinGentle.indexOf(tileIndex) >= 0;
	}

	function checkThickSteep(tileIndex:Int):Bool
	{
		return _slopeThickSteep.indexOf(tileIndex) >= 0;
	}

	function checkThinSteep(tileIndex:Int):Bool
	{
		return _slopeThinSteep.indexOf(tileIndex) >= 0;
	}

	/**
	 * Bounds the slope point to the slope
	 *
	 * @param 	slope 	The slope to fix the slopePoint for
	 */
	function fixSlopePoint(slope:FlxTile):Void
	{
		_slopePoint.x = FlxMath.bound(_slopePoint.x, slope.x, slope.x + scaledTileWidth);
		_slopePoint.y = FlxMath.bound(_slopePoint.y, slope.y, slope.y + scaledTileHeight);
	}

	/**
	 * Is called if an object collides with a floor slope
	 *
	 * @param 	slope	The floor slope
	 * @param	object 	The object that collides with that slope
	 */
	function onCollideFloorSlope(slope:FlxObject, object:FlxObject):Void
	{
		// Set the object's touching flag
		object.touching = FLOOR;

		// Adjust the object's velocity
		if (_downwardsGlue)
			object.velocity.y = _velocityYDownSlope;
		else
			object.velocity.y = Math.min(object.velocity.y, 0);

		// Reposition the object
		object.y = _slopePoint.y - object.height;

		if (object.y < slope.y - object.height)
		{
			object.y = slope.y - object.height;
		}
	}

	/**
	 * Is called if an object collides with a ceiling slope
	 *
	 * @param 	slope 	The ceiling slope
	 * @param 	object 	The object that collides with that slope
	 */
	function onCollideCeilSlope(slope:FlxObject, object:FlxObject):Void
	{
		// Set the object's touching flag
		object.touching = CEILING;

		// Adjust the object's velocity
		object.velocity.y = Math.max(object.velocity.y, 0);

		// Reposition the object
		object.y = _slopePoint.y;

		if (object.y > slope.y + scaledTileHeight)
		{
			object.y = slope.y + scaledTileHeight;
		}
	}

	/**
	 * Solves collision against a left-sided floor slope
	 *
	 * @param 	slope 	The slope to check against
	 * @param 	object 	The object that collides with the slope
	 */
	function solveCollisionSlopeNorthwest(slope:FlxObject, object:FlxObject):Void
	{
		if (object.x + object.width > slope.x + slope.width + _snapping)
		{
			return;
		}
		// Calculate the corner point of the object
		_objPoint.x = Math.floor(object.x + object.width + _snapping);
		_objPoint.y = Math.floor(object.y + object.height);

		// Calculate position of the point on the slope that the object might overlap
		// this would be one side of the object projected onto the slope's surface
		_slopePoint.x = _objPoint.x;
		_slopePoint.y = (slope.y + scaledTileHeight) - (_slopePoint.x - slope.x);

		var tileId:Int = cast(slope, FlxTile).index;
		if (checkThinSteep(tileId))
		{
			if (_slopePoint.x - slope.x <= scaledTileWidth / 2)
			{
				return;
			}
			else
			{
				_slopePoint.y = slope.y + scaledTileHeight * (2 - (2 * (_slopePoint.x - slope.x) / scaledTileWidth)) + _snapping;
				if (_downwardsGlue && object.velocity.x > 0)
					object.velocity.x *= 1 - (1 - _slopeSlowDownFactor) * 3;
			}
		}
		else if (checkThickSteep(tileId))
		{
			_slopePoint.y = slope.y + scaledTileHeight * (1 - (2 * ((_slopePoint.x - slope.x) / scaledTileWidth))) + _snapping;
			if (_downwardsGlue && object.velocity.x > 0)
				object.velocity.x *= 1 - (1 - _slopeSlowDownFactor) * 3;
		}
		else if (checkThickGentle(tileId))
		{
			_slopePoint.y = slope.y + (scaledTileHeight - _slopePoint.x + slope.x) / 2;
			if (_downwardsGlue && object.velocity.x > 0)
				object.velocity.x *= _slopeSlowDownFactor;
		}
		else if (checkThinGentle(tileId))
		{
			_slopePoint.y = slope.y + scaledTileHeight - (_slopePoint.x - slope.x) / 2;
			if (_downwardsGlue && object.velocity.x > 0)
				object.velocity.x *= _slopeSlowDownFactor;
		}
		else
		{
			if (_downwardsGlue && object.velocity.x > 0)
				object.velocity.x *= _slopeSlowDownFactor;
		}
		// Fix the slope point to the slope tile
		fixSlopePoint(cast(slope, FlxTile));

		// Check if the object is inside the slope
		if (_objPoint.x > slope.x + _snapping
			&& _objPoint.x < slope.x + scaledTileWidth + object.width + _snapping
			&& _objPoint.y >= _slopePoint.y
			&& _objPoint.y <= slope.y + scaledTileHeight)
		{
			// Call the collide function for the floor slope
			onCollideFloorSlope(slope, object);
		}
	}

	/**
	 * Solves collision against a right-sided floor slope
	 *
	 * @param 	slope 	The slope to check against
	 * @param 	object 	The object that collides with the slope
	 */
	function solveCollisionSlopeNortheast(slope:FlxObject, object:FlxObject):Void
	{
		if (object.x < slope.x - _snapping)
		{
			return;
		}
		// Calculate the corner point of the object
		_objPoint.x = Math.floor(object.x - _snapping);
		_objPoint.y = Math.floor(object.y + object.height);

		// Calculate position of the point on the slope that the object might overlap
		// this would be one side of the object projected onto the slope's surface
		_slopePoint.x = _objPoint.x;
		_slopePoint.y = (slope.y + scaledTileHeight) - (slope.x - _slopePoint.x + scaledTileWidth);

		var tileId:Int = cast(slope, FlxTile).index;
		if (checkThinSteep(tileId))
		{
			if (_slopePoint.x - slope.x >= scaledTileWidth / 2)
			{
				return;
			}
			else
			{
				_slopePoint.y = slope.y + scaledTileHeight * 2 * ((_slopePoint.x - slope.x) / scaledTileWidth) + _snapping;
			}
			if (_downwardsGlue && object.velocity.x < 0)
				object.velocity.x *= 1 - (1 - _slopeSlowDownFactor) * 3;
		}
		else if (checkThickSteep(tileId))
		{
			_slopePoint.y = slope.y - scaledTileHeight * (1 + (2 * ((slope.x - _slopePoint.x) / scaledTileWidth))) + _snapping;
			if (_downwardsGlue && object.velocity.x < 0)
				object.velocity.x *= 1 - (1 - _slopeSlowDownFactor) * 3;
		}
		else if (checkThickGentle(tileId))
		{
			_slopePoint.y = slope.y + (scaledTileHeight - slope.x + _slopePoint.x - scaledTileWidth) / 2;
			if (_downwardsGlue && object.velocity.x < 0)
				object.velocity.x *= _slopeSlowDownFactor;
		}
		else if (checkThinGentle(tileId))
		{
			_slopePoint.y = slope.y + scaledTileHeight - (slope.x - _slopePoint.x + scaledTileWidth) / 2;
			if (_downwardsGlue && object.velocity.x < 0)
				object.velocity.x *= _slopeSlowDownFactor;
		}
		else
		{
			if (_downwardsGlue && object.velocity.x < 0)
				object.velocity.x *= _slopeSlowDownFactor;
		}
		// Fix the slope point to the slope tile
		fixSlopePoint(cast(slope, FlxTile));

		// Check if the object is inside the slope
		if (_objPoint.x > slope.x - object.width - _snapping
			&& _objPoint.x < slope.x + scaledTileWidth + _snapping
			&& _objPoint.y >= _slopePoint.y
			&& _objPoint.y <= slope.y + scaledTileHeight)
		{
			// Call the collide function for the floor slope
			onCollideFloorSlope(slope, object);
		}
	}

	/**
	 * Solves collision against a left-sided ceiling slope
	 *
	 * @param 	slope 	The slope to check against
	 * @param 	object 	The object that collides with the slope
	 */
	function solveCollisionSlopeSouthwest(slope:FlxObject, object:FlxObject):Void
	{
		// Calculate the corner point of the object
		_objPoint.x = Math.floor(object.x + object.width + _snapping);
		_objPoint.y = Math.ceil(object.y);

		// Calculate position of the point on the slope that the object might overlap
		// this would be one side of the object projected onto the slope's surface
		_slopePoint.x = _objPoint.x;
		_slopePoint.y = slope.y + (_slopePoint.x - slope.x);

		var tileId:Int = cast(slope, FlxTile).index;
		if (checkThinSteep(tileId))
		{
			if (_slopePoint.x - slope.x <= scaledTileWidth / 2)
			{
				return;
			}
			else
			{
				_slopePoint.y = slope.y - scaledTileHeight * (1 + (2 * ((slope.x - _slopePoint.x) / scaledTileWidth))) - _snapping;
			}
		}
		else if (checkThickSteep(tileId))
		{
			_slopePoint.y = slope.y + scaledTileHeight * 2 * ((_slopePoint.x - slope.x) / scaledTileWidth) - _snapping;
		}
		else if (checkThickGentle(tileId))
		{
			_slopePoint.y = slope.y + scaledTileHeight - (slope.x - _slopePoint.x + scaledTileWidth) / 2;
		}
		else if (checkThinGentle(tileId))
		{
			_slopePoint.y = slope.y + (scaledTileHeight - slope.x + _slopePoint.x - scaledTileWidth) / 2;
		}

		// Fix the slope point to the slope tile
		fixSlopePoint(cast(slope, FlxTile));

		// Check if the object is inside the slope
		if (_objPoint.x > slope.x + _snapping
			&& _objPoint.x < slope.x + scaledTileWidth + object.width + _snapping
			&& _objPoint.y <= _slopePoint.y
			&& _objPoint.y >= slope.y)
		{
			// Call the collide function for the floor slope
			onCollideCeilSlope(slope, object);
		}
	}

	/**
	 * Solves collision against a right-sided ceiling slope
	 *
	 * @param 	slope 	The slope to check against
	 * @param 	object 	The object that collides with the slope
	 */
	function solveCollisionSlopeSoutheast(slope:FlxObject, object:FlxObject):Void
	{
		// Calculate the corner point of the object
		_objPoint.x = Math.floor(object.x - _snapping);
		_objPoint.y = Math.ceil(object.y);

		// Calculate position of the point on the slope that the object might overlap
		// this would be one side of the object projected onto the slope's surface
		_slopePoint.x = _objPoint.x;
		_slopePoint.y = (slope.y) + (slope.x - _slopePoint.x + scaledTileWidth);

		var tileId:Int = cast(slope, FlxTile).index;
		if (checkThinSteep(tileId))
		{
			if (_slopePoint.x - slope.x >= scaledTileWidth / 2)
			{
				return;
			}
			else
			{
				_slopePoint.y = slope.y + scaledTileHeight * (1 - (2 * ((_slopePoint.x - slope.x) / scaledTileWidth))) - _snapping;
			}
		}
		else if (checkThickSteep(tileId))
		{
			_slopePoint.y = slope.y + scaledTileHeight * (2 - (2 * (_slopePoint.x - slope.x) / scaledTileWidth)) - _snapping;
		}
		else if (checkThickGentle(tileId))
		{
			_slopePoint.y = slope.y + scaledTileHeight - (_slopePoint.x - slope.x) / 2;
		}
		else if (checkThinGentle(tileId))
		{
			_slopePoint.y = slope.y + (scaledTileHeight - _slopePoint.x + slope.x) / 2;
		}

		// Fix the slope point to the slope tile
		fixSlopePoint(cast(slope, FlxTile));

		// Check if the object is inside the slope
		if (_objPoint.x > slope.x - object.width - _snapping
			&& _objPoint.x < slope.x + scaledTileWidth + _snapping
			&& _objPoint.y <= _slopePoint.y
			&& _objPoint.y >= slope.y)
		{
			// Call the collide function for the floor slope
			onCollideCeilSlope(slope, object);
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
	 * @param 	tileIndex	The Tile Index number of the Tile you want to check.
	 * @return	True if the tile is listed in one of the slope arrays. Otherwise false.
	 */
	function checkArrays(tileIndex:Int):Bool
	{
		return _slopeNorthwest.indexOf(tileIndex) >= 0
			|| _slopeNortheast.indexOf(tileIndex) >= 0
			|| _slopeSouthwest.indexOf(tileIndex) >= 0
			|| _slopeSoutheast.indexOf(tileIndex) >= 0;
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
