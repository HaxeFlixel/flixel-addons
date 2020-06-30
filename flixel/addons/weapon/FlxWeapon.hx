package flixel.addons.weapon;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.weapon.FlxWeapon.FlxTypedWeapon;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.math.FlxRect;
import flixel.math.FlxVelocity;
import flixel.system.FlxSound;
import flixel.tile.FlxTilemap;
import flixel.util.helpers.FlxBounds;
import flixel.util.helpers.FlxRange;

/**
 * A Weapon can only fire 1 type of bullet. But it can fire many of them at once (in different directions if needed) via createBulletPattern
 * A Player could fire multiple Weapons at the same time however, if you need to layer them up
 *
 * @version 1.3 - October 9th 2011
 * @link http://www.photonstorm.com
 * @link http://www.haxeflixel.com
 * @author Richard Davey / Photon Storm
 * @author Touch added by Impaler / Beeblerox
 *
 * TODO: Angled bullets
 * TODO: multishot
 * TODO: Baked Rotation support for angled bullets
 * TODO: Bullet death styles (particle effects)
 * TODO: Bullet trails - blur FX style and Missile Command "draw lines" style? (could be another FX plugin)
 * TODO: Homing Missiles
 * TODO: Bullet uses random sprite from sprite sheet (for rainbow style bullets), or cycles through them in sequence?
 * TODO: Some Weapon base classes like shotgun, lazer, etc?
 */
typedef FlxWeapon = FlxTypedWeapon<FlxBullet>;

class FlxTypedWeapon<TBullet:FlxBullet>
{
	// Quick firing direction angle constants
	public static inline var BULLET_UP:Int = -90;
	public static inline var BULLET_DOWN:Int = 90;
	public static inline var BULLET_LEFT:Int = 180;
	public static inline var BULLET_RIGHT:Int = 0;
	public static inline var BULLET_NORTH_EAST:Int = -45;
	public static inline var BULLET_NORTH_WEST:Int = -135;
	public static inline var BULLET_SOUTH_EAST:Int = 45;
	public static inline var BULLET_SOUTH_WEST:Int = 135;

	/**
	 * Internal name for this weapon (i.e. "pulse rifle")
	 */
	public var name:String;

	/**
	 * The FlxGroup into which all the bullets for this weapon are drawn. This should be added to your display and collision checked against it.
	 */
	public var group(default, null):FlxTypedGroup<TBullet>;

	// Internal variables, use with caution
	public var nextFire:Int = 0;

	/**
	 * The delay in milliseconds (ms) between which each bullet is fired, set to zero to clear. By default there is no rate, as it can be controlled by FlxControl.setFireButton.
	 * However if you are firing using the mouse you may wish to set a firing rate.
	 */
	public var fireRate:Int = 0;

	/**
	 * When a bullet goes outside of this bounds it will be automatically killed, freeing it up for firing again.
	 * TODO - Needs testing with a scrolling map (when not using single screen display)
	 */
	public var bounds:FlxRect;

	/**
	 * Only accessible when fireFrom is "PARENT"
	 */
	public var parent(default, null):FlxSprite;

	/**
	 * If true, when fired the bullet direction is based on parent sprites facing value (up/down/left/right)
	 */
	public var useParentDirection:Bool;

	/**
	 * If parent is null, the Weapon will fire from a fixed x/y position on the screen, like in the game Missile Command.
	 */
	public var firePosition(default, null):FlxBounds<FlxPoint>;

	/**
	 * When the bullet is fired if you need to offset it on the x/y axis, for example to line it up with the "nose" of a space ship, set the amount here (positive or negative)
	 */
	public var positionOffset(default, null):FlxPoint;

	public var fireFrom(default, set):FlxWeaponFireFrom;
	public var speedMode:FlxWeaponSpeedMode;

	/**
	 * The lifespan of the bullet, given in seconds.
	 * The bullet will be killed once it passes this lifespan, if still alive and in bounds.
	 */
	public var bulletLifeSpan:FlxBounds<Float>;

