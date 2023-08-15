package flixel.addons.plugin.control;

#if FLX_KEYBOARD
import openfl.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxVelocity;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end

/**
 *
 * Makes controlling an FlxSprite with the keyboard a LOT easier and quicker to set-up!
 * Sometimes it's hard to know what values to set, especially if you want gravity, jumping, sliding, etc.
 * This class helps sort that - and adds some cool extra functionality too :)
 *
 * TODO: Hot Keys
 * TODO: Binding of sound effects to keys (seperate from setSounds? as those are event based)
 * TODO: Specify animation frames to play based on velocity
 * TODO: Variable gravity (based on height, the higher the stronger the effect)
 *
 * @link http://www.photonstorm.com
 * @author Richard Davey / Photon Storm
 */
class FlxControlHandler
{
	/**
	 * The "Instant" Movement Type means the sprite will move at maximum speed instantly, and will not "accelerate" (or speed-up) before reaching that speed.
	 */
	public static inline var MOVEMENT_INSTANT:Int = 0;

	/**
	 * The "Accelerates" Movement Type means the sprite will accelerate until it reaches maximum speed.
	 */
	public static inline var MOVEMENT_ACCELERATES:Int = 1;

	/**
	 * The "Instant" Stopping Type means the sprite will stop immediately when no direction keys are being pressed, there will be no deceleration.
	 */
	public static inline var STOPPING_INSTANT:Int = 0;

	/**
	 * The "Decelerates" Stopping Type means the sprite will start decelerating when no direction keys are being pressed. Deceleration continues until the speed reaches zero.
	 */
	public static inline var STOPPING_DECELERATES:Int = 1;

	/**
	 * The "Never" Stopping Type means the sprite will never decelerate, any speed built up will be carried on and never reduce.
	 */
	public static inline var STOPPING_NEVER:Int = 2;

	/**
	 * The "Instant" Movement Type means the sprite will rotate at maximum speed instantly, and will not "accelerate" (or speed-up) before reaching that speed.
	 */
	public static inline var ROTATION_INSTANT:Int = 0;

	/**
	 * The "Accelerates" Rotaton Type means the sprite will accelerate until it reaches maximum rotation speed.
	 */
	public static inline var ROTATION_ACCELERATES:Int = 1;

	/**
	 * The "Instant" Stopping Type means the sprite will stop rotating immediately when no rotation keys are being pressed, there will be no deceleration.
	 */
	public static inline var ROTATION_STOPPING_INSTANT:Int = 0;

	/**
	 * The "Decelerates" Stopping Type means the sprite will start decelerating when no rotation keys are being pressed. Deceleration continues until rotation speed reaches zero.
	 */
	public static inline var ROTATION_STOPPING_DECELERATES:Int = 1;

	/**
	 * The "Never" Stopping Type means the sprite will never decelerate, any speed built up will be carried on and never reduce.
	 */
	public static inline var ROTATION_STOPPING_NEVER:Int = 2;

	/**
	 * This keymode fires for as long as the key is held down
	 */
	public static inline var KEYMODE_PRESSED:Int = 0;

	/**
	 * This keyboard fires when the key has just been pressed down, and not again until it is released and re-pressed
	 */
	public static inline var KEYMODE_JUST_DOWN:Int = 1;

	/**
	 * This keyboard fires only when the key has been pressed and then released again
	 */
	public static inline var KEYMODE_RELEASED:Int = 2;

	// Helpers
	public var isPressedUp:Bool = false;
	public var isPressedDown:Bool = false;
	public var isPressedLeft:Bool = false;
	public var isPressedRight:Bool = false;

	// Used by the FlxControl plugin
	public var enabled:Bool = false;

	static inline var DIAGONAL_COMPENSATION_FACTOR:Float = FlxMath.SQUARE_ROOT_OF_TWO * 0.5;

	var _entity:FlxSprite;

	var _bounds:Rectangle;

	var _up:Bool = false;
	var _down:Bool = false;
	var _left:Bool = false;
	var _right:Bool = false;

	var _fire:Bool;
	var _altFire:Bool;
	var _jump:Bool;
	var _altJump:Bool;
	var _xFacing:Bool;
	var _yFacing:Bool;
	var _rotateAntiClockwise:Bool;
	var _rotateClockwise:Bool;

	var _upMoveSpeed:Int;
	var _downMoveSpeed:Int;
	var _leftMoveSpeed:Int;
	var _rightMoveSpeed:Int;
	var _thrustSpeed:Int;
	var _reverseSpeed:Int;

	// Rotation
	var _thrustEnabled:Bool = false;
	var _reverseEnabled:Bool;
	var _isRotating:Bool = false;
	var _antiClockwiseRotationSpeed:Float;
	var _clockwiseRotationSpeed:Float;
	var _enforceAngleLimits:Bool = false;
	var _minAngle:Int;
	var _maxAngle:Int;
	var _capAngularVelocity:Bool;

	var _xSpeedAdjust:Float = 0;
	var _ySpeedAdjust:Float = 0;

	var _gravityX:Int = 0;
	var _gravityY:Int = 0;

	// The ms delay between firing when the key is held down
	var _fireRate:Int;
	// The internal time when they can next fire
	var _nextFireTime:Int = 0;
	// The internal time of when when they last fired
	var _lastFiredTime:Int;
	// The fire key mode
	var _fireKeyMode:Int;
	// A function to call every time they fire
	var _fireCallback:Void->Void;

	// The pixel height amount they jump (drag and gravity also both influence this)
	var _jumpHeight:Int;
	// The ms delay between jumping when the key is held down
	var _jumpRate:Int;
	// The jump key mode
	var _jumpKeyMode:Int;
	// The internal time when they can next jump
	var _nextJumpTime:Int;
	// The internal time of when when they last jumped
	var _lastJumpTime:Int;
	// A short window of opportunity for them to jump having just fallen off the edge of a surface
	var _jumpFromFallTime:Int;
	// Internal time of when they last collided with a valid jumpSurface
	var _extraSurfaceTime:Int;
	// The surfaces they can jump from (i.e. FLOOR)
	var _jumpSurface:Int;
	// A function to call every time they jump
	var _jumpCallback:Void->Void;

