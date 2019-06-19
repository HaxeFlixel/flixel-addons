package flixel.addons.weapon;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxRect;

/**
 * @link http://www.photonstorm.com
 * @link http://www.haxeflixel.com
 * @author Richard Davey / Photon Storm
 * @author Touch added by Impaler / Beeblerox
 */
class FlxBullet extends FlxSprite
{
	// Acceleration or Velocity?
	public var accelerates:Bool = false;
	public var xAcceleration:Int;
	public var yAcceleration:Int;
	public var lifespan:Float;

	@:allow(flixel.addons.weapon)
	var bounds:FlxRect;

	public function new()
	{
		super(0, 0);
		exists = false;
	}

	override public function update(elapsed:Float):Void
	{
		if (lifespan > 0)
		{
			lifespan -= elapsed;

			if (lifespan <= 0)
			{
				kill();
			}
		}

		if (!FlxMath.pointInFlxRect(Math.floor(x), Math.floor(y), bounds))
		{
			kill();
		}

		super.update(elapsed);
	}
}
