package flixel.addons.display;

#if FLX_MOUSE
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

class FlxMouseSpring implements IFlxDestroyable
{
	public var sprite:FlxSprite;

	/**
	 * The tension of the spring, smaller numbers create springs closer to the mouse pointer
	 */
	public var tension:Float;

	/**
	 * The friction applied to the spring as it moves
	 */
	public var friction:Float;

	/**
	 * The constant downward force on the sprite (A negative value pulls up!)
	 */
	public var gravity:Float;

	/**
	 * The anchor point of the sprite, relative to its position, If null, the sprite's origin is used
	 */
	public var offset:FlxPoint;

	/**
	 * Whether to retain the velocity of the spring when the mouse is released. If false, it's cleared on release
	 */
	public var retainVelocity:Bool;
	
	@:deprecated("_retainVelocity is deprecated, use retainVelocity instead")
	var _retainVelocity(get, set):Bool;
	
	inline function get__retainVelocity():Bool
	{
		return retainVelocity;
	}
	
	inline function set__retainVelocity(value:Bool):Bool
	{
		return retainVelocity = value;
	}
	
	var velocity:FlxPoint = FlxPoint.get();
	var velY:Float;

	/**
	 * Adds a spring between the mouse and a FlxSprite
	 *
	 * @param   sprite          The FlxSprite to which this spring is attached
	 * @param   retainVelocity  True to retain the velocity of the spring when the mouse is released, or false to clear it
	 * @param   tension         The tension of the spring, smaller numbers create springs closer to the mouse pointer
	 * @param   friction        The friction applied to the spring as it moves
	 * @param   gravity         The constant downward force on the sprite (A negative value pulls up!)
	 * @param   offset          The anchor point of the sprite, relative to its position, If null,
	 *                          the sprite's origin is used. Note: A copy of the passed in point is used.
	 *                          
	 */
	public function new(sprite:FlxSprite, retainVelocity = false, tension = 0.1, friction = 0.95, gravity = 0.0, ?offset:FlxPoint)
	{
		this.sprite = sprite;
		this.retainVelocity = retainVelocity;
		this.tension = tension;
		this.friction = friction;
		this.gravity = gravity;
		
		if (offset != null)
		{
			this.offset = FlxPoint.get().copyFrom(offset);
			offset.putWeak();
		}
		else if (sprite is FlxExtendedMouseSprite)
		{
			final extSprite:FlxExtendedMouseSprite = cast sprite;
			this.offset = FlxPoint.get(extSprite.springOffsetX, extSprite.springOffsetY);
		}
	}

	/**
	 * Updates the spring physics and repositions the sprite
	 */
	public function update(elapsed:Float):Void
	{
		final offsetX = (offset == null ? offset.x : sprite.origin.x);
		final offsetY = (offset == null ? offset.y : sprite.origin.y);
		
		final disX = FlxG.mouse.x - (sprite.x + offsetX);
		final disY = FlxG.mouse.y - (sprite.y + offsetY);

		velocity.x += disX * tension;
		velocity.y += disY * tension;

		velocity.x *= friction;
		velocity.y += gravity;
		velocity.y *= friction;

		// TODO: use sprite.velocity
		sprite.x += velocity.x;
		sprite.y += velocity.y;
	}

	/**
	 * Resets the internal spring physics
	 */
	public function reset():Void
	{
		velocity.set(0, 0);
	}
	
	public function destroy()
	{
		sprite = null;
		offset = FlxDestroyUtil.put(offset);
		velocity = FlxDestroyUtil.put(velocity);
	}
}
#end
