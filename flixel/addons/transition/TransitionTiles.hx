package flixel.addons.transition;

import flash.display.BitmapData;
import flixel.addons.transition.TransitionEffect;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

/**
 *
 * @author larsiusprime
 */
class TransitionTiles extends TransitionEffect
{
	var _grpSprites:FlxTypedSpriteGroup<FlxTransitionSprite>;
	var _isCenter:Bool = false;

	public function new(data:TransitionData)
	{
		super(data);

		_grpSprites = new FlxTypedSpriteGroup<FlxTransitionSprite>();
		var delay:Float = 0;

		if (data.tileData == null)
		{
			data.tileData = {asset: null, width: 32, height: 32};
		}

		var region = data.region;

		var tilesX:Int = Math.ceil(region.width / data.tileData.width);
		var tilesY:Int = Math.ceil(region.height / data.tileData.height);

		var maxTiles:Int = tilesX > tilesY ? tilesX : tilesY;

		var dTime:Float = data.duration / maxTiles;

		var xDelay:Float = dTime * Math.abs(data.direction.x);
		var yDelay:Float = dTime * Math.abs(data.direction.y);

		var addX:Int = data.tileData.width;
		var addY:Int = data.tileData.height;

		var tx:Int = 0;
		var ty:Int = 0;

		var startX:Int = Std.int(region.x);
		var startY:Int = Std.int(region.y);

		if (data.direction.x < 0)
		{
			addX *= -1;
			startX += Std.int(region.width + addX);
		}
		if (data.direction.y < 0)
		{
			addY *= -1;
			startY += Std.int(region.height + addY);
		}

		tx = startX;
		ty = startY;
		for (iy in 0...tilesY)
		{
			for (ix in 0...tilesX)
			{
				var frameRate:Int = 40;
				if (data.tileData.frameRate != null)
				{
					frameRate = data.tileData.frameRate;
				}
				var ts = new FlxTransitionSprite(tx, ty, delay, data.tileData.asset, data.tileData.width, data.tileData.height, frameRate);
				ts.color = data.color;
				ts.scrollFactor.set(0, 0);
				_grpSprites.add(ts);
				tx += addX;
				delay += xDelay;
			}
			ty += addY;
			tx = startX;
			delay = 0 + ((iy + 1) * yDelay);
		}
		add(_grpSprites);

		_isCenter = (data.direction.x == 0 && data.direction.y == 0);
	}

	public override function destroy():Void
	{
		super.destroy();
		_grpSprites = null;
	}

	public override function start(NewStatus:TransitionStatus):Void
	{
		super.start(NewStatus);

		_grpSprites.forEach(function(t:FlxTransitionSprite)
		{
			t.start(NewStatus);
		});
	}

	public override function setStatus(NewStatus:TransitionStatus):Void
	{
		super.setStatus(NewStatus);
		_grpSprites.forEach(function(t:FlxTransitionSprite)
		{
			t.setStatus(NewStatus);
		});
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (_started)
		{
			var allDone:Bool = true;
			for (sprite in _grpSprites.members)
			{
				if (sprite.status != TransitionStatus.NULL && sprite.status != _endStatus)
				{
					allDone = false;
					break;
				}
			}
			if (allDone)
			{
				_started = false;
				delayThenFinish();
			}
		}
	}
}