	var _movement:Int;
	var _stopping:Int;
	var _rotation:Int;
	var _rotationStopping:Int;
	var _capVelocity:Bool;
	// TODO
	var _hotkeys:Array<String>;

	var _upKey:String;
	var _downKey:String;
	var _leftKey:String;
	var _rightKey:String;
	var _fireKey:String;
	// TODO
	var _altFireKey:String;
	var _jumpKey:String;
	// TODO
	var _altJumpKey:String;
	var _antiClockwiseKey:String;
	var _clockwiseKey:String;
	var _thrustKey:String;
	var _reverseKey:String;

	// Invert movement on horizontal/vetical axis eg. pressing left moves right etc.

	/** @since 2.1.0 */
	public var invertX:Bool;

	/** @since 2.1.0 */
	public var invertY:Bool;

	// Sounds
	var _jumpSound:FlxSound;
	var _fireSound:FlxSound;
	var _walkSound:FlxSound;
	var _thrustSound:FlxSound;

	/**
	 * Sets the FlxSprite to be controlled by this class, and defines the initial movement and stopping types.
	 * After creating an instance of this class you should call setMovementSpeed, and one of the enableXControl functions if you need more than basic cursors.
	 *
	 * @param	sprite			The FlxSprite you want this class to control. It can only control one FlxSprite at once.
	 * @param	movementType	Set to either MOVEMENT_INSTANT or MOVEMENT_ACCELERATES
	 * @param	StoppingType	Set to STOPPING_INSTANT, STOPPING_DECELERATES or STOPPING_NEVER
	 * @param	updateFacing	If true it sets the FlxSprite.facing value to the direction pressed (default false)
	 * @param	enableArrowKeys	If true it will enable all arrow keys (default) - see setCursorControl for more fine-grained control
	 */
	public function new(sprite:FlxSprite, movementType:Int, stoppingType:Int, updateFacing:Bool = false, enableArrowKeys:Bool = true)
	{
		_entity = sprite;

		_movement = movementType;
		_stopping = stoppingType;

		_xFacing = updateFacing;
		_yFacing = updateFacing;

		_rotation = ROTATION_INSTANT;
		_rotationStopping = ROTATION_STOPPING_INSTANT;

		if (enableArrowKeys)
		{
			setCursorControl();
		}

		enabled = true;
		invertX = false;
		invertY = false;
	}

	/**
	 * Set the speed at which the sprite will move when a direction key is pressed.
	 * All values are given in pixels per second. So an xSpeed of 100 would move the sprite 100 pixels in 1 second (1000ms)
	 * Due to the nature of the internal Flash timer this amount is not 100% accurate and will vary above/below the desired distance by a few pixels.
	 *
	 * If you need different speed values for left/right or up/down then use setAdvancedMovementSpeed
	 *
	 * @param	speedX			The speed in pixels per second in which the sprite will move/accelerate horizontally
	 * @param	speedY			The speed in pixels per second in which the sprite will move/accelerate vertically
	 * @param	speedMaxX		The maximum speed in pixels per second in which the sprite can move horizontally
	 * @param	speedMaxY		The maximum speed in pixels per second in which the sprite can move vertically
	 * @param	decelerationX	A deceleration speed in pixels per second to apply to the sprites horizontal movement (default 0)
	 * @param	decelerationY	A deceleration speed in pixels per second to apply to the sprites vertical movement (default 0)
	 */
	public function setMovementSpeed(speedX:Int, speedY:Int, speedMaxX:Int, speedMaxY:Int, decelerationX:Int = 0, decelerationY:Int = 0):Void
	{
		_leftMoveSpeed = -speedX;
		_rightMoveSpeed = speedX;
		_upMoveSpeed = -speedY;
		_downMoveSpeed = speedY;

		setMaximumSpeed(speedMaxX, speedMaxY);
		setDeceleration(decelerationX, decelerationY);
	}

	/**
	 * If you know you need the same value for the acceleration, maximum speeds and (optionally) deceleration then this is a quick way to set them.
	 *
	 * @param	speed			The speed in pixels per second in which the sprite will move/accelerate/decelerate
	 * @param	acceleration	If true it will set the speed value as the deceleration value (default) false will leave deceleration disabled
	 */
	public function setStandardSpeed(speed:Int, acceleration:Bool = true):Void
	{
		if (acceleration)
		{
			setMovementSpeed(speed, speed, speed, speed, speed, speed);
		}
		else
		{
			setMovementSpeed(speed, speed, speed, speed);
		}
	}

	/**
	 * Set the speed at which the sprite will move when a direction key is pressed.
	 * All values are given in pixels per second. So an xSpeed of 100 would move the sprite 100 pixels in 1 second (1000ms)
	 * Due to the nature of the internal Flash timer this amount is not 100% accurate and will vary above/below the desired distance by a few pixels.
	 *
	 * If you don't need different speed values for every direction on its own then use setMovementSpeed
	 *
	 * @param	leftSpeed		The speed in pixels per second in which the sprite will move/accelerate to the left
	 * @param	rightSpeed		The speed in pixels per second in which the sprite will move/accelerate to the right
	 * @param	upSpeed			The speed in pixels per second in which the sprite will move/accelerate up
	 * @param	downSpeed		The speed in pixels per second in which the sprite will move/accelerate down
	 * @param	speedMaxX		The maximum speed in pixels per second in which the sprite can move horizontally
	 * @param	speedMaxY		The maximum speed in pixels per second in which the sprite can move vertically
	 * @param	decelerationX	Deceleration speed in pixels per second to apply to the sprites horizontal movement (default 0)
	 * @param	decelerationY	Deceleration speed in pixels per second to apply to the sprites vertical movement (default 0)
	 */
	public function setAdvancedMovementSpeed(leftSpeed:Int, rightSpeed:Int, upSpeed:Int, downSpeed:Int, speedMaxX:Int, speedMaxY:Int, decelerationX:Int = 0,
			decelerationY:Int = 0):Void
	{
		_leftMoveSpeed = -leftSpeed;
		_rightMoveSpeed = rightSpeed;
		_upMoveSpeed = -upSpeed;
		_downMoveSpeed = downSpeed;

		setMaximumSpeed(speedMaxX, speedMaxY);
		setDeceleration(decelerationX, decelerationY);
	}