	/**
	 * The elasticity of the fired bullet controls how much it rebounds off collision surfaces.
	 * Between 0 and 1 (0 being no rebound, 1 being 100% force rebound). Set to zero to disable.
	 */
	public var bulletElasticity:Float = 0;

	/**
	 * Auto set the bullet angle when firing, such that it faces towards the target
	 */
	public var rotateBulletTowardsTarget:Bool = false;

	/**
	 * A reference to the Bullet that was last fired
	 */
	public var currentBullet:TBullet;

	// Callbacks
	public var onPreFireCallback:Void->Void;
	public var onPostFireCallback:Void->Void;

	// Sounds
	public var onPreFireSound:FlxSound;
	public var onPostFireSound:FlxSound;

	/**
	 * The factory function to create a bullet
	 */
	var bulletFactory:FlxTypedWeapon<TBullet>->TBullet;

	var lastFired:Int = 0;

	var skipParentCollision:Bool;

	/**
	 * When the bullet is fired if you need to offset it's angle from the parent angle, for example if the bullet sprite is angle offsetted, only used when useParentAngle is true
	 */
	var angleOffset:Float = 0;

	/**
	 * Creates the FlxWeapon class which will fire your bullets.
	 * You should call one of the makeBullet functions to visually create the bullets.
	 * Then either use setDirection with fire() or one of the fireAt functions to launch them.
	 *
	 * @param	Name		The name of your weapon (i.e. "lazer" or "shotgun"). For your internal reference really, but could be displayed in-game.
	 * @param	BulletFactory	FlxWeapon uses this factory function to actually create a bullet
	 * @param	fireFrom	enum that describes the weapon firing position, for Example Parent, Position.
	 * @param	speedMode	enum that describes the bullets speed mode, for Example Velocity, Acceleration.
	 */
	public function new(name:String, bulletFactory:FlxTypedWeapon<TBullet>->TBullet, fireFrom:FlxWeaponFireFrom, speedMode:FlxWeaponSpeedMode)
	{
		group = new FlxTypedGroup();
		bounds = FlxRect.get(0, 0, FlxG.width, FlxG.height);
		bulletLifeSpan = new FlxBounds(0.0, 0);

		this.name = name;
		this.bulletFactory = bulletFactory;
		this.fireFrom = fireFrom;
		this.speedMode = speedMode;
	}

