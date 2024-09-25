package flixel.addons.display;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxBitmapDataPool;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapData;
import openfl.display.BitmapDataChannel;
import openfl.display.BlendMode;
import openfl.geom.Point;
import openfl.geom.Rectangle;

using flixel.util.FlxSpriteUtil;

/**
 * A dynamic shape that fills up the way a pie chart does. Useful for timers and other things.
 */
class FlxPieDial extends FlxSprite
{
	/**
	 * A value between 0.0 (empty) and 1.0 (full)
	 */
	public var amount(default, set):Float;
	
	public function new(x = 0.0, y = 0.0, radius:Int, color = FlxColor.WHITE, frames = 36, ?shape:FlxPieDialShape, clockwise = true, innerRadius = 0)
	{
		if (shape == null)
			shape = CIRCLE;
		
		super(x, y);
		getPieDialGraphic(radius, color, frames, shape, clockwise, innerRadius);
		amount = 1.0;
	}

	override public function draw():Void
	{
		if (amount * animation.numFrames < 1)
			return;
		
		super.draw();
	}
	
	function getPieDialGraphic(radius:Int, color:FlxColor, frames:Int, shape:FlxPieDialShape, clockwise:Bool, innerRadius:Int)
	{
		final graphic = FlxPieDialUtils.getPieDialGraphic(radius, color, frames, shape, clockwise, innerRadius);
		loadGraphic(graphic, true, radius * 2, radius * 2);
	}
	
	function set_amount(f:Float):Float
	{
		amount = FlxMath.bound(f, 0.0, 1.0);
		var frame:Int = Std.int(f * animation.numFrames);
		animation.frameIndex = frame;
		if (amount == 1.0)
		{
			animation.frameIndex = 0; // special case for full frame
		}
		return amount;
	}
}

enum FlxPieDialShape
{
	CIRCLE;
	SQUARE;
}

/**
 * Set of tools for drawing pie dial graphics
 * @since 5.9.0
 */
class FlxPieDialUtils
{
	static final _rect = new Rectangle();
	static final _zero = new Point();
	static final _point = new Point();
	static var flashGfx = FlxSpriteUtil.flashGfx;
	
	public static function getPieDialGraphic(radius:Int, color:FlxColor, frames:Int, shape:FlxPieDialShape, clockwise:Bool, innerRadius:Int)
	{
		final key = 'pie_dial_${color.toHexString()}_${radius}_${frames}_${shape}_${clockwise}_$innerRadius';
		
		if (!FlxG.bitmap.checkCache(key))
		{
			final bmp = renderPieDial(shape, radius, innerRadius, frames, clockwise, color);
			FlxG.bitmap.add(bmp, true, key);
		}
		
		return FlxG.bitmap.get(key);
	}
	
	public static function getRadialGaugeGraphic(shape:FlxPieDialShape, radius:Int, innerRadius = 0, color = FlxColor.WHITE)
	{
		final key = 'radial_gauge_${shape}_${color.toHexString()}_${radius}_$innerRadius';
		
		if (!FlxG.bitmap.checkCache(key))
		{
			final bmp = renderRadialGauge(shape, radius, innerRadius, color);
			FlxG.bitmap.add(bmp, true, key);
		}
		
		return FlxG.bitmap.get(key);
	}
	
	/**
	 * Draws an animated pie dial graphic where each frame shows a more full amount,
	 * however the full gauge frame is on frame 0
	 * 
	 * @param radius       The radius of the shape
	 * @param color        The color of the shape
	 * @param shape        The shape, Either `SQUARE` or `CIRCLE`
	 * @param innerRadius  The radius of the inner hollow portion, where `0` means completely filled
	 */
	public static function renderRadialGauge(shape:FlxPieDialShape, radius:Int, innerRadius = 0, color = FlxColor.WHITE):BitmapData
	{
		return renderPieDial(shape, radius, innerRadius, 1, true, color);
	}
	