	/**
	 * Set the speed at which the sprite will rotate when a direction key is pressed.
	 * Use this in combination with setMovementSpeed to create a Thrust like movement system.
	 * All values are given in pixels per second. So an xSpeed of 100 would rotate the sprite 100 pixels in 1 second (1000ms)
	 * Due to the nature of the internal Flash timer this amount is not 100% accurate and will vary above/below the desired distance by a few pixels.
	 */
	public function setRotationSpeed(antiClockwiseSpeed:Float, clockwiseSpeed:Float, speedMax:Float, deceleration:Float):Void
	{
		_antiClockwiseRotationSpeed = -antiClockwiseSpeed;
		_clockwiseRotationSpeed = clockwiseSpeed;

		setRotationKeys();
		setMaximumRotationSpeed(speedMax);
		setRotationDeceleration(deceleration);
	}

	/**
	 * Sets the rotation type and the rotation stopping type.
	 * 
	 * @param	rotationType The rotation type. Must be either `ROTATION_INSTANT` or `ROTATION_ACCELERATES`.
	 * @param	stoppingType The rotation stopping type. Must be `ROTATION_STOPPING_INSTANT`, `ROTATION_STOPPING_DECELERATES`, or `ROTATION_STOPPING_NEVER`.
	 */
	public function setRotationType(rotationType:Int, stoppingType:Int):Void
	{
		_rotation = rotationType;
		_rotationStopping = stoppingType;
	}

	/**
	 * Sets the maximum speed (in pixels per second) that the FlxSprite can rotate.
	 * When the FlxSprite is accelerating (movement type MOVEMENT_ACCELERATES) its speed won't increase above this value.
	 * However Flixel allows the velocity of an FlxSprite to be set to anything. So if you'd like to check the value and restrain it, then enable "limitVelocity".
	 *
	 * @param	speed			The maximum speed in pixels per second in which the sprite can rotate
	 * @param	limitVelocity	If true the angular velocity of the FlxSprite will be checked and kept within the limit. If false it can be set to anything.
	 */
	public function setMaximumRotationSpeed(speed:Float, limitVelocity:Bool = true):Void
	{
		_entity.maxAngular = speed;

		_capAngularVelocity = limitVelocity;
	}

	/**
	 * Deceleration is a speed (in pixels per second) that is applied to the sprite if stopping type is "DECELERATES" and if no rotation is taking place.
	 * The velocity of the sprite will be reduced until it reaches zero.
	 *
	 * @param	speed	The speed in pixels per second at which the sprite will have its angular rotation speed decreased
	 */
	public function setRotationDeceleration(speed:Float):Void
	{
		_entity.angularDrag = speed;
	}

	/**
	 * Set minimum and maximum angle limits that the Sprite won't be able to rotate beyond.
	 * Values must be between -180 and +180. 0 is pointing right, 90 down, 180 left, -90 up.
	 *
	 * @param	minimumAngle	Minimum angle below which the sprite cannot rotate (must be -180 or above)
	 * @param	maximumAngle	Maximum angle above which the sprite cannot rotate (must be 180 or below)
	 */
	public function setRotationLimits(minimumAngle:Int, maximumAngle:Int):Void
	{
		if (minimumAngle > maximumAngle || minimumAngle < -180 || maximumAngle > 180)
		{
			throw "FlxControlHandler setRotationLimits: Invalid Minimum / Maximum angle";
		}
		else
		{
			_enforceAngleLimits = true;
			_minAngle = minimumAngle;
			_maxAngle = maximumAngle;
		}
	}

	/**
	 * Disables rotation limits set in place by setRotationLimits()
	 */
	public function disableRotationLimits():Void
	{
		_enforceAngleLimits = false;
	}

	/**
	 * Set which keys will rotate the sprite. The speed of rotation is set in setRotationSpeed.
	 *
	 * @param	leftRight				Use the LEFT and RIGHT arrow keys for anti-clockwise and clockwise rotation respectively.
	 * @param	upDown					Use the UP and DOWN arrow keys for anti-clockwise and clockwise rotation respectively.
	 * @param	customAntiClockwise		The String value of your own key to use for anti-clockwise rotation (as taken from flixel.system.input.Keyboard)
	 * @param	customClockwise			The String value of your own key to use for clockwise rotation (as taken from flixel.system.input.Keyboard)
	 */
	public function setRotationKeys(leftRight:Bool = true, upDown:Bool = false, customAntiClockwise:String = "", customClockwise:String = ""):Void
	{
		_isRotating = true;
		_rotateAntiClockwise = true;
		_rotateClockwise = true;
		_antiClockwiseKey = "LEFT";
		_clockwiseKey = "RIGHT";

		if (upDown)
		{
			_antiClockwiseKey = "UP";
			_clockwiseKey = "DOWN";
		}

		if (customAntiClockwise != "" && customClockwise != "")
		{
			_antiClockwiseKey = customAntiClockwise;
			_clockwiseKey = customClockwise;
		}
	}

