package flixel.addons.transition;

import openfl.display.BitmapData;
import flixel.addons.transition.TransitionEffect;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.math.FlxRect;
import openfl.Assets;
import openfl.display.BitmapDataChannel;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

#if html5
@:keep @:bitmap("assets/images/transitions/diagonal_gradient.png")
private class RawGraphicDiagonalGradient extends BitmapData {}
class GraphicDiagonalGradient extends RawGraphicDiagonalGradient
{
	static inline var WIDTH = 319;
	static inline var HEIGHT = 128;
	
	public function new(?onLoad)
	{
		super(WIDTH, HEIGHT, true, 0xFFffffff, onLoad);
		// Set properties because `@:bitmap` constructors ignore width/height
		this.width = WIDTH;
		this.height = HEIGHT;
	}
}
#else
@:keep @:bitmap("assets/images/transitions/diagonal_gradient.png")
private class GraphicDiagonalGradient extends BitmapData {}
#end

typedef TweenEndValues = { ?x:Float, ?y:Float, ?alpha:Float };
/**
 *
 * @author larsiusprime
 */
class TransitionFade extends TransitionEffect
{
	public static inline var GRADIENT_PATH = "flixel/images/transitions/diagonal_gradient.png";
	
	var back:FlxSprite;
	
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
	
	public override function start(newStatus:TransitionStatus):Void
	{
		super.start(newStatus);
		
		final endValues:TweenEndValues = {};
		setTweenValues(newStatus == IN, _data.direction.x, _data.direction.y, back, endValues);
		
		_data.tweenOptions.onComplete = finishTween;
		FlxTween.tween(back, endValues, _data.duration, _data.tweenOptions);
	}
	
	function setTweenValues(isIn:Bool, dirX:Float, dirY:Float, sprite:FlxSprite, values:TweenEndValues):Void
	{
		final isOut = !isIn;
		if (dirX == 0 && dirY == 0)
		{
			// no direction
			sprite.alpha = isIn ? 0 : 1;
			values.alpha = isOut ? 0 : 1;
		}
		else if (dirX != 0 && dirY != 0)
		{
			// diagonal wipe
			if (dirX > 0)
			{
				sprite.x = isIn ? -back.width : 0;
				values.x = isOut ? -back.width : 0;
			}
			else
			{
				sprite.x = isIn ? FlxG.width : FlxG.width - back.width;
				values.x = isOut ? FlxG.width : FlxG.width - back.width;
			}
			
			return;
		}
		else if (dirX != 0)
		{
			// horizontal wipe
			if (dirX > 0)
			{
				sprite.x = isIn ? -back.width : 0;
				values.x = isOut ? -back.width : 0;
			}
			else
			{
				sprite.x = isIn ? FlxG.width : -back.width / 2;
				values.x = isOut ? FlxG.width : -back.width / 2;
			}
		}
		else
		{
			// vertical wipe
			if (dirY > 0)
			{
				sprite.y = isIn ? -back.height : 0;
				values.y = isOut ? -back.height : 0;
			}
			else
			{
				sprite.y = isIn ? FlxG.height : -back.height / 2;
				values.y = isOut ? FlxG.height : -back.height / 2;
			}
		}
	}

	inline function getBitmapKey(dirX:Float, dirY:Float, color:FlxColor):String
	{
		return "transition" + color + "x" + dirX + "y" + dirY;
	}
	
	function makeSprite(dirX:Float, dirY:Float, region:FlxRect):FlxSprite
	{
		final sprite = new FlxSprite(region.x, region.y);
		final bitmapKey = getBitmapKey(dirX, dirY, _data.color);

		sprite.antialiasing = false;
		
		if (dirX == 0 && dirY == 0)
		{
			// no direction
			sprite.makeGraphic(1, 1, _data.color, false, bitmapKey);
			sprite.scale.set(Std.int(region.width), Std.int(region.height));
			sprite.updateHitbox();
		}
		else if (dirX == 0 && dirY != 0)
		{
			// vertical wipe
			sprite.makeGraphic(1, Std.int(region.height * 2), _data.color, false, bitmapKey);
			final angle = dirY > 0 ? 90 : 270;
			final gradient = FlxGradient.createGradientBitmapData(1, Std.int(region.height), [_data.color, FlxColor.TRANSPARENT], 1, angle);
			final destY = dirY > 0 ? region.height : 0;
			sprite.pixels.copyPixels(gradient, gradient.rect, new Point(0, destY));
			sprite.scale.set(region.width, 1.0);
			sprite.updateHitbox();
		}
		else if (dirX != 0 && dirY == 0)
		{
			// horizontal wipe
			final destX = dirX > 0 ? region.width : 0;
			final angle = dirX > 0 ? 0 : 180;
			sprite.makeGraphic(Std.int(region.width * 2), 1, _data.color, false, bitmapKey);
			final gradient = FlxGradient.createGradientBitmapData(Std.int(region.width), 1, [_data.color, FlxColor.TRANSPARENT], 1, angle);
			sprite.pixels.copyPixels(gradient, gradient.rect, new Point(destX, 0));
			sprite.scale.set(1.0, region.height);
			sprite.updateHitbox();
		}
		else if (dirX != 0 && dirY != 0)
		{
			// diagonal wipe
			sprite.loadGraphic(getGradient());
			sprite.color = _data.color;
			sprite.flipX = dirX < 0;
			sprite.flipY = dirY < 0;
		}
		
		return sprite;
	}
	
	function getGradient():FlxGraphic
	{
		// TODO: create this gradient using FlxGradient
		final gameWidth = FlxG.width;
		final gameHeight = FlxG.height;
		final source = FlxG.bitmap.add(GRADIENT_PATH).bitmap;
		final key = '$GRADIENT_PATH:${gameWidth}x${gameHeight}';
		
		var graphic = FlxG.bitmap.get(key);
		if (graphic == null)
		{
			final gradient = new BitmapData(Math.floor(gameWidth * 2.5), gameHeight, true, 0x0);
			
			// draw the gradient in the cleared area
			final matrix:Matrix = new Matrix();
			matrix.scale(gradient.width / source.width, gradient.height / source.height);
			gradient.draw(source, matrix, null, null, null, true);
			
			// Don't destroy transition bitmaps
			graphic = FlxG.bitmap.add(gradient, false, key);
			graphic.persist = true;
			graphic.destroyOnNoUse = false;
		}
		
		return graphic;
	}
	
	function finishTween(f:FlxTween):Void
	{
		delayThenFinish();
	}
}