	/**
	 * Internal function that handles the actual firing of the bullets
	 *
	 * @param	Method
	 * @param	X
	 * @param	Y
	 * @param	Target
	 * @return	True if a bullet was fired or false if one wasn't available. The bullet last fired is stored in FlxWeapon.prevBullet
	 */
	function runFire(Mode:FlxWeaponFireMode):Bool
	{
		if (fireRate > 0 && FlxG.game.ticks < nextFire)
		{
			return false;
		}

		if (onPreFireCallback != null)
		{
			onPreFireCallback();
		}

		#if FLX_SOUND_SYSTEM
		if (onPreFireSound != null)
		{
			onPreFireSound.play();
		}
		#end

		lastFired = FlxG.game.ticks;
		nextFire = FlxG.game.ticks + Std.int(fireRate / FlxG.timeScale);

		// Get a free bullet from the pool
		currentBullet = group.recycle(null, bulletFactory.bind(this));
		if (currentBullet == null)
		{
			return false;
		}

		// Clear any velocity that may have been previously set from the pool
		currentBullet.velocity.x = 0; // TODO is this really necessary?
		currentBullet.velocity.y = 0;

		switch (fireFrom)
		{
			case PARENT(parent, offset, useParentDirection, angleOffset):
				// store new offset in a new variable
				var actualOffset = new FlxPoint(FlxG.random.float(offset.min.x, offset.max.x), FlxG.random.float(offset.min.y, offset.max.y));
				if (useParentDirection)
				{
					// rotate actual offset around parent origin using the parent angle
					actualOffset = rotatePoints(actualOffset, parent.origin, parent.angle);

					// reposition offset to have it's origin at the new returned point
					actualOffset.subtract(currentBullet.width / 2, currentBullet.height / 2);
					actualOffset.subtract(parent.offset.x, parent.offset.y);
				}

				currentBullet.last.x = currentBullet.x = parent.x + actualOffset.x;
				currentBullet.last.y = currentBullet.y = parent.y + actualOffset.y;

			case POSITION(position):
				currentBullet.last.x = currentBullet.x = FlxG.random.float(position.min.x, position.max.x);
				currentBullet.last.y = currentBullet.y = FlxG.random.float(position.min.y, position.max.y);
		}

		currentBullet.exists = true;
		currentBullet.bounds = bounds;
		currentBullet.elasticity = bulletElasticity;
		currentBullet.lifespan = FlxG.random.float(bulletLifeSpan.min, bulletLifeSpan.max);

		switch (Mode)
		{
			case FIRE_AT_POSITION(x, y):
				internalFireAtPoint(currentBullet, FlxPoint.weak(x, y));

			case FIRE_AT_TARGET(target):
				internalFireAtPoint(currentBullet, target.getPosition(FlxPoint.weak()));

			case FIRE_FROM_ANGLE(angle):
				internalFireFromAngle(currentBullet, FlxG.random.float(angle.min, angle.max));

			case FIRE_FROM_PARENT_ANGLE(angle):
				internalFireFromAngle(currentBullet, parent.angle + FlxG.random.float(angle.min, angle.max));

			case FIRE_FROM_PARENT_FACING(angle):
				internalFireFromAngle(currentBullet, FlxAngle.angleFromFacing(parent.facing, true) + FlxG.random.float(angle.min, angle.max));

			#if FLX_TOUCH
			case FIRE_AT_TOUCH(touch):
				internalFireAtPoint(currentBullet, touch.getPosition(FlxPoint.weak()));
			#end

			#if FLX_MOUSE
			case FIRE_AT_MOUSE:
				internalFireAtPoint(currentBullet, FlxG.mouse.getPosition(FlxPoint.weak()));
			#end
		}

		if (currentBullet.animation.getByName("fire") != null)
		{
			currentBullet.animation.play("fire");
		}

		// Post fire stuff
		if (onPostFireCallback != null)
		{
			onPostFireCallback();
		}

		#if FLX_SOUND_SYSTEM
		if (onPostFireSound != null)
		{
			onPostFireSound.play();
		}
		#end

		return true;
	}

	/**
	 * Calculates the new position for a point rotated around another point
	 *
	 * @param	point	The to be rotated point
	 * @param	origin	The to be rotated around point. usually the origin of the parent flxsprite
	 * @param	point	the current angle from of the origin. usually the parent angle.
	 * @return	The new rotated Point
	 */
	public function rotatePoints(point:FlxPoint, origin:FlxPoint, angle:Float):FlxPoint
	{
		var returnedPoint:FlxPoint = FlxPoint.weak();

		var inBetweenAngle:Float = origin.angleBetween(point) - 90;
		inBetweenAngle = angle + inBetweenAngle;
		var inBetweenDistance:Float = origin.distanceTo(point);

		returnedPoint.x = Math.cos(inBetweenAngle * Math.PI / 180) * inBetweenDistance;
		returnedPoint.y = Math.sin(inBetweenAngle * Math.PI / 180) * inBetweenDistance;
		return returnedPoint.add(origin.x, origin.y);
	}

	/**
	 * Fires a bullet (if one is available) based on the facing (UP/DOWN/LEFT/RIGHT) of the Weapons parent
	 *
	 * @return	True if a bullet was fired or false if one wasn't available. A reference to the bullet fired is stored in FlxWeapon.currentBullet.
	 */
	public inline function fireFromParentFacing(angleNoise:FlxBounds<Float>):Bool
	{
		return runFire(FIRE_FROM_PARENT_FACING(angleNoise));
	}

	#if FLX_MOUSE
	/**
	 * Fires a bullet (if one is available) at the mouse coordinates, using the speed set in setBulletSpeed and the rate set in setFireRate.
	 *
	 * @return	True if a bullet was fired or false if one wasn't available. A reference to the bullet fired is stored in FlxWeapon.currentBullet.
	 */
	public inline function fireAtMouse():Bool
	{
		return runFire(FIRE_AT_MOUSE);
	}
	#end

