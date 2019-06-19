package flixel.addons.display;

import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxVector;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.display.BitmapDataChannel;
import openfl.display.BlendMode;

using flixel.util.FlxSpriteUtil;

/**
 * A dynamic shape that fills up the way a pie chart does. Useful for timers and other things.
 * @author larsiusprime
 */
class FlxPieDial extends FlxSprite
{
	/**
	 * A value between 0.0 (empty) and 1.0 (full)
	 */
	public var amount(default, set):Float;

	var pieFrames:Int = 0;

	public function new(X:Float, Y:Float, Radius:Int, Color:FlxColor = FlxColor.WHITE, Frames:Int = 36, ?Shape:FlxPieDialShape, Clockwise:Bool = true,
			InnerRadius:Int = 0)
	{
		if (Shape == null)
			Shape = CIRCLE;
		super(X, Y);
		makePieDialGraphic(Radius, Color, Frames, Shape, Clockwise, InnerRadius);
		amount = 1.0;
	}

	override public function draw():Void
	{
		if (amount == 0)
			return;
		super.draw();
	}

	function makePieDialGraphic(Radius:Int, Color:FlxColor, Frames:Int, Shape:FlxPieDialShape, Clockwise:Bool, InnerRadius:Int)
	{
		pieFrames = Frames;
		var key:String = "pie_dial_" + Color.toHexString() + "_" + Radius + "_" + Frames + "_" + Shape + "_" + Clockwise + "_" + InnerRadius;
		var W = Radius * 2;
		var H = Radius * 2;
		if (!FlxG.bitmap.checkCache(key))
		{
			var bmp = makePieDialGraphicSub(Radius, Color, Frames, Shape, Clockwise, InnerRadius);
			FlxG.bitmap.add(bmp, true, key);
		}

		loadGraphic(key, true, W, H);
	}

	function makePieDialGraphicSub(Radius:Int, Color:Int, Frames:Int, Shape:FlxPieDialShape, Clockwise:Bool, InnerRadius):BitmapData
	{
		var W = Radius * 2;
		var H = Radius * 2;

		var rows:Int = Math.ceil(Math.sqrt(Frames));
		var cols:Int = Math.ceil((Frames) / rows);

		var back = Clockwise ? FlxColor.BLACK : FlxColor.WHITE;
		var fore = Clockwise ? FlxColor.WHITE : FlxColor.BLACK;

		var fullFrame = makeFullFrame(Radius, Color, Frames, Shape, Clockwise, InnerRadius);
		var nextFrame = new FlxSprite().makeGraphic(W, H, back, false);

		var bmp:BitmapData = new BitmapData(W * cols, H * rows, false, back);
		var i:Int = 0;
		_flashPoint.setTo(0, 0);
		var v:FlxVector = FlxVector.get(0, -1);
		var degrees:Float = 360 / (Frames);
		if (!Clockwise)
		{
			degrees *= -1;
		}

		var sweep:Float = Clockwise ? 0 : 360;
		var bmp2 = new BitmapData(bmp.width, bmp.height, true, FlxColor.TRANSPARENT);
		var fullBmp:BitmapData = fullFrame.pixels.clone();

		var polygon:Array<FlxPoint> = [FlxPoint.get(), FlxPoint.get(), FlxPoint.get(), FlxPoint.get(), FlxPoint.get()];
		for (r in 0...rows)
		{
			for (c in 0...cols)
			{
				if (i >= Frames)
				{
					break;
				}

				_flashPoint.setTo(c * W, r * H);
				bmp2.copyPixels(fullBmp, fullBmp.rect, _flashPoint);

				if (i <= 0)
				{
					bmp.fillRect(fullBmp.rect, FlxColor.WHITE);
				}
				else
				{
					nextFrame.pixels.copyPixels(fullFrame.pixels, fullFrame.pixels.rect, _flashPointZero);
					_flashPoint.setTo(c * W, r * H);
					drawSweep(sweep, v, nextFrame, polygon, W, H, back, fore);
					bmp.copyPixels(nextFrame.pixels, nextFrame.pixels.rect, _flashPoint);
				}

				sweep += degrees;
				v.rotateByDegrees(degrees);

				i++;
			}

			if (i >= Frames)
			{
				break;
			}
		}

		fullBmp.dispose();
		fullFrame.destroy();
		nextFrame.destroy();

		var shapeChannel = new BitmapData(bmp.width, bmp.height, false);
		shapeChannel.copyChannel(bmp2, bmp2.rect, _flashPointZero, BitmapDataChannel.ALPHA, BitmapDataChannel.RED);
		shapeChannel.copyChannel(bmp2, bmp2.rect, _flashPointZero, BitmapDataChannel.ALPHA, BitmapDataChannel.GREEN);
		shapeChannel.copyChannel(bmp2, bmp2.rect, _flashPointZero, BitmapDataChannel.ALPHA, BitmapDataChannel.BLUE);

		shapeChannel.draw(bmp, null, null, BlendMode.MULTIPLY, null, true);
		bmp2.copyChannel(shapeChannel, shapeChannel.rect, _flashPointZero, BitmapDataChannel.RED, BitmapDataChannel.ALPHA);

		shapeChannel.dispose();
		bmp.dispose();

		return bmp2;
	}