	/**
	 * If you want to enable a Thrust like motion for your sprite use this to set the speed and keys.
	 * This is usually used in conjunction with Rotation and it will over-ride anything already defined in setMovementSpeed.
	 *
	 * @param	thrustKey		Specify the key String (as taken from flixel.system.input.Keyboard) to use for the Thrust action
	 * @param	thrustSpeed		The speed in pixels per second which the sprite will move. Acceleration or Instant movement is determined by the Movement Type.
	 * @param	reverseKey		If you want to be able to reverse, set the key string as taken from flixel.system.input.Keyboard (defaults to null).
	 * @param	reverseSpeed	The speed in pixels per second which the sprite will reverse. Acceleration or Instant movement is determined by the Movement Type.
	 */
	public function setThrust(thrustKey:String, thrustSpeed:Float, ?reverseKey:String, reverseSpeed:Float = 0):Void
	{
		_thrustEnabled = false;
		_reverseEnabled = false;

		if (thrustKey != "")
		{
			_thrustKey = thrustKey;
			_thrustSpeed = Math.floor(thrustSpeed);
			_thrustEnabled = true;
		}

		if (reverseKey != null)
		{
			_reverseKey = reverseKey;
			_reverseSpeed = Math.floor(reverseSpeed);
			_reverseEnabled = true;
		}
	}

	/**
	 * Sets the maximum speed (in pixels per second) that the FlxSprite can move. You can set the horizontal and vertical speeds independantly.
	 * When the FlxSprite is accelerating (movement type MOVEMENT_ACCELERATES) its speed won't increase above this value.
	 * However Flixel allows the velocity of an FlxSprite to be set to anything. So if you'd like to check the value and restrain it, then enable "limitVelocity".
	 *
	 * @param	speedX			The maximum speed in pixels per second in which the sprite can move horizontally
	 * @param	speedY			The maximum speed in pixels per second in which the sprite can move vertically
	 * @param	limitVelocity	If true the velocity of the FlxSprite will be checked and kept within the limit. If false it can be set to anything.
	 */
	public function setMaximumSpeed(speedX:Int, speedY:Int, limitVelocity:Bool = true):Void
	{
		_entity.maxVelocity.x = speedX;
		_entity.maxVelocity.y = speedY;

		_capVelocity = limitVelocity;
	}

	/**
	 * Deceleration is a speed (in pixels per second) that is applied to the sprite if stopping type is "DECELERATES" and if no acceleration is taking place.
	 * The velocity of the sprite will be reduced until it reaches zero, and can be configured separately per axis.
	 *
	 * @param	speedX		The speed in pixels per second at which the sprite will have its horizontal speed decreased
	 * @param	speedY		The speed in pixels per second at which the sprite will have its vertical speed decreased
	 */
	public function setDeceleration(speedX:Int, speedY:Int):Void
	{
		_entity.drag.x = speedX;
		_entity.drag.y = speedY;
	}

	/**
	 * Gravity can be applied to the sprite, pulling it in any direction.
	 * Gravity is given in pixels per second and is applied as acceleration. The speed the sprite reaches under gravity will never exceed the Maximum Movement Speeds set.
	 * If you don't want gravity for a specific direction pass a value of zero.
	 *
	 * @param	forceX	A positive value applies gravity dragging the sprite to the right. A negative value drags the sprite to the left. Zero disables horizontal gravity.
	 * @param	forceY	A positive value applies gravity dragging the sprite down. A negative value drags the sprite up. Zero disables vertical gravity.
	 */
	public function setGravity(forceX:Int, forceY:Int):Void
	{
		_gravityX = forceX;
		_gravityY = forceY;

		_entity.acceleration.x = _gravityX;
		_entity.acceleration.y = _gravityY;
	}

	/**
	 * Switches the gravity applied to the sprite. If gravity was +400 Y (pulling them down) this will swap it to -400 Y (pulling them up)
	 * To reset call flipGravity again
	 */
	public function flipGravity():Void
	{
		if (!Math.isNaN(_gravityX) && _gravityX != 0)
		{
			_gravityX = -_gravityX;
			_entity.acceleration.x = _gravityX;
		}

		if (!Math.isNaN(_gravityY) && _gravityY != 0)
		{
			_gravityY = -_gravityY;
			_entity.acceleration.y = _gravityY;
		}
	}

	/**
	 * TODO
	 * Resets the X and Y speeds. Not yet implemented.
	 *
	 * @param	resetX	Whether to reset the X speed. Defaults to `true`.
	 * @param	resetY	Whether to reset the Y speed. Defaults to `true`.
	 */
	public function resetSpeeds(resetX:Bool = true, resetY:Bool = true):Void
	{
		if (resetX)
		{
			_xSpeedAdjust = 0;
		}

		if (resetY)
		{
			_ySpeedAdjust = 0;
		}
	}

	/**
	 * Set sound effects for the movement events jumping, firing, walking and thrust.
	 *
	 * @param	jump	The FlxSound to play when the user jumps
	 * @param	fire	The FlxSound to play when the user fires
	 * @param	walk	The FlxSound to play when the user walks
	 * @param	thrust	The FlxSound to play when the user thrusts
	 */
	public function setSounds(?jump:FlxSound, ?fire:FlxSound, ?walk:FlxSound, ?thrust:FlxSound):Void
	{
		if (jump != null)
		{
			_jumpSound = jump;
		}

		if (fire != null)
		{
			_fireSound = fire;
		}

		if (walk != null)
		{
			_walkSound = walk;
		}

		if (thrust != null)
		{
			_thrustSound = thrust;
		}
	}

	/**
	 * Enable a fire button
	 *
	 * @param	key				The key to use as the fire button (String from flixel.system.input.Keyboard, i.e. "SPACE", "CONTROL")
	 * @param	keymode			The FlxControlHandler KEYMODE value (KEYMODE_PRESSED, KEYMODE_JUST_DOWN, KEYMODE_RELEASED)
	 * @param	repeatDelay		Time delay in ms between which the fire action can repeat (0 means instant, 250 would allow it to fire approx. 4 times per second)
	 * @param	callback		A user defined function to call when it fires
	 * @param	altKey			Specify an alternative fire key that works AS WELL AS the primary fire key (TODO)
	 */
	public function setFireButton(key:String, keymode:Int, repeatDelay:Int, callback:Void->Void, altKey:String = ""):Void
	{
		_fireKey = key;
		_fireKeyMode = keymode;
		_fireRate = repeatDelay;
		_fireCallback = callback;

		if (altKey != "")
		{
			_altFireKey = altKey;
		}

		_fire = true;
	}

