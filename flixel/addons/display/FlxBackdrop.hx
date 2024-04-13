package flixel.addons.display;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

using flixel.util.FlxColorTransformUtil;

/**
 * Used for showing infinitely scrolling backgrounds.
 * @author George Kurelic (Original concept by Chevy Ray)
 */
class FlxBackdrop extends FlxSprite
{
	/**
	 * The axes to repeat the backdrop, defaults to XY which covers the whole camera.
	 */
	public var repeatAxes:FlxAxes = XY;
	
	/**
	 * The gap between repeated tiles, defaults to (0, 0), or no gap.
	 */
	public var spacing(default, null):FlxPoint = FlxPoint.get();
	
	/**
	 * If true, tiles are pre-rendered to a intermediary bitmap whenever `loadGraphic` is called
	 * or the following properties are changed: camera size camera zoom, `scale.x`, `scale.y`,
	 * `spacing.x`, `spacing.y`, `repeatAxes` or `angle`. If these properties change often, it is recommended to
	 * set `drawBlit` to `false`.
	 * 
	 * Note: blitting will disable animations and only show the first frame.
	 */
	public var drawBlit:Bool = FlxG.renderBlit;
	
	/**
	 * Decides the the size of the blit graphic. Leave as `AUTO` unless you know what you're doing.
	 * 
	 * @see flixel.addons.display.FlxBackDrop.BackdropBlitMode
	 */
	public var blitMode:BackdropBlitMode = AUTO;
	
	var _blitOffset:FlxPoint = FlxPoint.get();
	var _blitGraphic:FlxGraphic = null;
	var _tileMatrix:FlxMatrix = new FlxMatrix();
	var _prevDrawParams:BackdropDrawParams =
	{
		graphicKey:null,
		tilesX:-1,
		tilesY:-1,
		scaleX:0.0,
		scaleY:0.0,
		spacingX:0.0,
		spacingY:0.0,
		repeatAxes:XY,
		angle:0.0
	};
	
	/**
	 * Creates an instance of the FlxBackdrop class, used to create infinitely scrolling backgrounds.
	 *
	 * @param   graphic     The image you want to use for the backdrop.
	 * @param   repeatAxes  The axes on which to repeat. The default, `XY` will tile the entire camera.
	 * @param   spacingX    Amount of spacing between tiles on the X axis
	 * @param   spacingY    Amount of spacing between tiles on the Y axis
	 */
	public function new(?graphic:FlxGraphicAsset, repeatAxes = XY, spacingX = 0.0, spacingY = 0.0)
	{
		super(0, 0, graphic);
		
		this.repeatAxes = repeatAxes;
		this.spacing.set(spacingX, spacingY);
	}

	override function destroy():Void
	{
		spacing = FlxDestroyUtil.put(spacing);
		_blitOffset = FlxDestroyUtil.put(_blitOffset);
		_blitGraphic = FlxDestroyUtil.destroy(_blitGraphic);
		_tileMatrix = null;
		
		super.destroy();
	}
	
	override function draw()
	{
		if (repeatAxes == NONE)
		{
			super.draw();
			return;
		}
		
		checkEmptyFrame();

		if (alpha == 0 || _frame.type == FlxFrameType.EMPTY)
			return;

		if (scale.x <= 0 || scale.y <= 0)
			return;

		if (dirty) // rarely
			calcFrame(useFramePixels);

		if (drawBlit)
		{
			drawToLargestCamera();
		}
		
		#if (flixel >= "5.7.0")
		final cameras = getCamerasLegacy();
		#end
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
		if (repeatAxes.x) bounds.x = camera.viewMarginLeft;
		if (repeatAxes.y) bounds.y = camera.viewMarginTop;
		
		return camera.containsRect(bounds);
	}
	
	function drawToLargestCamera()
	{
		var largest:FlxCamera = null;
		var largestArea = 0.0;
		#if (flixel >= "5.7.0")
		final cameras = getCamerasLegacy(); // else use this.cameras
		#end
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
				continue;
			
			if (camera.viewWidth * camera.viewHeight > largestArea)
			{
				largest = camera;
				largestArea = camera.viewWidth * camera.viewHeight;
			}
		}
		
