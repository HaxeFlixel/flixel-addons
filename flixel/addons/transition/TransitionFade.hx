package flixel.addons.transition;

import flash.display.BitmapData;
import flixel.addons.transition.TransitionEffect;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.math.FlxRect;
import openfl.Assets;
import openfl.display.BitmapDataChannel;
import openfl.geom.Matrix;
import openfl.geom.Point;

@:keep @:bitmap("assets/images/transitions/diagonal_gradient.png")
private class GraphicDiagonalGradient extends BitmapData {}

/**
 *
 * @author larsiusprime
 */
class TransitionFade extends TransitionEffect
{
	var back:FlxSprite;
	var tweenStr:String = "";
	var tweenStr2:String = "";
	var tweenValStart:Float = 0;
	var tweenValStart2:Float = 0;
	var tweenValEnd:Float = 0;
	var tweenValEnd2:Float = 0;

	public function new(data:TransitionData)
	{
		super(data);

		back = makeSprite(data.direction.x, data.direction.y, data.region);
		back.scrollFactor.set(0, 0);
		add(back);
	}

	public override function destroy():Void
	{
		super.destroy();
		back = null;
	}

	public override function start(NewStatus:TransitionStatus):Void
	{
		super.start(NewStatus);

		setTweenValues(NewStatus, _data.direction.x, _data.direction.y);

		switch (tweenStr)
		{
			case "alpha":
				back.alpha = tweenValStart;
			case "x":
				back.x = tweenValStart;
			case "y":
				back.y = tweenValStart;
		}
		switch (tweenStr2)
		{
			case "alpha":
				back.alpha = tweenValStart2;
			case "x":
				back.x = tweenValStart2;
			case "y":
				back.y = tweenValStart2;
		}

		var Values:Dynamic = {};
		Reflect.setField(Values, tweenStr, tweenValEnd);
		if (tweenStr2 != "")
		{
			Reflect.setField(Values, tweenStr2, tweenValEnd2);
		}
		_data.tweenOptions.onComplete = finishTween;
		FlxTween.tween(back, Values, _data.duration, _data.tweenOptions);
	}

	function setTweenValues(NewStatus:TransitionStatus, DirX:Float, DirY:Float):Void
	{
		if (DirX == 0 && DirY == 0)
		{
			// no direction
			tweenStr = "alpha";
			tweenValStart = NewStatus == IN ? 0.0 : 1.0;
			tweenValEnd = NewStatus == IN ? 1.0 : 0.0;
		}
		else if (Math.abs(DirX) > 0 && DirY == 0)
		{
			// horizontal wipe
			tweenStr = "x";
			if (DirX > 0)
			{
				tweenValStart = NewStatus == IN ? -back.width : 0;
				tweenValEnd = NewStatus == IN ? 0 : -back.width;
			}
			else
			{
				tweenValStart = NewStatus == IN ? FlxG.width : -back.width / 2;
				tweenValEnd = NewStatus == IN ? -back.width / 2 : FlxG.width;
			}
		}
		else if ((DirX == 0 && Math.abs(DirY) > 0))
		{
			// vertical wipe
			tweenStr = "y";
			if (DirY > 0)
			{
				tweenValStart = NewStatus == IN ? -back.height : 0;
				tweenValEnd = NewStatus == IN ? 0 : -back.height;
			}
			else
			{
				tweenValStart = NewStatus == IN ? FlxG.height : -back.height / 2;
				tweenValEnd = NewStatus == IN ? -back.height / 2 : FlxG.height;
			}
		}
		else if (Math.abs(DirX) > 0 && Math.abs(DirY) > 0)
		{
			// diagonal wipe
			tweenStr = "x";
			tweenStr2 = "y";
			if (DirX > 0)
			{
				tweenValStart = NewStatus == IN ? -back.width : 0;
				tweenValEnd = NewStatus == IN ? 0 : -back.width;
			}
			else
			{
				tweenValStart = NewStatus == IN ? FlxG.width : -back.width * (2 / 3);
				tweenValEnd = NewStatus == IN ? -back.width * (2 / 3) : FlxG.width;
			}
			if (DirY > 0)
			{
				tweenValStart2 = NewStatus == IN ? -back.height : 0;
				tweenValEnd2 = NewStatus == IN ? 0 : -back.height;
			}
			else
			{
				tweenValStart2 = NewStatus == IN ? FlxG.height : -back.height * (2 / 3);
				tweenValEnd2 = NewStatus == IN ? -back.height * (2 / 3) : FlxG.height;
			}
		}
	}