	/**
	 * Enable a jump button
	 *
	 * @param	key				The key to use as the jump button (String from flixel.system.input.Keyboard, i.e. "SPACE", "CONTROL")
	 * @param	keymode			The FlxControlHandler KEYMODE value (KEYMODE_PRESSED, KEYMODE_JUST_DOWN, KEYMODE_RELEASED)
	 * @param	height			The height in pixels/sec that the Sprite will attempt to jump (gravity and acceleration can influence this actual height obtained)
	 * @param	surface			A bitwise combination of all valid surfaces the Sprite can jump off (such as FLOOR)
	 * @param	repeatDelay		Time delay in ms between which the jumping can repeat (250 would be 4 times per second)
	 * @param	jumpFromFall	A time in ms that allows the Sprite to still jump even if it's just fallen off a platform, if still within ths time limit
	 * @param	callback		A user defined function to call when the Sprite jumps
	 * @param	altKey			Specify an alternative jump key that works AS WELL AS the primary jump key (TODO)
	 */
	public function setJumpButton(key:String, keymode:Int, height:Int, surface:Int, repeatDelay:Int = 250, jumpFromFall:Int = 0, ?callback:Void->Void,
			altKey:String = ""):Void
	{
		_jumpKey = key;
		_jumpKeyMode = keymode;
		_jumpHeight = height;
		_jumpSurface = surface;
		_jumpRate = repeatDelay;
		_jumpFromFallTime = jumpFromFall;
		_jumpCallback = callback;

		if (altKey != "")
		{
			_altJumpKey = altKey;
		}

		_jump = true;
	}

	/**
	 * Limits the sprite to only be allowed within this rectangle. If its x/y coordinates go outside it will be repositioned back inside.
	 * Coordinates should be given in GAME WORLD pixel values (not screen value, although often they are the two same things)
	 *
	 * @param	x		The x coordinate of the top left corner of the area (in game world pixels)
	 * @param	y		The y coordinate of the top left corner of the area (in game world pixels)
	 * @param	width	The width of the area (in pixels)
	 * @param	height	The height of the area (in pixels)
	 */
	public function setBounds(x:Int, y:Int, width:Int, height:Int):Void
	{
		_bounds = new Rectangle(x, y, width, height);
	}

	/**
	 * Clears any previously set sprite bounds
	 */
	public function removeBounds():Void
	{
		_bounds = null;
	}

	function moveUp():Bool
	{
		var move:Bool = false;

		if (FlxG.keys.anyPressed([invertY ? _downKey : _upKey]))
		{
			move = true;
			isPressedUp = true;

			if (_yFacing)
			{
				_entity.facing = UP;
			}

			if (_movement == MOVEMENT_INSTANT)
			{
				_entity.velocity.y = _upMoveSpeed;
			}
			else if (_movement == MOVEMENT_ACCELERATES)
			{
				_entity.acceleration.y = _upMoveSpeed;
			}

			if (_bounds != null && _entity.y < _bounds.top)
			{
				_entity.y = _bounds.top;
			}
		}

		return move;
	}

	function moveDown():Bool
	{
		var move:Bool = false;

		if (FlxG.keys.anyPressed([invertY ? _upKey : _downKey]))
		{
			move = true;
			isPressedDown = true;

			if (_yFacing)
			{
				_entity.facing = DOWN;
			}

			if (_movement == MOVEMENT_INSTANT)
			{
				_entity.velocity.y = _downMoveSpeed;
			}
			else if (_movement == MOVEMENT_ACCELERATES)
			{
				_entity.acceleration.y = _downMoveSpeed;
			}

			if (_bounds != null && _entity.y > _bounds.bottom)
			{
				_entity.y = _bounds.bottom;
			}
		}

		return move;
	}

	function moveLeft():Bool
	{
		var move:Bool = false;

		if (FlxG.keys.anyPressed([invertX ? _rightKey : _leftKey]))
		{
			move = true;
			isPressedLeft = true;

			if (_xFacing)
			{
				_entity.facing = LEFT;
			}

			if (_movement == MOVEMENT_INSTANT)
			{
				_entity.velocity.x = _leftMoveSpeed;
			}
			else if (_movement == MOVEMENT_ACCELERATES)
			{
				_entity.acceleration.x = _leftMoveSpeed;
			}

			if (_bounds != null && _entity.x < _bounds.x)
			{
				_entity.x = _bounds.x;
			}
		}

		return move;
	}

	function moveRight():Bool
	{
		var move:Bool = false;

		if (FlxG.keys.anyPressed([invertX ? _leftKey : _rightKey]))
		{
			move = true;
			isPressedRight = true;

			if (_xFacing)
			{
				_entity.facing = RIGHT;
			}

			if (_movement == MOVEMENT_INSTANT)
			{
				_entity.velocity.x = _rightMoveSpeed;
			}
			else if (_movement == MOVEMENT_ACCELERATES)
			{
				_entity.acceleration.x = _rightMoveSpeed;
			}

			if (_bounds != null && _entity.x > _bounds.right)
			{
				_entity.x = _bounds.right;
			}
		}

		return move;
	}

	function moveAntiClockwise():Bool
	{
		var move:Bool = false;

		if (FlxG.keys.anyPressed([_antiClockwiseKey]))
		{
			move = true;

			if (_rotation == ROTATION_INSTANT)
			{
				_entity.angularVelocity = _antiClockwiseRotationSpeed;
			}
			else if (_rotation == ROTATION_ACCELERATES)
			{
				_entity.angularAcceleration = _antiClockwiseRotationSpeed;
			}

			// TODO - Not quite there yet given the way Flixel can rotate to any valid int angle!
			if (_enforceAngleLimits)
			{
				// entity.angle = FlxAngle.angleLimit(entity.angle, minAngle, maxAngle);
			}
		}

		return move;
	}

