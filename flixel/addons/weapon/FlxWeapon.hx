package flixel.addons.weapon;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxVelocity;
import flixel.sound.FlxSound;
import flixel.tile.FlxTilemap;
import flixel.util.FlxDestroyUtil;
import flixel.util.helpers.FlxBounds;
#if FLX_TOUCH
import flixel.input.touch.FlxTouch;
#end

/**
 * A Weapon can only fire 1 type of bullet.
 * A Player could fire multiple Weapons at the same time, however, if you need to layer them up.
 *
 * @version 1.3 - October 9th 2011
 * @link http://www.photonstorm.com
 * @link http://www.haxeflixel.com
 * @author Richard Davey / Photon Storm
 * @author Touch added by Impaler / Beeblerox
 *
 * TODO: Angled bullets
 * TODO: Multishot
 * TODO: Baked Rotation support for angled bullets
 * TODO: Bullet death styles (particle effects)
 * TODO: Bullet trails - blur FX style and Missile Command "draw lines" style? (could be another FX plugin)
 * TODO: Homing Missiles
 * TODO: Bullet uses random sprite from sprite sheet (for rainbow style bullets), or cycles through them in sequence?
 * TODO: Some Weapon base classes like shotgun, laser, etc?
 */
typedef FlxWeapon = FlxTypedWeapon<FlxBullet>;