		if (largest != null)
			regenGraphic(largest);
	}
	
	override function isSimpleRenderBlit(?camera:FlxCamera):Bool
	{
		if (repeatAxes == NONE)
			return super.isSimpleRenderBlit(camera);
		
		return (super.isSimpleRenderBlit(camera) || drawBlit)
			&& (camera != null ? isPixelPerfectRender(camera) : pixelPerfectRender);
	}
	
	override function drawSimple(camera:FlxCamera):Void
	{
		if (repeatAxes == NONE)
		{
			super.drawSimple(camera);
			return;
		}
		
		var drawDirect = !drawBlit;
		final graphic = drawBlit ? _blitGraphic : this.graphic;
		final frame = drawBlit ? _blitGraphic.imageFrame.frame : _frame;
		
		// The distance between repeated sprites, in screen space
		final tileSize = FlxPoint.get(frame.frame.width, frame.frame.height);
		if (drawDirect)
			tileSize.addPoint(spacing);
		
		getScreenPosition(_point, camera).subtractPoint(offset);
		var tilesX = 1;
		var tilesY = 1;
		if (repeatAxes != NONE)
		{
			final viewMargins = camera.getViewMarginRect();
			if (repeatAxes.x)
			{
				final left  = modMin(_point.x + frameWidth, tileSize.x, viewMargins.left) - frameWidth;
				final right = modMax(_point.x, tileSize.x, viewMargins.right) + tileSize.x;
				tilesX = Math.round((right - left) / tileSize.x);
				final origTileSizeX = frameWidth + spacing.x;
				_point.x = modMin(_point.x + frameWidth, origTileSizeX, viewMargins.left) - frameWidth;
			}
			
			if (repeatAxes.y)
			{
				final top    = modMin(_point.y + frameHeight, tileSize.y, viewMargins.top) - frameHeight;
				final bottom = modMax(_point.y, tileSize.y, viewMargins.bottom) + tileSize.y;
				tilesY = Math.round((bottom - top) / tileSize.y);
				final origTileSizeY = frameHeight + spacing.y;
				_point.y = modMin(_point.y + frameHeight, origTileSizeY, viewMargins.top) - frameHeight;
			}
			viewMargins.put();
		}
		
		if (drawBlit)
			_point.addPoint(_blitOffset);
		
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
				
				final pixels = drawBlit ? _blitGraphic.bitmap: framePixels;
				camera.copyPixels(frame, pixels, pixels.rect, _flashPoint, colorTransform, blend, antialiasing);
			}
		}
		
		tileSize.put();
		camera.buffer.unlock();
	}

	override function drawComplex(camera:FlxCamera)
	{
		if (repeatAxes == NONE)
		{
			super.drawComplex(camera);
			return;
		}
		
		var drawDirect = !drawBlit;
		final graphic = drawBlit ? _blitGraphic : this.graphic;
		final frame = drawBlit ? _blitGraphic.imageFrame.frame : _frame;
		
		frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		
		// The distance between repeated sprites, in screen space
		final tileSize = FlxPoint.get(frame.frame.width, frame.frame.height);
		
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
		
		getScreenPosition(_point, camera).subtractPoint(offset);
		var tilesX = 1;
		var tilesY = 1;
		if (repeatAxes != NONE)
		{
			final viewMargins = camera.getViewMarginRect();
			final bounds = getScreenBounds(camera);
			if (repeatAxes.x)
			{
				final origTileSizeX = (frameWidth + spacing.x) * scale.x;
				final left  = modMin(bounds.right, origTileSizeX, viewMargins.left) - bounds.width;
				final right = modMax(bounds.left, origTileSizeX, viewMargins.right) + origTileSizeX;
				tilesX = Math.round((right - left) / tileSize.x);
				_point.x = left + _point.x - bounds.x;
			}
			
			if (repeatAxes.y)
			{
				final origTileSizeY = (frameHeight + spacing.y) * scale.y;
				final top    = modMin(bounds.bottom, origTileSizeY, viewMargins.top) - bounds.height;
				final bottom = modMax(bounds.top, origTileSizeY, viewMargins.bottom) + origTileSizeY;
				tilesY = Math.round((bottom - top) / tileSize.y);
				_point.y = top + _point.y - bounds.y;
			}
			viewMargins.put();
			bounds.put();
		}
		_point.addPoint(origin);
		if (drawBlit)
			_point.addPoint(_blitOffset);
		
		for (tileX in 0...tilesX)
		{
			for (tileY in 0...tilesY)
			{
				_tileMatrix.copyFrom(_matrix);
				
				_tileMatrix.translate(_point.x + (tileSize.x * tileX), _point.y + (tileSize.y * tileY));
				
				if (isPixelPerfectRender(camera))
				{
					_tileMatrix.tx = Math.floor(_tileMatrix.tx);
					_tileMatrix.ty = Math.floor(_tileMatrix.ty);
				}
				
				if (FlxG.renderBlit)
				{
					final pixels = drawBlit ? _blitGraphic.bitmap: framePixels;
					camera.drawPixels(frame, pixels, _tileMatrix, colorTransform, blend, antialiasing, shader);
				}
				else
				{
					drawItem.addQuad(frame, _tileMatrix, colorTransform);
				}
			}
		}
		
		tileSize.put();
		if (FlxG.renderBlit)
			camera.buffer.unlock();
	}
	
	function getFrameScreenBounds(camera:FlxCamera):FlxRect
	{
		if (drawBlit)
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
	
	function regenGraphic(camera:FlxCamera)
	{
		// The distance between repeated sprites, in screen space
		var tileSize = FlxPoint.get(
			(frameWidth  + spacing.x) * scale.x,
			(frameHeight + spacing.y) * scale.y
		);
		
		final viewMargins = camera.getViewMarginRect();
		var tilesX = 1;
		var tilesY = 1;
		if (repeatAxes != NONE)
		{
			inline function min (a:Int, b:Int):Int return a < b ? a : b;
			switch (blitMode)
			{
				case AUTO | SPLIT (1):
					if (repeatAxes.x) tilesX = Math.ceil(viewMargins.width  / tileSize.x) + 1;
					if (repeatAxes.y) tilesY = Math.ceil(viewMargins.height / tileSize.y) + 1;
				case MAX_TILES(1) | MAX_TILES_XY(1, 1):
				case MAX_TILES(max):
					if (repeatAxes.x) tilesX = min(max, Math.ceil(viewMargins.width  / tileSize.x) + 1);
					if (repeatAxes.y) tilesY = min(max, Math.ceil(viewMargins.height / tileSize.y) + 1);
				case MAX_TILES_XY(maxX, maxY):
					if (repeatAxes.x) tilesX = min(maxX, Math.ceil(viewMargins.width  / tileSize.x) + 1);
					if (repeatAxes.y) tilesY = min(maxY, Math.ceil(viewMargins.height / tileSize.y) + 1);
				case SPLIT(portions):
					if (repeatAxes.x) tilesX = repeatAxes.x ? Math.ceil(viewMargins.width  / tileSize.x / portions + 1) : 1;
					if (repeatAxes.y) tilesY = repeatAxes.y ? Math.ceil(viewMargins.height / tileSize.y / portions + 1) : 1;
			}
		}
		
		viewMargins.put();
		
		if (matchPrevDrawParams(tilesX, tilesY))
		{
			tileSize.put();
			return;
		}
		setDrawParams(tilesX, tilesY);
		
		_blitOffset.set(0, 0);
		var graphicSizeX = Math.ceil(tilesX * tileSize.x);
		var graphicSizeY = Math.ceil(tilesY * tileSize.y);
		if (repeatAxes != XY)
		{
			final screenBounds = getScreenBounds();
			final screenPos = getScreenPosition();
			if (!repeatAxes.x)
			{
				graphicSizeX = Math.ceil(screenBounds.width);
				_blitOffset.x = screenBounds.x - screenPos.x;
			}
			
			if (!repeatAxes.y)
			{
				graphicSizeY = Math.ceil(screenBounds.height);
				_blitOffset.y = screenBounds.y - screenPos.y;
			}
			screenBounds.put();
			screenPos.put();
		}
		
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
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);
		if (bakedRotationAngle <= 0)
		{
			updateTrig();
			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}
		
		_matrix.translate(origin.x, origin.y);
		_matrix.translate(-_blitOffset.x, -_blitOffset.y);
		_point.set(_matrix.tx, _matrix.ty);
		
		// draw extra tiles on the edge in case the image protrudes past the tile
		// TODO: Use 0 buffer when angle is multiple of 90 with centered origin
		final bufferX = repeatAxes.x && angle != 0 ? 1 : 0;
		final bufferY = repeatAxes.y && angle != 0 ? 1 : 0;
		for (tileX in -bufferX...tilesX + bufferX)
		{
			for (tileY in -bufferY...tilesY + bufferY)
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
			&& _prevDrawParams.repeatAxes == repeatAxes
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
		_prevDrawParams.repeatAxes = repeatAxes;
		_prevDrawParams.angle      = angle;
	}
}

enum BackdropBlitMode
{
	/**
	 * Not implemented yet.
	 */
	AUTO;
	
	/**
	 * Blits a bitmap as big as the specified number of x and y tiles and repeats that.
	 */
	MAX_TILES_XY(x:Int, y:Int);
	
	/**
	 * Blits a bitmap as big as the specified number of tiles and repeats that.
	 */
	MAX_TILES(tiles:Int);
	
	/**
	 * Blits enough tiles to cover the screen in multiple draws, for example, if the camera is 10x8
	 * tiles big, SPLIT(2) will draw a blit target 5x4 tiles large and draw it 2x2 times to cover the
	 * stage.
	 */
	SPLIT(portions:Int);
}

typedef BackdropDrawParams = {
	graphicKey:String,
	tilesX:Int,
	tilesY:Int,
	scaleX:Float,
	scaleY:Float,
	spacingX:Float,
	spacingY:Float,
	repeatAxes:FlxAxes,
	angle:Float
};