	function makeFullFrame(Radius:Int, Color:Int, Frames:Int, Shape:FlxPieDialShape, Clockwise:Bool, InnerRadius):FlxSprite
	{
		var W = Radius * 2;
		var H = Radius * 2;

		var fullFrame = new FlxSprite().makeGraphic(W, H, FlxColor.TRANSPARENT, true);
		if (InnerRadius > Radius)
		{
			InnerRadius = 0;
		}

		var dR = Radius - InnerRadius;

		if (Shape == SQUARE)
		{
			fullFrame.pixels.fillRect(fullFrame.pixels.rect, Color);
			if (InnerRadius > 0)
			{
				_flashRect.setTo(dR, dR, InnerRadius * 2, InnerRadius * 2);
				fullFrame.pixels.fillRect(_flashRect, FlxColor.TRANSPARENT);
			}
		}
		else if (Shape == CIRCLE)
		{
			if (InnerRadius > 0)
			{
				var alpha = new BitmapData(fullFrame.pixels.width, fullFrame.pixels.height, false, FlxColor.BLACK);
				fullFrame.pixels.fillRect(_flashRect, FlxColor.BLACK);
				fullFrame.drawCircle(-1, -1, Radius, FlxColor.WHITE, null, {smoothing: true});
				fullFrame.drawCircle(-1, -1, InnerRadius, FlxColor.BLACK, null, {smoothing: true});

				alpha.copyPixels(fullFrame.pixels, fullFrame.pixels.rect, _flashPointZero, null, null, true);

				fullFrame.pixels.fillRect(fullFrame.pixels.rect, Color);
				fullFrame.pixels.copyChannel(alpha, alpha.rect, _flashPointZero, BitmapDataChannel.RED, BitmapDataChannel.ALPHA);

				alpha.dispose();
			}
			else
			{
				fullFrame.drawCircle(-1, -1, Radius, Color);
			}
		}
		return fullFrame;
	}

	function drawSweep(sweep:Float, v:FlxVector, nextFrame:FlxSprite, polygon:Array<FlxPoint>, W:Int, H:Int, back:FlxColor, fore:FlxColor)
	{
		var halfW = W / 2;
		var halfH = H / 2;

		nextFrame.pixels.fillRect(nextFrame.pixels.rect, back);
		polygon[0].set(halfW, halfH);

		if (sweep < 45)
		{
			polygon[1].set(halfW, 0);
			polygon[2].set(halfW + W * v.x, halfH + H * v.y);
			polygon[3].set(halfW, halfH);
		}
		else if (sweep < 90)
		{
			polygon[1].set(halfW, 0);
			polygon[2].set(W, 0);
			polygon[3].set(halfW + W * v.x, halfH + H * v.y);
		}
		else if (sweep < 135)
		{
			_flashRect.setTo(halfW, 0, halfW, halfH);
			nextFrame.pixels.fillRect(_flashRect, fore);

			polygon[1].set(W, halfH);
			polygon[2].set(halfW + W * v.x, halfH + H * v.y);
			polygon[3].set(halfW, halfH);
		}
		else if (sweep < 180)
		{
			_flashRect.setTo(halfW, 0, halfW, halfH);
			nextFrame.pixels.fillRect(_flashRect, fore);

			polygon[1].set(W, halfH);
			polygon[2].set(W, H);
			polygon[3].set(halfW + W * v.x, halfH + H * v.y);
		}
		else if (sweep < 225)
		{
			_flashRect.setTo(halfW, 0, halfW, H);
			nextFrame.pixels.fillRect(_flashRect, fore);

			polygon[1].set(halfW, H);
			polygon[2].set(halfW + W * v.x, halfH + H * v.y);
			polygon[3].set(halfW, halfH);
		}
		else if (sweep < 270)
		{
			_flashRect.setTo(halfW, 0, halfW, H);
			nextFrame.pixels.fillRect(_flashRect, fore);

			polygon[1].set(halfW, H);
			polygon[2].set(0, H);
			polygon[3].set(halfW + W * v.x, halfH + H * v.y);
		}
		else if (sweep < 315)
		{
			_flashRect.setTo(halfW, 0, halfW, H);
			nextFrame.pixels.fillRect(_flashRect, fore);
			_flashRect.setTo(0, halfH, halfW, halfH);
			nextFrame.pixels.fillRect(_flashRect, fore);

			polygon[1].set(0, halfH);
			polygon[2].set(halfW + W * v.x, halfH + H * v.y);
			polygon[3].set(halfW, halfH);
		}
		else if (sweep < 360)
		{
			_flashRect.setTo(halfW, 0, halfW, H);
			nextFrame.pixels.fillRect(_flashRect, fore);
			_flashRect.setTo(0, halfH, halfW, halfH);
			nextFrame.pixels.fillRect(_flashRect, fore);

			polygon[1].set(0, halfH);
			polygon[2].set(0, 0);
			polygon[3].set(halfW + W * v.x, halfH + H * v.y);
		}

		polygon[4].set(halfW, halfH);

		nextFrame.drawPolygon(polygon, fore);
	}

	function set_amount(f:Float):Float
	{
		amount = FlxMath.bound(f, 0.0, 1.0);
		var frame:Int = Std.int(f * pieFrames);
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
