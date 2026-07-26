/**
 * The logic in this module is largely ported from StarfieldFX.as by Richard Davey / photonstorm
 * @see https://github.com/photonstorm/Flixel-Power-Tools/blob/master/src/org/flixel/plugin/photonstorm/FX/StarfieldFX.as
 */

package flixel.addons.display;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

class FlxStarField2D extends FlxStarField
{
	public var starVelocityOffset(default, null):FlxPoint;

	public function new(x = 0, y = 0, width = 0, height = 0, starAmount = 300)
	{
		super(x, y, width, height, starAmount);
		starVelocityOffset = FlxPoint.get(-1, 0);
		setStarDepthColors(5, 0xff585858, 0xffF4F4F4);
		setStarSpeed(100, 400);
	}

	override public function destroy():Void
	{
		starVelocityOffset = FlxDestroyUtil.put(starVelocityOffset);
		super.destroy();
	}

	override public function update(elapsed:Float):Void
	{
		for (star in _stars)
		{
			star.x += (starVelocityOffset.x * star.speed) * elapsed;
			star.y += (starVelocityOffset.y * star.speed) * elapsed;

			// wrap the star
			if (star.x > width)
			{
				star.x = 0;
			}
			else if (star.x < 0)
			{
				star.x = width;
			}

			if (star.y > height)
			{
				star.y = 0;
			}
			else if (star.y < 0)
			{
				star.y = height;
			}
		}

		super.update(elapsed);
	}
}