	#if FLX_TOUCH
	/**
	 * Fires a bullet (if one is available) at the FlxTouch coordinates, using the speed set in setBulletSpeed and the rate set in setFireRate.
	 *
	 * @param	Touch	The FlxTouch object to fire at, if null use the first available one
	 * @return	True if a bullet was fired or false if one wasn't available. A reference to the bullet fired is stored in FlxWeapon.currentBullet.
	 */
	public function fireAtTouch(?Touch:FlxTouch):Bool
	{
		var touch = Touch == null ? FlxG.touches.getFirst() : Touch;
		if (touch != null)
			return runFire(FIRE_AT_TOUCH(touch));
		else
			return false;
	}
	#end

	/**
	 * Fires a bullet (if one is available) at the given x/y coordinates, using the speed set in setBulletSpeed and the rate set in setFireRate.
	 *
	 * @param	X	The x coordinate (in game world pixels) to fire at
	 * @param	Y	The y coordinate (in game world pixels) to fire at
	 * @return	True if a bullet was fired or false if one wasn't available. A reference to the bullet fired is stored in FlxWeapon.currentBullet.
	 */
	public inline function fireAtPosition(X:Int, Y:Int):Bool
	{
		return runFire(FIRE_AT_POSITION(X, Y));
	}

	/**
	 * Fires a bullet (if one is available) at the given targets x/y coordinates, using the speed set in setBulletSpeed and the rate set in setFireRate.
	 *
	 * @param	Target	The FlxSprite you wish to fire the bullet at
	 * @return	True if a bullet was fired or false if one wasn't available. A reference to the bullet fired is stored in FlxWeapon.currentBullet.
	 */
	public inline function fireAtTarget(Target:FlxSprite):Bool
	{
		return runFire(FIRE_AT_TARGET(Target));
	}

	/**
	 * Fires a bullet (if one is available) based on the given angle
	 *
	 * @param	Angle	The angle (in degrees) calculated in clockwise positive direction (down = 90 degrees positive, right = 0 degrees positive, up = 90 degrees negative)
	 * @return	True if a bullet was fired or false if one wasn't available. A reference to the bullet fired is stored in FlxWeapon.currentBullet.
	 */
	public inline function fireFromAngle(angle:FlxBounds<Float>):Bool
	{
		return runFire(FIRE_FROM_ANGLE(angle));
	}

	/**
	 * Fires a bullet (if one is available) based on the angle of the Weapons parent
	 *
	 * @return	True if a bullet was fired or false if one wasn't available. A reference to the bullet fired is stored in FlxWeapon.currentBullet.
	 */
	public inline function fireFromParentAngle(angle:FlxBounds<Float>):Bool
	{
		return runFire(FIRE_FROM_PARENT_ANGLE(angle));
	}

	/**
	 * Sets a pre-fire callback function and sound. These are played immediately before the bullet is fired.
	 *
	 * @param	Callback	The function to call
	 * @param	Sound		A FlxSound to play
	 */
	public function setPreFireCallback(?Callback:Void->Void, ?Sound:FlxSound):Void
	{
		onPreFireCallback = Callback;
		onPreFireSound = Sound;
	}

	/**
	 * Sets a post-fire callback function and sound. These are played immediately after the bullet is fired.
	 *
	 * @param	Callback	The function to call
	 * @param	Sound		An FlxSound to play
	 */
	public function setPostFireCallback(?Callback:Void->Void, ?Sound:FlxSound):Void
	{
		onPostFireCallback = Callback;
		onPostFireSound = Sound;
	}