	function makeSprite(DirX:Float, DirY:Float, region:FlxRect):FlxSprite
	{
		var s = new FlxSprite(region.x, region.y);
		var locX:Float = 0;
		var locY:Float = 0;
		var angle:Int = 0;
		var pixels:BitmapData = null;
		if (DirX == 0 && DirY == 0)
		{
			// no direction
			s.makeGraphic(Std.int(region.width), Std.int(region.height), _data.color);
		}
		else if (DirX == 0 && Math.abs(DirY) > 0)
		{
			// vertical wipe
			locY = DirY > 0 ? region.height : 0;
			angle = DirY > 0 ? 90 : 270;
			s.makeGraphic(1, Std.int(region.height * 2), _data.color);
			pixels = s.pixels;
			var gvert = FlxGradient.createGradientBitmapData(1, Std.int(region.height), [_data.color, FlxColor.TRANSPARENT], 1, angle);
			pixels.copyPixels(gvert, gvert.rect, new Point(0, locY));
			s.pixels = pixels;
			s.scale.set(region.width, 1.0);
			s.updateHitbox();
		}
		else if (Math.abs(DirX) > 0 && DirY == 0)
		{
			// horizontal wipe
			locX = DirX > 0 ? region.width : 0;
			angle = DirX > 0 ? 0 : 180;
			s.makeGraphic(Std.int(region.width * 2), 1, _data.color);
			pixels = s.pixels;
			var ghorz = FlxGradient.createGradientBitmapData(Std.int(region.width), 1, [_data.color, FlxColor.TRANSPARENT], 1, angle);
			pixels.copyPixels(ghorz, ghorz.rect, new Point(locX, 0));
			s.pixels = pixels;
			s.scale.set(1.0, region.height);
			s.updateHitbox();
		}
		else if (Math.abs(DirX) > 0 && Math.abs(DirY) > 0)
		{
			// diagonal wipe
			locY = DirY > 0 ? region.height : 0;
			s.loadGraphic(getGradient());
			s.flipX = DirX < 0;
			s.flipY = DirY < 0;
		}
		return s;
	}

	function getGradient():BitmapData
	{
		// TODO: this could perhaps be optimized a lot by creating a single-pixel wide sprite, rotating it, scaling it super big, and positioning it properly
		var rawBmp = new GraphicDiagonalGradient(0, 0);
		var gdiag:BitmapData = cast rawBmp;
		var gdiag_scaled:BitmapData = new BitmapData(FlxG.width * 2, FlxG.height * 2, true);
		var m:Matrix = new Matrix();
		m.scale(gdiag_scaled.width / gdiag.width, gdiag_scaled.height / gdiag.height);
		gdiag_scaled.draw(gdiag, m, null, null, null, true);
		var theColor:FlxColor = _data.color;
		var final_pixels:BitmapData = new BitmapData(FlxG.width * 3, FlxG.height * 3, true, theColor);
		final_pixels.copyChannel(gdiag_scaled, gdiag_scaled.rect,
			new Point(final_pixels.width - gdiag_scaled.width, final_pixels.height - gdiag_scaled.height), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
		gdiag.dispose();
		gdiag_scaled.dispose();
		return final_pixels;
	}

	function finishTween(f:FlxTween):Void
	{
		delayThenFinish();
	}
}