	function moveClockwise():Bool
	{
		var move:Bool = false;

		if (FlxG.keys.anyPressed([_clockwiseKey]))
		{
			move = true;

			if (_rotation == ROTATION_INSTANT)
			{
				_entity.angularVelocity = _clockwiseRotationSpeed;
			}
			else if (_rotation == ROTATION_ACCELERATES)
			{
				_entity.angularAcceleration = _clockwiseRotationSpeed;
			}

			// TODO - Not quite there yet given the way Flixel can rotate to any valid int angle!
			if (_enforceAngleLimits)
			{
				// entity.angle = FlxAngle.angleLimit(entity.angle, minAngle, maxAngle);
			}
		}

		return move;
	}

	function moveThrust():Bool
	{
		var move:Bool = false;

		if (FlxG.keys.anyPressed([_thrustKey]))
		{
			move = true;

			var motion:FlxPoint = FlxVelocity.velocityFromAngle(Math.floor(_entity.angle), _thrustSpeed);

			if (_movement == MOVEMENT_INSTANT)
			{
				_entity.velocity.x = motion.x;
				_entity.velocity.y = motion.y;
			}
			else if (_movement == MOVEMENT_ACCELERATES)
			{
				_entity.acceleration.x = motion.x;
				_entity.acceleration.y = motion.y;
			}

			if (_bounds != null && _entity.x < _bounds.x)
			{
				_entity.x = _bounds.x;
			}
		}

		#if FLX_SOUND_SYSTEM
		if (move && _thrustSound != null)
		{
			_thrustSound.play(false);
		}
		#end

		return move;
	}

	function moveReverse():Bool
	{
		var move:Bool = false;

		if (FlxG.keys.anyPressed([_reverseKey]))
		{
			move = true;

			var motion:FlxPoint = FlxVelocity.velocityFromAngle(Math.floor(_entity.angle), _reverseSpeed);

			if (_movement == MOVEMENT_INSTANT)
			{
				_entity.velocity.x = -motion.x;
				_entity.velocity.y = -motion.y;
			}
			else if (_movement == MOVEMENT_ACCELERATES)
			{
				_entity.acceleration.x = -motion.x;
				_entity.acceleration.y = -motion.y;
			}

			if (_bounds != null && _entity.x < _bounds.x)
			{
				_entity.x = _bounds.x;
			}
		}

		return move;
	}

	function runFire():Bool
	{
		var fired:Bool = false;

		// 0 = Pressed
		// 1 = Just Down
		// 2 = Just Released
		if (((_fireKeyMode == 0) && FlxG.keys.anyPressed([_fireKey]))
			|| (_fireKeyMode == 1 && FlxG.keys.anyJustPressed([_fireKey]))
			|| (_fireKeyMode == 2 && FlxG.keys.anyJustReleased([_fireKey])))
		{
			if (_fireRate > 0)
			{
				if (FlxG.game.ticks > _nextFireTime)
				{
					_lastFiredTime = FlxG.game.ticks;
					_fireCallback();
					fired = true;
					_nextFireTime = _lastFiredTime + Std.int(_fireRate / FlxG.timeScale);
				}
			}
			else
			{
				_lastFiredTime = FlxG.game.ticks;
				_fireCallback();
				fired = true;
			}
		}

		#if FLX_SOUND_SYSTEM
		if (fired && _fireSound != null)
		{
			_fireSound.play(true);
		}
		#end

		return fired;
	}

	function runJump():Bool
	{
		var jumped:Bool = false;

		// This should be called regardless if they've pressed jump or not
		if (_entity.isTouching(_jumpSurface))
		{
			_extraSurfaceTime = FlxG.game.ticks + _jumpFromFallTime;
		}

		if ((_jumpKeyMode == KEYMODE_PRESSED && FlxG.keys.anyPressed([_jumpKey]))
			|| (_jumpKeyMode == KEYMODE_JUST_DOWN && FlxG.keys.anyJustPressed([_jumpKey]))
			|| (_jumpKeyMode == KEYMODE_RELEASED && FlxG.keys.anyJustReleased([_jumpKey])))
		{
			// Sprite not touching a valid jump surface
			if (_entity.isTouching(_jumpSurface) == false)
			{
				// They've run out of time to jump
				if (FlxG.game.ticks > _extraSurfaceTime)
				{
					return jumped;
				}
				else
				{
					// Still within the fall-jump window of time, but have jumped recently
					if (_lastJumpTime > (_extraSurfaceTime - _jumpFromFallTime))
					{
						return jumped;
					}
				}

				// If there is a jump repeat rate set and we're still less than it then return
				if (FlxG.game.ticks < _nextJumpTime)
				{
					return jumped;
				}
			}
			else
			{
				// If there is a jump repeat rate set and we're still less than it then return
				if (FlxG.game.ticks < _nextJumpTime)
				{
					return jumped;
				}
			}

			if (_gravityY > 0)
			{
				// Gravity is pulling them down to earth, so they are jumping up (negative)
				_entity.velocity.y = -_jumpHeight;
			}
			else
			{
				// Gravity is pulling them up, so they are jumping down (positive)
				_entity.velocity.y = _jumpHeight;
			}

			if (_jumpCallback != null)
			{
				_jumpCallback();
			}

			_lastJumpTime = FlxG.game.ticks;
			_nextJumpTime = _lastJumpTime + Std.int(_jumpRate / FlxG.timeScale);

			jumped = true;
		}

		#if FLX_SOUND_SYSTEM
		if (jumped && _jumpSound != null)
		{
			_jumpSound.play(true);
		}
		#end

		return jumped;
	}