	/**
	 * Checks to see if the bullets are overlapping the specified object or group
	 *
	 * @param  ObjectOrGroup  	The group or object to check if bullets collide
	 * @param  NotifyCallBack  	A function that will get called if a bullet overlaps an object
	 * @param  SkipParent    	Don't trigger collision notifies with the parent of this object
	 */
	public inline function bulletsOverlap(ObjectOrGroup:FlxBasic, ?NotifyCallBack:FlxObject->FlxObject->Void, SkipParent:Bool = true):Void
	{
		if (group != null && group.length > 0)
		{
			skipParentCollision = SkipParent;
			FlxG.overlap(ObjectOrGroup, group, NotifyCallBack != null ? NotifyCallBack : onBulletHit, shouldBulletHit);
		}
	}

	function shouldBulletHit(Object:FlxObject, Bullet:FlxObject):Bool
	{
		if (parent == Object && skipParentCollision)
		{
			return false;
		}

		if ((Object is FlxTilemap))
		{
			return cast(Object, FlxTilemap).overlapsWithCallback(Bullet);
		}
		else
		{
			return true;
		}
	}

	function onBulletHit(Object:FlxObject, Bullet:FlxObject):Void
	{
		Bullet.kill();
	}

	function internalFireAtPoint(bullet:TBullet, point:FlxPoint):Void
	{
		switch (speedMode)
		{
			case SPEED(speed):
				FlxVelocity.moveTowardsPoint(bullet, point, FlxG.random.float(speed.min, speed.max));

			case ACCELERATION(acceleration, maxSpeed):
				FlxVelocity.accelerateTowardsPoint(bullet, point, FlxG.random.float(acceleration.min, acceleration.max),
					FlxG.random.float(maxSpeed.min, maxSpeed.max));
		}

		if (rotateBulletTowardsTarget)
		{
			bullet.angle = angleOffset + FlxAngle.angleBetweenPoint(bullet, point, true);
		}

		point.putWeak();
	}

	function internalFireFromAngle(bullet:TBullet, degrees:Float):Void
	{
		var radians = FlxAngle.asRadians(degrees);
		switch (speedMode)
		{
			case SPEED(speed):
				// TODO need to create a function: FlxVelocity.moveFromAngle(radians, speed);
				var velocity = FlxVelocity.velocityFromAngle(FlxAngle.asDegrees(radians), FlxG.random.float(speed.min, speed.max));
				bullet.velocity.x = velocity.x;
				bullet.velocity.y = velocity.y;

			case ACCELERATION(acceleration, maxSpeed):
				FlxVelocity.accelerateFromAngle(bullet, radians, FlxG.random.float(acceleration.min, acceleration.max),
					FlxG.random.float(maxSpeed.min, maxSpeed.max));
		}

		if (rotateBulletTowardsTarget)
		{
			bullet.angle = angleOffset + FlxAngle.asDegrees(radians);
		}
	}

	inline function set_fireFrom(v:FlxWeaponFireFrom):FlxWeaponFireFrom
	{
		switch (v)
		{
			case PARENT(parent, _, _, angleOffset):
				this.parent = parent;
				if (angleOffset != null)
					this.angleOffset = angleOffset;

			default:
				parent = null;
		}
		return fireFrom = v;
	}
}

enum FlxWeaponFireFrom
{
	PARENT(parent:FlxSprite, offset:FlxBounds<FlxPoint>, ?useParentAngle:Bool, ?angleOffset:Float);
	POSITION(position:FlxBounds<FlxPoint>);
}

enum FlxWeaponFireMode
{
	FIRE_AT_POSITION(x:Float, y:Float);
	FIRE_AT_TARGET(target:FlxSprite);
	FIRE_FROM_ANGLE(angle:FlxBounds<Float>);
	FIRE_FROM_PARENT_ANGLE(angleNoise:FlxBounds<Float>);
	FIRE_FROM_PARENT_FACING(angleNoise:FlxBounds<Float>);

	#if FLX_TOUCH
	FIRE_AT_TOUCH(touch:FlxTouch);
	#end
	#if FLX_MOUSE
	FIRE_AT_MOUSE;
	#end
}

enum FlxWeaponSpeedMode
{
	SPEED(speed:FlxBounds<Float>);
	ACCELERATION(acceleration:FlxBounds<Float>, maxSpeed:FlxBounds<Float>);
}