class FlxTypedWeapon<TBullet:FlxBullet> implements IFlxDestroyable
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
	 * Internal name for this weapon (e.g., `"pulse rifle"`).
	 */
	public var name:String;

	/**
	 * The `FlxGroup` from which all the bullets for this weapon are drawn. This should be added to your display and collision-checked against it.
	 */
	public var group(default, null):FlxTypedGroup<TBullet>;

	/**
	 * The game tick after which the weapon will be able to fire. Only used if `fireRate > 0`.
	 * Internal variable; use with caution.
	 */
	public var nextFire:Int = 0;

	/**
	 * The delay in milliseconds (ms) between which each bullet is fired. Default is `0`, which means there is no delay.
	 */
	public var fireRate:Int = 0;

	/**
	 * When a bullet goes outside of these bounds, it will be automatically killed, freeing it up for firing again.
	 * TODO - Needs testing with a scrolling map (when not using single screen display)
	 */
	public var bounds:FlxRect;

	/**
	 * The parent sprite of this weapon. Only accessible when `fireFrom == PARENT`.
	 */
	public var parent(default, null):FlxSprite;

	/**
	 * Whether to fire bullets in the direction of the `parent`'s angle. Only accessible when `fireFrom == PARENT`.
	 */
	public var useParentDirection(default, set):Bool;

	/**
	 * A fixed position from which to fire the weapon, like in the game Missile Command. Only accessible when `fireFrom == POSITION`.
	 */
	public var firePosition(default, null):FlxBounds<FlxPoint>;

	/**
	 * A value used to offset a bullet's position when it is fired. Can be used to, for example, line a bullet up with the "nose" of a space ship.
	 * Only accessible when `fireFrom == PARENT`.
	 */
	@:deprecated("Use positionOffsetBounds instead")
	public var positionOffset(default, null):FlxPoint;

	/**
	 * A value used to offset a bullet's position when it is fired. Can be used to, for example,
	 * line a bullet up with the "nose" of a space ship. Only accessible when `fireFrom == PARENT`.
	 * @since 3.2.0
	 */
	public var positionOffsetBounds(default, null):FlxBounds<FlxPoint>;

	public var fireFrom(default, set):FlxWeaponFireFrom;
	public var speedMode:FlxWeaponSpeedMode;

	/**
	 * The lifespan of the bullet, given in seconds.
	 * The bullet will be killed once it passes this lifespan, if it is still alive and in bounds.
	 */
	public var bulletLifeSpan:FlxBounds<Float>;

	/**
	 * The elasticity of the fired bullet controls how much it rebounds off collision surfaces.
	 * Between `0` and `1` (`0` being no rebound, and `1` being 100% force rebound). Default is `0`.
	 */
	public var bulletElasticity:Float = 0;

	/**
	 * Whether to automatically set the bullet's angle when firing, such that it faces towards the target.
	 */
	public var rotateBulletTowardsTarget:Bool = false;

	/**
	 * A reference to the bullet that was last fired.
	 */
	public var currentBullet:TBullet;

	/**
	 * A function that is called immediately before a bullet is fired.
	 */
	public var onPreFireCallback:Void->Void;

	/**
	 * A function that is called immediately after a bullet is fired.
	 */
	public var onPostFireCallback:Void->Void;

	/**
	 * A sound that is played immediately before a bullet is fired.
	 */
	public var onPreFireSound:FlxSound;

	/**
	 * A sound that is played immediately after a bullet is fired.
	 */
	public var onPostFireSound:FlxSound;

	/**
	 * The factory function used to create new bullets.
	 */
	var bulletFactory:FlxTypedWeapon<TBullet>->TBullet;

	var skipParentCollision:Bool;

	/**
	 * A value used to offset a bullet's initial angle when it is fired.
	 */
	var angleOffset:Float = 0;

	/**
	 * Creates an `FlxWeapon` instance which can fire bullets.
	 * Use one of the `fireFrom...()` or `fireAt...()` functions to fire bullets.
	 *
	 * @param   name           The name of the weapon (e.g., `"laser"`, `"shotgun"`)
	 *                         For your internal reference really, but could be displayed in-game too.
	 * @param   bulletFactory  The factory function used to create new bullets.
	 * @param   fireFrom       The weapon's firing position (i.e., `PARENT`, `POSITION`).
	 * @param   speedMode      The speed mode for the bullets (i.e., `SPEED`, `ACCELERATION`).
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
	 * Internal function that handles the actual firing of the bullets.
	 *
	 * @param   mode  The mode to use for firing the bullet.
	 * @return  `true` if a bullet was fired, or `false` if one wasn't available.
	 * A reference to the last fired bullet is stored in `currentBullet`.
	 */
	function runFire(mode:FlxWeaponFireMode):Bool
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

		nextFire = FlxG.game.ticks + Std.int(fireRate / FlxG.timeScale);

		// Get a free bullet from the pool
		currentBullet = group.recycle(null, bulletFactory.bind(this));
		if (currentBullet == null)
		{
			return false;
		}

		// Clear any velocity that may have been previously set from the pool
		currentBullet.velocity.zero(); // TODO is this really necessary?

		switch (fireFrom)
		{
			case PARENT(parent, offset, useParentAngle, angleOffset):
				// store new offset in a new variable
				var actualOffset = FlxPoint.get(FlxG.random.float(offset.min.x, offset.max.x), FlxG.random.float(offset.min.y, offset.max.y));
				if (useParentAngle)
				{
					// rotate actual offset around parent origin using the parent angle
					rotatePoints(actualOffset, parent.origin, parent.angle, actualOffset);

					// reposition offset to have its origin at the new returned point
					actualOffset.subtract(currentBullet.width / 2, currentBullet.height / 2);
					actualOffset.subtract(parent.offset.x, parent.offset.y);
				}

				currentBullet.last.x = currentBullet.x = parent.x + actualOffset.x;
				currentBullet.last.y = currentBullet.y = parent.y + actualOffset.y;

				actualOffset.put();

			case POSITION(position):
				currentBullet.last.x = currentBullet.x = FlxG.random.float(position.min.x, position.max.x);
				currentBullet.last.y = currentBullet.y = FlxG.random.float(position.min.y, position.max.y);
		}

		currentBullet.exists = true;
		currentBullet.bounds = bounds;
		currentBullet.elasticity = bulletElasticity;
		currentBullet.lifespan = FlxG.random.float(bulletLifeSpan.min, bulletLifeSpan.max);

		switch (mode)
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
				internalFireFromAngle(currentBullet, parent.facing.degrees + FlxG.random.float(angle.min, angle.max));

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
	 * Calculates the new position for a point rotated around another point.
	 *
	 * @param   point    The point to be rotated.
	 * @param   origin   The point around which to be rotated. Usually the origin of the `parent`.
	 * @param   degrees  The angle by which to rotate `point` around `origin`. Usually the `parent`'s angle.
	 * @param   result   An optional point to reuse instead of getting another from the pool.
	 * @return  The new rotated point.
	 */
	public function rotatePoints(point:FlxPoint, origin:FlxPoint, degrees:Float, ?result:FlxPoint):FlxPoint
	{
		if (result == null)
			result = FlxPoint.get();

		final distanceTo = origin.distanceTo(point);
		final degreesTo = degrees + origin.distanceTo(point);

		result.setPolarDegrees(distanceTo, degreesTo);
		result.addPoint(origin);
		return result;
	}

	/**
	 * Fires a bullet (if one is available) based on the `facing` variable of the weapon's `parent`.
	 *
	 * @return  `true` if a bullet was fired, or `false` if one wasn't available.
	 * A reference to the last fired bullet is stored in `currentBullet`.
	 */
	public inline function fireFromParentFacing(angleNoise:FlxBounds<Float>):Bool
	{
		return runFire(FIRE_FROM_PARENT_FACING(angleNoise));
	}

	#if FLX_MOUSE
	/**
	 * Fires a bullet (if one is available) at the mouse coordinates,
	 * using the speed set in `speedMode` and the rate set in `fireRate`.
	 *
	 * @return  `true` if a bullet was fired, or `false` if one wasn't available.
	 * A reference to the last fired bullet is stored in `currentBullet`.
	 */
	public inline function fireAtMouse():Bool
	{
		return runFire(FIRE_AT_MOUSE);
	}
	#end

	#if FLX_TOUCH
	/**
	 * Fires a bullet (if one is available) at the `FlxTouch` coordinates,
	 * using the speed set in `speedMode` and the rate set in `fireRate`.
	 *
	 * @param   touch  The `FlxTouch` object to fire at. If `null`, uses the first available one.
	 * @return  `true` if a bullet was fired, or `false` if one wasn't available.
	 * A reference to the last fired bullet is stored in `currentBullet`.
	 */
	public function fireAtTouch(?touch:FlxTouch):Bool
	{
		var touch = touch == null ? FlxG.touches.getFirst() : touch;
		if (touch != null)
			return runFire(FIRE_AT_TOUCH(touch));
		else
			return false;
	}
	#end

	/**
	 * Fires a bullet (if one is available) at the given x/y coordinates,
	 * using the speed set in `speedMode` and the rate set in `fireRate`.
	 *
	 * @param   x  The x coordinate (in game world pixels) to fire at.
	 * @param   y  The y coordinate (in game world pixels) to fire at.
	 * @return  `true` if a bullet was fired, or `false` if one wasn't available.
	 * A reference to the last fired bullet is stored in `currentBullet`.
	 */
	public inline function fireAtPosition(x:Int, y:Int):Bool
	{
		return runFire(FIRE_AT_POSITION(x, y));
	}

	/**
	 * Fires a bullet (if one is available) at the given target's position,
	 * using the speed set in `speedMode` and the rate set in `fireRate`.
	 *
	 * @param   target  The `FlxSprite` to fire the bullet at.
	 * @return  `true` if a bullet was fired, or `false` if one wasn't available.
	 * A reference to the last fired bullet is stored in `currentBullet`.
	 */
	public inline function fireAtTarget(target:FlxSprite):Bool
	{
		return runFire(FIRE_AT_TARGET(target));
	}

	/**
	 * Fires a bullet (if one is available) based on the given angle.
	 *
	 * @param   angle  The angle (in degrees) calculated in clockwise positive direction
	 *                 (down = 90 degrees positive, right = 0 degrees positive, up = 90 degrees negative)
	 * @return  `true` if a bullet was fired, or `false` if one wasn't available.
	 * A reference to the last fired bullet is stored in `currentBullet`.
	 */
	public inline function fireFromAngle(angle:FlxBounds<Float>):Bool
	{
		return runFire(FIRE_FROM_ANGLE(angle));
	}

	/**
	 * Fires a bullet (if one is available) based on the angle of the weapon's `parent`.
	 *
	 * @return  `true` if a bullet was fired, or `false` if one wasn't available.
	 * A reference to the last fired bullet is stored in `currentBullet`.
	 */
	public inline function fireFromParentAngle(angle:FlxBounds<Float>):Bool
	{
		return runFire(FIRE_FROM_PARENT_ANGLE(angle));
	}

	/**
	 * Sets a pre-fire callback function and sound. These are played immediately before the bullet is fired.
	 *
	 * @param   callback  The function to call before a bullet is fired.
	 * @param   sound     An `FlxSound` to play before a bullet is fired.
	 */
	public function setPreFireCallback(?callback:Void->Void, ?sound:FlxSound):Void
	{
		onPreFireCallback = callback;
		onPreFireSound = sound;
	}

	/**
	 * Sets a post-fire callback function and sound. These are played immediately after the bullet is fired.
	 *
	 * @param   callback  The function to call after a bullet is fired.
	 * @param   sound     An `FlxSound` to play after a bullet is fired.
	 */
	public function setPostFireCallback(?callback:Void->Void, ?sound:FlxSound):Void
	{
		onPostFireCallback = callback;
		onPostFireSound = sound;
	}

	/**
	 * Checks whether the bullets are overlapping the specified object or group.
	 *
	 * @param  objectOrGroup   The object or group to check against.
	 * @param  notifyCallBack  A function that will get called if a bullet overlaps the object or group.
	 * @param  skipParent      Whether to ignore collisions with the parent of this weapon.
	 */
	public inline function bulletsOverlap(objectOrGroup:FlxBasic, ?notifyCallBack:FlxObject->FlxObject->Void, skipParent = true):Void
	{
		if (group != null && group.length > 0)
		{
			skipParentCollision = skipParent;
			FlxG.overlap(objectOrGroup, group, notifyCallBack != null ? notifyCallBack : onBulletHit, shouldBulletHit);
		}
	}

	function shouldBulletHit(object:FlxObject, bullet:FlxObject):Bool
	{
		if (parent == object && skipParentCollision)
		{
			return false;
		}

		if ((object is FlxTilemap))
		{
			return cast(object, FlxTilemap).overlapsWithCallback(bullet);
		}
		else
		{
			return true;
		}
	}

	function onBulletHit(object:FlxObject, bullet:FlxObject):Void
	{
		bullet.kill();
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
				velocity.put();

			case ACCELERATION(acceleration, maxSpeed):
				FlxVelocity.accelerateFromAngle(bullet, radians, FlxG.random.float(acceleration.min, acceleration.max),
					FlxG.random.float(maxSpeed.min, maxSpeed.max));
		}

		if (rotateBulletTowardsTarget)
		{
			bullet.angle = angleOffset + FlxAngle.asDegrees(radians);
		}
	}

	public function destroy():Void
	{
		name = null;
		group = FlxDestroyUtil.destroy(group);
		bounds = FlxDestroyUtil.put(bounds);
		parent = null; // Don't destroy the parent
		positionOffset = FlxDestroyUtil.put(positionOffset);
		if (positionOffsetBounds != null)
		{
			positionOffsetBounds.min = FlxDestroyUtil.put(positionOffsetBounds.min);
			positionOffsetBounds.max = FlxDestroyUtil.put(positionOffsetBounds.max);
			positionOffsetBounds = null;
		}
		if (firePosition != null)
		{
			firePosition.min = FlxDestroyUtil.put(firePosition.min);
			firePosition.max = FlxDestroyUtil.put(firePosition.max);
			firePosition = null;
		}
		if (fireFrom != null)
		{
			switch (fireFrom)
			{
				case PARENT(parent, offset, useParentAngle, angleOffset):
					parent = null;
					if (offset != null)
					{
						offset.min = FlxDestroyUtil.put(offset.min);
						offset.max = FlxDestroyUtil.put(offset.max);
						offset = null;
					}
					angleOffset = null;
				case POSITION(position):
					if (position != null)
					{
						position.min = FlxDestroyUtil.put(position.min);
						position.max = FlxDestroyUtil.put(position.max);
						position = null;
					}
			}
			// fireFrom = null; // Can't do this because sending null to set_fireFrom() causes an NPE
			@:bypassAccessor fireFrom = null;
		}
		if (speedMode != null)
		{
			switch (speedMode)
			{
				case SPEED(speed):
					speed = null;
				case ACCELERATION(acceleration, maxSpeed):
					acceleration = null;
					maxSpeed = null;
			}
			speedMode = null;
		}
		bulletLifeSpan = null;
		currentBullet = FlxDestroyUtil.destroy(currentBullet);
		onPreFireCallback = null;
		onPostFireCallback = null;
		onPreFireSound = null;
		onPostFireSound = null;
		bulletFactory = null;
	}

	function set_useParentDirection(v:Bool):Bool
	{
		switch (fireFrom)
		{
			case PARENT(parent, offset, useParentAngle, angleOffset):
				@:bypassAccessor fireFrom = PARENT(parent, offset, v, angleOffset);
			default:
		}
		return v;
	}

	function set_fireFrom(v:FlxWeaponFireFrom):FlxWeaponFireFrom
	{
		switch (v)
		{
			case PARENT(parent, offset, useParentAngle, angleOffset):
				this.parent = parent;
				// this.positionOffset = offset;
				this.positionOffsetBounds = offset;
				this.useParentDirection = useParentAngle;
				if (angleOffset != null)
					this.angleOffset = angleOffset;

				this.firePosition = null;

			case POSITION(position):
				this.firePosition = position;

				this.parent = null;
				this.positionOffset = null;
				this.positionOffsetBounds = null;

			default:
				this.parent = null;
				this.positionOffset = null;
				this.positionOffsetBounds = null;
				this.firePosition = null;
		}
		return fireFrom = v;
	}
}

enum FlxWeaponFireFrom
{
	/**
	 * @param   parent          The parent sprite of the weapon.
	 * @param   offset          A value used to offset a bullet's position when it is fired
	 *                          (e.g. to line a bullet up with the "nose" of a space ship).
	 * @param   useParentAngle  Whether to fire bullets in the direction of the `parent`'s angle.
	 * @param   angleOffset     A value used to offset a bullet's angle from the `parent`'s angle
	 *                          when it is fired.
	 */
	PARENT(parent:FlxSprite, offset:FlxBounds<FlxPoint>, ?useParentAngle:Bool, ?angleOffset:Float);

	/**
	 * @param   position  A fixed position from which to fire the weapon, like in the game Missile Command.
	 */
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
