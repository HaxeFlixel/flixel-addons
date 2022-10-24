
/**
 * Used for showing infinitely scrolling backgrounds.
 * @author George Kurelic (Original concept by Chevy Ray)
 */
class FlxBackdrop extends FlxSprite
{
	public var repeatAxes:FlxAxes = XY;
	public var spacing(default, null):FlxPoint = new FlxPoint();
	public var tiles:Int = 1;
	
	/**
	 * Creates an instance of the FlxBackdrop class, used to create infinitely scrolling backgrounds.
	 *
	 * @param   graphic     The image you want to use for the backdrop.
	 * @param   repeatAxes  If the backdrop should repeat on the X axis.
	 * @param   spaceX      Amount of spacing between tiles on the X axis
	 * @param   spaceY      Amount of spacing between tiles on the Y axis
	 */
	public function new(x = 0.0, y = 0.0, ?graphic:FlxGraphicAsset, repeatAxes:FlxAxes = XY, spacingX = 0.0, spacingY = 0.0)
	{
		super(x, y, graphic);
		
		this.repeatAxes = repeatAxes;
		this.spacing.set(spacingX, spacingY);
	}

	override function destroy():Void
	{
		spacing = FlxDestroyUtil.destroy(spacing);
		super.destroy();
	}
	
	override function draw()
	{
		checkEmptyFrame();

		if (alpha == 0 || _frame.type == FlxFrameType.EMPTY)
			return;

		if (scale.x <= 0 || scale.y <= 0)
			return;

		if (dirty) // rarely
			calcFrame(useFramePixels);

		if (drawIntermediary)
		{
			drawToLargestCamera();
		}
		
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
				continue;

			if (isSimpleRender(camera))
				drawSimple(camera);
			else
				drawComplex(camera);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}

	override function isOnScreen(?camera:FlxCamera):Bool
	{
		if (repeatAxes == XY)
			return true;
		
		if (repeatAxes == NONE)
			return super.isOnScreen(camera);
		
		if (camera == null)
			camera = FlxG.camera;
		
		var bounds = getScreenBounds(_rect, camera);
		var view = camera.getViewRect();
		if (repeatAxes == X) bounds.x = view.x;
		if (repeatAxes == Y) bounds.y = view.y;
		view.put();
		
		return camera.containsRect(bounds);
	}
	
	function drawToLargestCamera()
	{
		var largest:FlxCamera = null;
		var largestArea = 0.0;
		var view = FlxRect.get();
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
				continue;
			
			camera.getViewRect(view);
			if (view.width * view.height > largestArea)
			{
				largest = camera;
				largestArea = view.width * view.height;
			}
		}
		view.put();
		
