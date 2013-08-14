package flixel.addons.nape;

import flixel.FlxSprite;
import flixel.system.input.touch.FlxTouch;
import flixel.util.FlxAngle;
import flixel.util.FlxPoint;
import nape.geom.Vec2;

/**
 * Some of the FlxVelocity functions, working with nape.
 */
class FlxNapeVelocity
{
	/**
	 * Sets the source FlxNapeSprite x/y velocity so it will move directly towards the destination FlxSprite at the speed given (in pixels per second)
	 * Timings are approximate due to the way Flash timers work, and irrespective of SWF frame rate. Allow for a variance of +- 50ms.
	 * The source object doesn't stop moving automatically should it ever reach the destination coordinates.
	 * @param	Source		The FlxNapeSprite on which the velocity will be set
	 * @param	Dest		The FlxSprite where the source object will move to
	 * @param	Speed		The speed it will move, in pixels per second (default is 100 pixels/sec)
	 */
	inline static public function moveTowardsObject(Source:FlxNapeSprite, Dest:FlxSprite, Speed:Float = 100):Void
	{
		var direction = FlxAngle.angleBetween(Source, Dest);
		Source.body.applyImpulse(Vec2.fromPolar(Speed, direction));
	}
	
	#if !FLX_NO_MOUSE
	/**
	 * Move the given FlxNapeSprite towards the mouse pointer coordinates at a steady velocity
	 * Timings are approximate due to the way Flash timers work, and irrespective of SWF frame rate. Allow for a variance of +- 50ms.
	 * The source object doesn't stop moving automatically should it ever reach the destination coordinates.
	 * @param	Source		The FlxNapeSprite to move
	 * @param	Speed		The speed it will move, in pixels per second (default is 100 pixels/sec)
	 */
	inline static public function moveTowardsMouse(Source:FlxNapeSprite, Speed:Float = 100):Void
	{
		var direction = FlxAngle.angleBetweenMouse(Source);
		Source.body.applyImpulse(Vec2.fromPolar(Speed, direction));
	}
	#end
	
	#if !FLX_NO_TOUCH
	/**
	 * Move the given FlxNapeSprite towards a FlxTouch point at a steady velocity
	 * Timings are approximate due to the way Flash timers work, and irrespective of SWF frame rate. Allow for a variance of +- 50ms.
	 * The source object doesn't stop moving automatically should it ever reach the destination coordinates.
	 * @param	Source			The FlxNapeSprite to move
	 * @param	Speed			The speed it will move, in pixels per second (default is 100 pixels/sec)
	 */
	inline static public function moveTowardsTouch(Source:FlxNapeSprite, Touch:FlxTouch, Speed:Float = 100):Void
	{
		var direction = FlxAngle.angleBetweenTouch(Source, Touch);
		Source.body.applyImpulse(Vec2.fromPolar(Speed, direction));
	}
	#end
	
	/**
	 * Sets the x/y velocity on the source FlxNapeSprite so it will move towards the target coordinates at the speed given (in pixels per second)
	 * Timings are approximate due to the way Flash timers work, and irrespective of SWF frame rate. Allow for a variance of +- 50ms.
	 * The source object doesn't stop moving automatically should it ever reach the destination coordinates.
	 * @param	Source		The FlxNapeSprite to move
	 * @param	Target		The FlxPoint coordinates to move the source FlxSprite towards
	 * @param	Speed		The speed it will move, in pixels per second (default is 100 pixels/sec)
	 */
	inline static public function moveTowardsPoint(Source:FlxNapeSprite, Target:FlxPoint, Speed:Float = 100):Void
	{
		var direction = FlxAngle.angleBetweenPoint(Source, Target);
		Source.body.applyImpulse(Vec2.fromPolar(Speed, direction));
	}
	
	/**
	 * Stops a FlxNapeSprite from moving by setting its velocity to 0, 0.
	 * @param	Source		The FlxNapeSprite to stop
	 */
	inline static public function stopVelocity(Source:FlxNapeSprite):Void
	{
		Source.body.velocity.set(Vec2.get(0, 0)); 
		Source.body.velocity.set(Vec2.get(0, 0)); 
	}
}