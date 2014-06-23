package flixel.addons.weapon;

import flixel.addons.weapon.FlxWeapon.FlxTypedWeapon;
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
	public var weapon(default, null):FlxTypedWeapon<Dynamic>;
	
	@:allow(flixel.addons.weapon)
	private var bounds:FlxRect;
	
	public function new(Weapon:FlxTypedWeapon<Dynamic>)
	{
		super(0, 0);
		
		weapon = Weapon;
		
		exists = false;
	}
	
	public function postFire():Void
	{
		if (animation.getByName("fire") != null)
			animation.play("fire");
	}
	
	override public function update():Void
	{
		if (lifespan > 0)
		{
			lifespan -= FlxG.elapsed;
			
			if (lifespan <= 0)
			{
				kill();
			}
		}
		
		if (!FlxMath.pointInFlxRect(Math.floor(x), Math.floor(y), bounds))
		{
			kill();
		}
		
		super.update();
	}
}