	/**
	 * Called by the FlxControl plugin
	 */
	public function update(elapsed:Float):Void
	{
		if (_entity == null)
		{
			return;
		}

		// Reset the helper booleans
		isPressedUp = false;
		isPressedDown = false;
		isPressedLeft = false;
		isPressedRight = false;

		if (_stopping == STOPPING_INSTANT)
		{
			if (_movement == MOVEMENT_INSTANT)
			{
				_entity.velocity.x = 0;
				_entity.velocity.y = 0;
			}
			else if (_movement == MOVEMENT_ACCELERATES)
			{
				_entity.acceleration.x = 0;
				_entity.acceleration.y = 0;
			}
		}
		else if (_stopping == STOPPING_DECELERATES)
		{
			if (_movement == MOVEMENT_INSTANT)
			{
				_entity.velocity.x = 0;
				_entity.velocity.y = 0;
			}
			else if (_movement == MOVEMENT_ACCELERATES)
			{
				// By default these are zero anyway, so it's safe to set like this
				_entity.acceleration.x = _gravityX;
				_entity.acceleration.y = _gravityY;
			}
		}

		// Rotation
		if (_isRotating)
		{
			if (_rotationStopping == ROTATION_STOPPING_INSTANT)
			{
				if (_rotation == ROTATION_INSTANT)
				{
					_entity.angularVelocity = 0;
				}
				else if (_rotation == ROTATION_ACCELERATES)
				{
					_entity.angularAcceleration = 0;
				}
			}
			else if (_rotationStopping == ROTATION_STOPPING_DECELERATES)
			{
				if (_rotation == ROTATION_INSTANT)
				{
					_entity.angularVelocity = 0;
				}
			}

			var hasRotatedAntiClockwise:Bool = false;
			var hasRotatedClockwise:Bool = false;

			hasRotatedAntiClockwise = moveAntiClockwise();

			if (hasRotatedAntiClockwise == false)
			{
				hasRotatedClockwise = moveClockwise();
			}

			if (_rotationStopping == ROTATION_STOPPING_DECELERATES)
			{
				if (_rotation == ROTATION_ACCELERATES && hasRotatedAntiClockwise == false && hasRotatedClockwise == false)
				{
					_entity.angularAcceleration = 0;
				}
			}

			// If they have got instant stopping with acceleration and are NOT pressing a key, then stop the rotation. Otherwise we let it carry on
			if (_rotationStopping == ROTATION_STOPPING_INSTANT
				&& _rotation == ROTATION_ACCELERATES
				&& hasRotatedAntiClockwise == false
				&& hasRotatedClockwise == false)
			{
				_entity.angularVelocity = 0;
				_entity.angularAcceleration = 0;
			}
		}

		// Thrust
		if (_thrustEnabled || _reverseEnabled)
		{
			var moved:Bool = false;

			if (_thrustEnabled)
			{
				moved = moveThrust();
			}

			if (moved == false && _reverseEnabled)
			{
				moved = moveReverse();
			}
		}
		else
		{
			var movedX:Bool = false;
			var movedY:Bool = false;

			if (_up)
			{
				movedY = invertY ? moveDown() : moveUp();
			}

			if (_down && movedY == false)
			{
				movedY = invertY ? moveUp() : moveDown();
			}

			if (_left)
			{
				movedX = invertX ? moveRight() : moveLeft();
			}

			if (_right && movedX == false)
			{
				movedX = invertX ? moveLeft() : moveRight();
			}

			if (movedX && movedY)
			{
				if (_movement == MOVEMENT_INSTANT)
				{
					_entity.velocity.x *= DIAGONAL_COMPENSATION_FACTOR;
					_entity.velocity.y *= DIAGONAL_COMPENSATION_FACTOR;
				}
				else if (_movement == MOVEMENT_ACCELERATES)
				{
					_entity.acceleration.x *= DIAGONAL_COMPENSATION_FACTOR;
					_entity.acceleration.y *= DIAGONAL_COMPENSATION_FACTOR;
				}
			}
		}

		if (_fire)
		{
			runFire();
		}

		if (_jump)
		{
			runJump();
		}

		if (_capVelocity)
		{
			if (_entity.velocity.x > _entity.maxVelocity.x)
			{
				_entity.velocity.x = _entity.maxVelocity.x;
			}

			if (_entity.velocity.y > _entity.maxVelocity.y)
			{
				_entity.velocity.y = _entity.maxVelocity.y;
			}
		}

		#if FLX_SOUND_SYSTEM
		if (_walkSound != null)
		{
			if ((_movement == MOVEMENT_INSTANT && _entity.velocity.x != 0)
				|| (_movement == MOVEMENT_ACCELERATES && _entity.acceleration.x != 0))
			{
				_walkSound.play(false);
			}
			else
			{
				_walkSound.stop();
			}
		}
		#end
	}

	/**
	 * Sets Custom Key controls. Useful if none of the pre-defined sets work. All String values should be taken from flixel.system.input.Keyboard
	 * Pass a blank (empty) String to disable that key from being checked.
	 *
	 * @param	customUpKey		The String to use for the Up key.
	 * @param	customDownKey	The String to use for the Down key.
	 * @param	customLeftKey	The String to use for the Left key.
	 * @param	customRightKey	The String to use for the Right key.
	 */
	public function setCustomKeys(customUpKey:String, customDownKey:String, customLeftKey:String, customRightKey:String):Void
	{
		if (customUpKey != "")
		{
			_up = true;
			_upKey = customUpKey;
		}

		if (customDownKey != "")
		{
			_down = true;
			_downKey = customDownKey;
		}

		if (customLeftKey != "")
		{
			_left = true;
			_leftKey = customLeftKey;
		}

		if (customRightKey != "")
		{
			_right = true;
			_rightKey = customRightKey;
		}
	}

	/**
	 * Enables Cursor/Arrow Key controls. Can be set on a per-key basis. Useful if you only want to allow a few keys.
	 * For example in a Space Invaders game you'd only enable LEFT and RIGHT.
	 *
	 * @param	allowUp		Enable the UP key
	 * @param	allowDown	Enable the DOWN key
	 * @param	allowLeft	Enable the LEFT key
	 * @param	allowRight	Enable the RIGHT key
	 */
	public function setCursorControl(allowUp:Bool = true, allowDown:Bool = true, allowLeft:Bool = true, allowRight:Bool = true):Void
	{
		_up = allowUp;
		_down = allowDown;
		_left = allowLeft;
		_right = allowRight;

		_upKey = "UP";
		_downKey = "DOWN";
		_leftKey = "LEFT";
		_rightKey = "RIGHT";
	}