	/**
	 * Draws an animated pie dial graphic where each frame shows a more full amount,
	 * however the full gauge frame is on frame 0
	 * 
	 * @param radius       The radius of the shape
	 * @param color        The color of the shape
	 * @param frames       
	 * @param shape        The shape, Either `SQUARE` or `CIRCLE`
	 * @param clockwise    The direction the gauge
	 * @param innerRadius  The radius of the inner hollow portion, where `0` means completely filled
	 */
	public static function renderPieDial(shape:FlxPieDialShape, radius:Int, innerRadius:Int, frames:Int, clockwise = true, color = FlxColor.WHITE):BitmapData
	{
		final W = radius * 2;
		final H = radius * 2;
		
		final rows = Math.ceil(Math.sqrt(frames));
		final cols = Math.ceil(frames / rows);
		
		final maskFrame = FlxBitmapDataPool.get(W, H, true, FlxColor.TRANSPARENT, true);
		final fullFrame = FlxBitmapDataPool.get(W, H, true, FlxColor.TRANSPARENT, true);
		FlxPieDialUtils.drawShape(fullFrame, radius, color, shape, innerRadius);
		
		final result = new BitmapData(W * cols, H * rows, true, FlxColor.TRANSPARENT);
		final p = FlxPoint.get();
		final degreeInterval = (clockwise ? 1 : -1) * 360 / frames;
		
		final mask = FlxBitmapDataPool.get(result.width, result.height, result.transparent, FlxColor.TRANSPARENT, true);
		
		final polygon:Array<FlxPoint> = [FlxPoint.get(), FlxPoint.get(), FlxPoint.get(), FlxPoint.get(), FlxPoint.get()];
		for (i in 0...frames)
		{
			_point.setTo((i % cols) * W, Std.int(i / cols) * H);
			result.copyPixels(fullFrame, fullFrame.rect, _point);//, null, null, true);
			if (i <= 0)
			{
				mask.fillRect(fullFrame.rect, FlxColor.WHITE);
			}
			else
			{
				final angle = degreeInterval * i;
				maskFrame.fillRect(maskFrame.rect, FlxColor.TRANSPARENT);
				FlxPieDialUtils.drawSweep(maskFrame, angle);
				mask.copyPixels(maskFrame, maskFrame.rect, _point, null, null, true);
			}
		}
		
		result.copyPixels(result, result.rect, _zero, mask);
		FlxBitmapDataPool.put(mask);
		FlxBitmapDataPool.put(maskFrame);
		FlxBitmapDataPool.put(fullFrame);
		
		return result;
	}
	