		if (largest != null)
			regenGraphic(largest);
	}
	
	override function isSimpleRenderBlit(?camera:FlxCamera):Bool
	{
		return (super.isSimpleRenderBlit(camera) || drawIntermediary)
			&& (camera != null ? isPixelPerfectRender(camera) : pixelPerfectRender);
	}
	
	override function drawSimple(camera:FlxCamera):Void
	{
		var drawDirect = !drawIntermediary;
		final graphic = drawIntermediary ? _blitGraphic : this.graphic;
		final frame = drawIntermediary ? _blitGraphic.imageFrame.frame : _frame;
		
		// The distance between repeated sprites, in screen space
		var tileSize = FlxPoint.get(frame.frame.width, frame.frame.height);
		if (drawDirect)
			tileSize.addPoint(spacing);
		
		FlxG.watch.addQuick("tileSize", tileSize);
		getScreenPosition(_point, camera);
		_point.subtractPoint(offset);
		var tilesX = 1;
		var tilesY = 1;
		if (repeatAxes != NONE)
		{
			var originalTileSize = tileSize;
			if (drawIntermediary)
			{
				originalTileSize = FlxPoint.weak(frameWidth + spacing.x, frameHeight + spacing.y);
			}
			var view = camera.getViewRect();
			if (repeatAxes.x)
			{
				final left  = modMin(_point.x + frame.frame.width, tileSize.x, view.left) - frame.frame.width;
				final right = modMax(_point.x, tileSize.x, view.right) + tileSize.x;
				tilesX = Math.round((right - left) / tileSize.x);
				_point.x = modMin(_point.x + frameWidth, frameWidth + spacing.x, view.left) - frameWidth;
				FlxG.watch.addQuick("right-left", '($right - $left) / ${tileSize.x} = ${Math.round((right - left) / tileSize.x)}');
			}
			
			if (repeatAxes.y)
			{
				final top    = modMin(_point.y + frame.frame.height, tileSize.y, view.top) - frame.frame.height;
				final bottom = modMax(_point.y, tileSize.y, view.bottom) + tileSize.y;
				tilesY = Math.round((bottom - top) / tileSize.y);
				_point.y = modMin(_point.x + frameHeight, frameHeight + spacing.y, view.top) - frameHeight;
				FlxG.watch.addQuick("bottom-top", '($bottom - $top) / ${tileSize.y} = ${Math.round((bottom - top) / tileSize.y)}');
			}
		}
		FlxG.watch.addQuick("tiles", '$tilesX x $tilesY');
		
		if (FlxG.renderBlit)
			calcFrame(true);
		
		camera.buffer.lock();
		
		for (tileX in 0...tilesX)
		{
			for (tileY in 0...tilesY)
			{
				// _point.copyToFlash(_flashPoint);
				_flashPoint.setTo(_point.x + tileSize.x * tileX, _point.y + tileSize.y * tileY);
				
				if (isPixelPerfectRender(camera))
				{
					_flashPoint.x = Math.floor(_flashPoint.x);
					_flashPoint.y = Math.floor(_flashPoint.y);
				}
				
				final pixels = drawIntermediary ? _blitGraphic.bitmap: framePixels;
				camera.copyPixels(frame, pixels, pixels.rect, _flashPoint, colorTransform, blend, antialiasing);
			}
		}
		
		camera.buffer.unlock();
	}

	override function drawComplex(camera:FlxCamera)
	{
		var drawDirect = !drawIntermediary;
		final graphic = drawIntermediary ? _blitGraphic : this.graphic;
		final frame = drawIntermediary ? _blitGraphic.imageFrame.frame : _frame;
		
		frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		
		// The distance between repeated sprites, in screen space
		var tileSize = FlxPoint.get(frame.frame.width, frame.frame.height);
		
		if (drawDirect)
		{
			tileSize.set
			(
				(frame.frame.width  + spacing.x) * scale.x,
				(frame.frame.height + spacing.y) * scale.y
			);
			
			_matrix.scale(scale.x, scale.y);

			if (bakedRotationAngle <= 0)
			{
				updateTrig();

				if (angle != 0)
					_matrix.rotateWithTrig(_cosAngle, _sinAngle);
			}
		}
		
		var drawItem = null;
		if (FlxG.renderTile)
		{
			var isColored:Bool = (alpha != 1) || (color != 0xffffff);
			var hasColorOffsets:Bool = (colorTransform != null && colorTransform.hasRGBAOffsets());
			drawItem = camera.startQuadBatch(graphic, isColored, hasColorOffsets, blend, antialiasing, shader);
		}
		else
		{
			camera.buffer.lock();
		}
		
		getScreenPosition(_point, camera);
		var tilesX = 1;
		var tilesY = 1;
		if (repeatAxes != NONE)
		{
			var originalTileSize = tileSize;
			if (drawIntermediary)
			{
				originalTileSize = FlxPoint.weak(frameWidth + spacing.x, frameHeight + spacing.y);
			}
			final view = camera.getViewRect();
			final bounds = getScreenBounds(camera);
			if (repeatAxes.x)
			{
				final left  = modMin(bounds.right, originalTileSize.x, view.left) - bounds.width;
				final right = modMax(bounds.left, originalTileSize.x, view.right) + originalTileSize.x;
				tilesX = Math.round((right - left) / tileSize.x);
				_point.x = left + _point.x - bounds.x;
			}
			
			if (repeatAxes.y)
			{
				final top    = modMin(bounds.bottom, originalTileSize.y, view.top) - bounds.height;
				final bottom = modMax(bounds.top, originalTileSize.y, view.bottom) + originalTileSize.y;
				tilesY = Math.round((bottom - top) / tileSize.y);
				_point.y = top + _point.y - bounds.y;
			}
			view.put();
			bounds.put();
			originalTileSize.putWeak();
		}
		_point.subtractPoint(offset);
		_point.add(origin.x, origin.y);
		
		FlxG.watch.addQuick("tiles", '$tilesX x $tilesY');
		
		final mat = new FlxMatrix();
		for (tileX in 0...tilesX)
		{
			for (tileY in 0...tilesY)
			{
				mat.copyFrom(_matrix);
				
				mat.translate(_point.x + (tileSize.x * tileX), _point.y + (tileSize.y * tileY));
				
				if (isPixelPerfectRender(camera))
				{
					mat.tx = Math.floor(mat.tx);
					mat.ty = Math.floor(mat.ty);
				}
				
				if (FlxG.renderBlit)
				{
					final pixels = drawIntermediary ? _blitGraphic.bitmap: framePixels;
					camera.drawPixels(frame, pixels, mat, colorTransform, blend, antialiasing, shader);
				}
				else
				{
					drawItem.addQuad(frame, mat, colorTransform);
				}
			}
		}
		
		if (FlxG.renderBlit)
			camera.buffer.unlock();
	}
	
	function getFrameScreenBounds(camera:FlxCamera):FlxRect
	{
		if (drawIntermediary)
		{
			final frame = _blitGraphic.imageFrame.frame.frame;
			return FlxRect.get(x, y, frame.width, frame.height);
		}
		
		final newRect = FlxRect.get(x, y);
		
		if (pixelPerfectPosition)
			newRect.floor();
		final scaledOrigin = FlxPoint.weak(origin.x * scale.x, origin.y * scale.y);
		newRect.x += -Std.int(camera.scroll.x * scrollFactor.x) - offset.x + origin.x - scaledOrigin.x;
		newRect.y += -Std.int(camera.scroll.y * scrollFactor.y) - offset.y + origin.y - scaledOrigin.y;
		if (isPixelPerfectRender(camera))
			newRect.floor();
		newRect.setSize(frameWidth * Math.abs(scale.x), frameHeight * Math.abs(scale.y));
		return newRect.getRotatedBounds(angle, scaledOrigin, newRect);
	}
	
	function modMin(value:Float, step:Float, min:Float)
	{
		return value - Math.floor((value - min) / step) * step;
	}
	
	function modMax(value:Float, step:Float, max:Float)
	{
		return value - Math.ceil((value - max) / step) * step;
	}
	
	public var drawIntermediary:Bool;
	
	var _blitGraphic:FlxGraphic = null;
	var _prevDrawParams:BackdropDrawParams =
	{
		graphicKey:null,
		tilesX:-1,
		tilesY:-1,
		scaleX:0.0,
		scaleY:0.0,
		spacingX:0.0,
		spacingY:0.0,
		angle:0.0
	};
	
	function regenGraphic(camera:FlxCamera)
	{
		// The distance between repeated sprites, in screen space
		var tileSize = FlxPoint.get(
			(frameWidth  + spacing.x) * scale.x,
			(frameHeight + spacing.y) * scale.y
		);
		
		var view = camera.getViewRect();
		var tilesX = repeatAxes.x ? Math.ceil(view.width  / tileSize.x / tiles + 1) : 1;
		var tilesY = repeatAxes.y ? Math.ceil(view.height / tileSize.y / tiles + 1) : 1;
			
		view.put();
		
		if (matchPrevDrawParams(tilesX, tilesY))
		{
			tileSize.put();
			return;
		}
		setDrawParams(tilesX, tilesY);
		
		var graphicSizeX = Math.ceil(tilesX * tileSize.x);
		var graphicSizeY = Math.ceil(tilesY * tileSize.y);
		if (_blitGraphic == null || (_blitGraphic.width != graphicSizeX || _blitGraphic.height != graphicSizeY))
		{
			_blitGraphic = FlxG.bitmap.create(graphicSizeX, graphicSizeY, 0x0, true);
		}
		
		var pixels = _blitGraphic.bitmap;
		pixels.lock();
		
		pixels.fillRect(pixels.rect, FlxColor.TRANSPARENT);
		animation.frameIndex = 0;
		calcFrame(true);
		
		_matrix.identity();
		// _matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);
		if (bakedRotationAngle <= 0)
		{
			updateTrig();
			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}
		_point.set(_matrix.tx, _matrix.ty);
		
		FlxG.watch.addQuick("regenTiles", '$tilesX x $tilesY');
		
		for (tileX in 0...tilesX)
		{
			for (tileY in 0...tilesY)
			{
				_matrix.tx = _point.x + tileX * tileSize.x;
				_matrix.ty = _point.y + tileY * tileSize.y;
				pixels.draw(framePixels, _matrix);
			}
		}
		
		pixels.unlock();
		
		tileSize.put();
	}
	
	inline function matchPrevDrawParams(tilesX:Int, tilesY:Int)
	{
		return _prevDrawParams.graphicKey == graphic.key
			&& _prevDrawParams.tilesX     == tilesX
			&& _prevDrawParams.tilesY     == tilesY
			&& _prevDrawParams.scaleX     == scale.x
			&& _prevDrawParams.scaleY     == scale.y
			&& _prevDrawParams.spacingX   == spacing.x
			&& _prevDrawParams.spacingY   == spacing.y
			&& _prevDrawParams.angle      == angle;
	}
	
	inline function setDrawParams(tilesX:Int, tilesY:Int)
	{
		_prevDrawParams.graphicKey = graphic.key;
		_prevDrawParams.tilesX     = tilesX;
		_prevDrawParams.tilesY     = tilesY;
		_prevDrawParams.scaleX     = scale.x;
		_prevDrawParams.scaleY     = scale.y;
		_prevDrawParams.spacingX   = spacing.x;
		_prevDrawParams.spacingY   = spacing.y;
		_prevDrawParams.angle      = angle;
	}
}