	/**
	 * Enables WASD controls. Can be set on a per-key basis. Useful if you only want to allow a few keys.
	 * For example in a Space Invaders game you'd only enable LEFT and RIGHT.
	 *
	 * @param	allowUp		Enable the up (W) key
	 * @param	allowDown	Enable the down (S) key
	 * @param	allowLeft	Enable the left (A) key
	 * @param	allowRight	Enable the right (D) key
	 */
	public function setWASDControl(allowUp:Bool = true, allowDown:Bool = true, allowLeft:Bool = true, allowRight:Bool = true):Void
	{
		_up = allowUp;
		_down = allowDown;
		_left = allowLeft;
		_right = allowRight;

		_upKey = "W";
		_downKey = "S";
		_leftKey = "A";
		_rightKey = "D";
	}

	/**
	 * Enables ESDF (home row) controls. Can be set on a per-key basis. Useful if you only want to allow a few keys.
	 * For example in a Space Invaders game you'd only enable LEFT and RIGHT.
	 *
	 * @param	allowUp		Enable the up (E) key
	 * @param	allowDown	Enable the down (D) key
	 * @param	allowLeft	Enable the left (S) key
	 * @param	allowRight	Enable the right (F) key
	 */
	public function setESDFControl(allowUp:Bool = true, allowDown:Bool = true, allowLeft:Bool = true, allowRight:Bool = true):Void
	{
		_up = allowUp;
		_down = allowDown;
		_left = allowLeft;
		_right = allowRight;

		_upKey = "E";
		_downKey = "D";
		_leftKey = "S";
		_rightKey = "F";
	}

	/**
	 * Enables IJKL (right-sided or secondary player) controls. Can be set on a per-key basis. Useful if you only want to allow a few keys.
	 * For example in a Space Invaders game you'd only enable LEFT and RIGHT.
	 *
	 * @param	allowUp		Enable the up (I) key
	 * @param	allowDown	Enable the down (K) key
	 * @param	allowLeft	Enable the left (J) key
	 * @param	allowRight	Enable the right (L) key
	 */
	public function setIJKLControl(allowUp:Bool = true, allowDown:Bool = true, allowLeft:Bool = true, allowRight:Bool = true):Void
	{
		_up = allowUp;
		_down = allowDown;
		_left = allowLeft;
		_right = allowRight;

		_upKey = "I";
		_downKey = "K";
		_leftKey = "J";
		_rightKey = "L";
	}

	/**
	 * Enables HJKL (Rogue / Net-Hack) controls. Can be set on a per-key basis. Useful if you only want to allow a few keys.
	 * For example in a Space Invaders game you'd only enable LEFT and RIGHT.
	 *
	 * @param	allowUp		Enable the up (K) key
	 * @param	allowDown	Enable the down (J) key
	 * @param	allowLeft	Enable the left (H) key
	 * @param	allowRight	Enable the right (L) key
	 */
	public function setHJKLControl(allowUp:Bool = true, allowDown:Bool = true, allowLeft:Bool = true, allowRight:Bool = true):Void
	{
		_up = allowUp;
		_down = allowDown;
		_left = allowLeft;
		_right = allowRight;

		_upKey = "K";
		_downKey = "J";
		_leftKey = "H";
		_rightKey = "L";
	}

	/**
	 * Enables ZQSD (Azerty keyboard) controls. Can be set on a per-key basis. Useful if you only want to allow a few keys.
	 * For example in a Space Invaders game you'd only enable LEFT and RIGHT.
	 *
	 * @param	allowUp		Enable the up (Z) key
	 * @param	allowDown	Enable the down (Q) key
	 * @param	allowLeft	Enable the left (S) key
	 * @param	allowRight	Enable the right (D) key
	 */
	public function setZQSDControl(allowUp:Bool = true, allowDown:Bool = true, allowLeft:Bool = true, allowRight:Bool = true):Void
	{
		_up = allowUp;
		_down = allowDown;
		_left = allowLeft;
		_right = allowRight;

		_upKey = "Z";
		_downKey = "S";
		_leftKey = "Q";
		_rightKey = "D";
	}

	/**
	 * Enables Dvoark Simplified Controls. Can be set on a per-key basis. Useful if you only want to allow a few keys.
	 * For example in a Space Invaders game you'd only enable LEFT and RIGHT.
	 *
	 * @param	allowUp		Enable the up (COMMA) key
	 * @param	allowDown	Enable the down (A) key
	 * @param	allowLeft	Enable the left (O) key
	 * @param	allowRight	Enable the right (E) key
	 */
	public function setDvorakSimplifiedControl(allowUp:Bool = true, allowDown:Bool = true, allowLeft:Bool = true, allowRight:Bool = true):Void
	{
		_up = allowUp;
		_down = allowDown;
		_left = allowLeft;
		_right = allowRight;

		_upKey = "COMMA";
		_downKey = "O";
		_leftKey = "A";
		_rightKey = "E";
	}

	/**
	 * Enables Numpad (left-handed) Controls. Can be set on a per-key basis. Useful if you only want to allow a few keys.
	 * For example in a Space Invaders game you'd only enable LEFT and RIGHT.
	 *
	 * @param	allowUp		Enable the up (NUMPADEIGHT) key
	 * @param	allowDown	Enable the down (NUMPADTWO) key
	 * @param	allowLeft	Enable the left (NUMPADFOUR) key
	 * @param	allowRight	Enable the right (NUMPADSIX) key
	 */
	public function setNumpadControl(allowUp:Bool = true, allowDown:Bool = true, allowLeft:Bool = true, allowRight:Bool = true):Void
	{
		_up = allowUp;
		_down = allowDown;
		_left = allowLeft;
		_right = allowRight;

		_upKey = "NUMPADEIGHT";
		_downKey = "NUMPADTWO";
		_leftKey = "NUMPADFOUR";
		_rightKey = "NUMPADSIX";
	}
}
#end