	/**
	 * Draws the specified shape onto the bitmap
	 * 
	 * @param dest         The bitmap to draw to
	 * @param radius       The radius of the shape
	 * @param color        The color of the shape
	 * @param shape        The shape, Either `SQUARE` or `CIRCLE`
	 * @param innerRadius  The radius of the inner hollow portion, where `0` means completely filled
	 */
	public static inline function drawShape(dest:BitmapData, radius:Int, color:FlxColor, shape:FlxPieDialShape, innerRadius = 0):BitmapData
	{
		final W = radius << 1;
		final H = radius << 1;
		
		switch (shape)
		{
			case SQUARE if (innerRadius > 0 && innerRadius < radius):
				final thickness = radius - innerRadius;
				_rect.setTo(0, 0, W, thickness);
				dest.fillRect(_rect, color);
				_rect.setTo(0, 0, thickness, H);
				dest.fillRect(_rect, color);
				_rect.setTo(W - thickness, 0, thickness, H);
				dest.fillRect(_rect, color);
				_rect.setTo(0, H - thickness, W, thickness);
				dest.fillRect(_rect, color);
				
			case SQUARE:
				dest.fillRect(dest.rect, color);
			
			case CIRCLE if (innerRadius > 0 && innerRadius < radius):
				final alpha = FlxBitmapDataPool.get(W, H, false, FlxColor.BLACK, true);
				alpha.fillRect(alpha.rect, FlxColor.BLACK);
				drawCircle(alpha, radius, FlxColor.WHITE, null, {smoothing: true});
				drawCircle(alpha, innerRadius, FlxColor.BLACK, null, {smoothing: true});
				
				alpha.copyPixels(dest, dest.rect, _zero, null, null, true);
				
				dest.fillRect(dest.rect, color);
				dest.copyChannel(alpha, alpha.rect, _zero, BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
				
				FlxBitmapDataPool.put(alpha);
				
			case CIRCLE:
				drawCircle(dest, radius, color);
		}
		return dest;
	}
	
	/**
	 * Used via `drawSweep`
	 */
	static final sweepPoints = [for (i in 0...4) FlxPoint.get()];
	
	/**
	 * Draws a wedge section of a bitmap, used in `FlxPieDial`
	 * @param dest     The btimap to draw to
	 * @param degrees  The angle of the wedge
	 * @param color    The color to fill the wedge
	 */
	public static function drawSweep(dest:BitmapData, degrees:Float, color = FlxColor.WHITE)
	{
		degrees %= 360;
		final p = sweepPoints;
		final radius = dest.width >> 1;
		final center = p[0].set(radius, radius);
		final cornerLength = center.length;
		
		if (degrees >= 270)
		{
			// fill right half
			_rect.setTo(radius, 0, radius, dest.height);
			dest.fillRect(_rect, color);
			// fill bottom-left quadrant
			_rect.setTo(0, radius, radius, radius);
			dest.fillRect(_rect, color);
		}
		else if (degrees >= 180)
		{
			// fill right half
			_rect.setTo(radius, 0, radius, dest.height);
			dest.fillRect(_rect, color);
		}
		else if (degrees >= 90)
		{
			// fill top-right quadrant
			_rect.setTo(radius, 0, radius, radius);
			dest.fillRect(_rect, color);
		}
		else if (degrees <= -270)
		{
			// fill left half
			_rect.setTo(0, 0, radius, dest.height);
			dest.fillRect(_rect, color);
			// fill bottom-right quadrant
			_rect.setTo(radius, radius, radius, radius);
			dest.fillRect(_rect, color);
		}
		else if (degrees <= -180)
		{
			// fill left half
			_rect.setTo(0, 0, radius, dest.height);
			dest.fillRect(_rect, color);
		}
		else if (degrees <= -90)
		{
			// fill top-left quadrant
			_rect.setTo(0, 0, radius, radius);
			dest.fillRect(_rect, color);
		}
		
		// draw the interesting quadrant
		if (Math.abs(degrees % 90) < 45)
		{
			p[1].setPolarDegrees(radius, -90 + Std.int(degrees / 90) * 90).addPoint(center);
			p[2].setPolarDegrees(cornerLength, -90 + degrees).addPoint(center);
			p[3].copyFrom(center);
		}
		else
		{
			final quadDegreesStart = Std.int(degrees / 90) * 90;
			final cornerDegrees = quadDegreesStart + (degrees < 0 ? -45 : 45);
			p[1].setPolarDegrees(radius, -90 + quadDegreesStart).addPoint(center);
			p[2].setPolarDegrees(cornerLength, -90 + cornerDegrees).addPoint(center);
			p[3].setPolarDegrees(cornerLength, -90 + degrees).addPoint(center);
		}
		
		drawPolygon(dest, p, color);
	}
	
	/**
	 * This function draws a circle on a FlxSprite at position X,Y with the specified color.
	 *
	 * @param   bitmap     The BitmapData to manipulate
	 * @param   X          X coordinate of the circle's center (automatically centered on the sprite if -1)
	 * @param   Y          Y coordinate of the circle's center (automatically centered on the sprite if -1)
	 * @param   radius     Radius of the circle (makes sure the circle fully fits on the sprite's graphic if < 1, assuming and and y are centered)
	 * @param   color      The ARGB color to fill this circle with. FlxColor.TRANSPARENT (0x0) means no fill.
	 * @param   lineStyle  A LineStyle typedef containing the params of Graphics.lineStyle()
	 * @param   drawStyle  A DrawStyle typedef containing the params of BitmapData.draw()
	 * @return  The FlxSprite for chaining
	 */
	public static function drawCircle(bitmap:BitmapData, ?radius:Float, color = FlxColor.WHITE, ?lineStyle:LineStyle, ?drawStyle:DrawStyle):BitmapData
	{
		final x = bitmap.width * 0.5;
		final y = bitmap.height * 0.5;
		
		if (radius == null)
			radius = Math.min(bitmap.width, bitmap.height) * 0.5;
		
		beginDraw(color, lineStyle);
		flashGfx.drawCircle(x, y, radius);
		endDraw(bitmap, drawStyle);
		return bitmap;
	}
	
	/**
	 * This function draws a polygon on a FlxSprite.
	 *
	 * @param   graphic    The FlxSprite to manipulate
	 * @param   Vertices   Array of Vertices to use for drawing the polygon
	 * @param   FillColor  The ARGB color to fill this polygon with. FlxColor.TRANSPARENT (0x0) means no fill.
	 * @param   lineStyle  A LineStyle typedef containing the params of Graphics.lineStyle()
	 * @param   drawStyle  A DrawStyle typedef containing the params of BitmapData.draw()
	 * @return  The FlxSprite for chaining
	 */
	public static function drawPolygon(bitmap:BitmapData, vertices:Array<FlxPoint>, fillColor = FlxColor.WHITE, ?lineStyle:LineStyle,
			?drawStyle:DrawStyle):BitmapData
	{
		beginDraw(fillColor, lineStyle);
		final p:FlxPoint = vertices.shift();
		flashGfx.moveTo(p.x, p.y);
		for (p in vertices)
		{
			flashGfx.lineTo(p.x, p.y);
		}
		endDraw(bitmap, drawStyle);
		vertices.unshift(p);
		return bitmap;
	}
	
	static inline function beginDraw(color:FlxColor, ?lineStyle:LineStyle):Void
	{
		flashGfx.clear();
		FlxSpriteUtil.setLineStyle(lineStyle);
		
		if (color != FlxColor.TRANSPARENT)
			flashGfx.beginFill(color.rgb, color.alphaFloat);
	}
	
	static inline function endDraw(bitmap:BitmapData, ?style:DrawStyle):BitmapData
	{
		flashGfx.endFill();
		if (style == null)
			style = {smoothing: false};
		else if (style.smoothing == null)
			style.smoothing = false;
		
		final sprite = FlxSpriteUtil.flashGfxSprite;
		bitmap.draw(sprite, style.matrix, style.colorTransform, style.blendMode, style.clipRect, style.smoothing);
		return bitmap;
	}
}