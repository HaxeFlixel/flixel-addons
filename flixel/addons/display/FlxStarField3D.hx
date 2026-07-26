/**
 * The logic in this module is largely ported from StarfieldFX.as by Richard Davey / photonstorm
 * @see https://github.com/photonstorm/Flixel-Power-Tools/blob/master/src/org/flixel/plugin/photonstorm/FX/StarfieldFX.as
 */

package flixel.addons.display;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

class FlxStarField3D extends FlxStarField
{
	public var center(default, null):FlxPoint;

	public function new(x = 0, y = 0, width = 0, height:Int = 0, starAmount:Int = 300)
	{
		super(x, y, width, height, starAmount);
		center = FlxPoint.get(width / 2, height / 2);
		setStarDepthColors(300, 0xff292929, 0xffffffff);
		setStarSpeed(0, 200);
	}

	override public function destroy():Void
	{
		center = FlxDestroyUtil.put(center);
		super.destroy();
	}

	override public function update(elapsed:Float):Void
	{
		for (star in _stars)
		{
			star.d *= 1.1;
			star.x = center.x + ((Math.cos(star.r) * star.d) * star.speed) * elapsed;
			star.y = center.y + ((Math.sin(star.r) * star.d) * star.speed) * elapsed;

			if ((star.x < 0) || (star.x > width) || (star.y < 0) || (star.y > height))
			{
				star.d = 1;
				star.r = FlxG.random.float() * Math.PI * 2;
				star.x = 0;
				star.y = 0;
				star.speed = FlxG.random.float(_minSpeed, _maxSpeed);

				_stars[star.index] = star;
			}
		}

		super.update(elapsed);
	}
}