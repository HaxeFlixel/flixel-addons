package flixel.addons.effects;

import flixel.animation.FlxAnimation;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxAssets;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;

/**
 * Nothing too fancy, just a handy little class to attach a trail effect to a FlxSprite.
 * Inspired by the way "Buck" from the inofficial #flixel IRC channel
 * creates a trail effect for the character in his game.
 * Feel free to use this class and adjust it to your needs.
 * @author Gama11
 */
class FlxTrail extends FlxSpriteGroup
{
	/**
	 * Stores the FlxSprite the trail is attached to.
	 */
	public var target(default, null):FlxSprite;

	/**
	 * How often to update the trail.
	 */
	public var delay:Int;

	/**
	 * Whether to check for X changes or not.
	 */
	public var xEnabled:Bool = true;

	/**
	 * Whether to check for Y changes or not.
	 */
	public var yEnabled:Bool = true;

	/**
	 * Whether to check for angle changes or not.
	 */
	public var rotationsEnabled:Bool = true;

	/**
	 * Whether to check for scale changes or not.
	 */
	public var scalesEnabled:Bool = true;

	/**
	 * Whether to check for frame changes of the "parent" FlxSprite or not.
	 */
	public var framesEnabled:Bool = true;

	/**
	 * Counts the frames passed.
	 */
	var _counter:Int = 0;

	/**
	 * How long is the trail?
	 */
	var _trailLength:Int = 0;

	/**
	 * Stores the trailsprite image.
	 */
	var _graphic:FlxGraphicAsset;

	/**
	 * The alpha value for the next trailsprite.
	 */
	var _transp:Float = 1;

	/**
	 * How much lower the alpha value of the next trailsprite is.
	 */
	var _difference:Float;

	var _recentPositions:Array<FlxPoint> = [];
	var _recentAngles:Array<Float> = [];
	var _recentScales:Array<FlxPoint> = [];
	var _recentFrames:Array<Int> = [];
	var _recentFlipX:Array<Bool> = [];
	var _recentFlipY:Array<Bool> = [];
	var _recentAnimations:Array<FlxAnimation> = [];

	/**
	 * Stores the sprite origin (rotation axis)
	 */
	var _spriteOrigin:FlxPoint;

	/**
	 * Creates a new FlxTrail effect for a specific FlxSprite.
	 *
	 * @param	Target		The FlxSprite the trail is attached to.
	 * @param  	Graphic		The image to use for the trailsprites. Optional, uses the sprite's graphic if null.
	 * @param	Length		The amount of trailsprites to create.
	 * @param	Delay		How often to update the trail. 0 updates every frame.
	 * @param	Alpha		The alpha value for the very first trailsprite.
	 * @param	Diff		How much lower the alpha of the next trailsprite is.
	 */
	public function new(Target:FlxSprite, ?Graphic:FlxGraphicAsset, Length:Int = 10, Delay:Int = 3, Alpha:Float = 0.4, Diff:Float = 0.05):Void
	{
		super();

		_spriteOrigin = FlxPoint.get().copyFrom(Target.origin);

		// Sync the vars
		target = Target;
		delay = Delay;
		_graphic = Graphic;
		_transp = Alpha;
		_difference = Diff;

		// Create the initial trailsprites
		increaseLength(Length);
		solid = false;
	}

	override public function destroy():Void
	{
		FlxDestroyUtil.putArray(_recentPositions);
		FlxDestroyUtil.putArray(_recentScales);

		_recentAngles = null;
		_recentPositions = null;
		_recentScales = null;
		_recentFrames = null;
		_recentFlipX = null;
		_recentFlipY = null;
		_recentAnimations = null;
		_spriteOrigin = null;

		target = null;
		_graphic = null;

		super.destroy();
	}

	/**
	 * Updates positions and other values according to the delay that has been set.
	 */
	override public function update(elapsed:Float):Void
	{
		// Count the frames
		_counter++;

		// Update the trail in case the intervall and there actually is one.
		if (_counter >= delay && _trailLength >= 1)
		{
			_counter = 0;

			// Push the current position into the positons array and drop one.
			var spritePosition:FlxPoint = null;
			if (_recentPositions.length == _trailLength)
			{
				spritePosition = _recentPositions.pop();
			}
			else
			{
				spritePosition = FlxPoint.get();
			}

			spritePosition.set(target.x - target.offset.x, target.y - target.offset.y);
			_recentPositions.unshift(spritePosition);

			// Also do the same thing for the Sprites angle if rotationsEnabled
			if (rotationsEnabled)
			{
				cacheValue(_recentAngles, target.angle);
			}

			// Again the same thing for Sprites scales if scalesEnabled
			if (scalesEnabled)
			{
				var spriteScale:FlxPoint = null; // sprite.scale;
				if (_recentScales.length == _trailLength)
				{
					spriteScale = _recentScales.pop();
				}
				else
				{
					spriteScale = FlxPoint.get();
				}

				spriteScale.set(target.scale.x, target.scale.y);
				_recentScales.unshift(spriteScale);
			}

			// Again the same thing for Sprites frames if framesEnabled
			if (framesEnabled && _graphic == null)
			{
				cacheValue(_recentFrames, target.animation.frameIndex);
				cacheValue(_recentFlipX, target.flipX);
				cacheValue(_recentFlipY, target.flipY);
				cacheValue(_recentAnimations, target.animation.curAnim);
			}

			// Now we need to update the all the Trailsprites' values
			var trailSprite:FlxSprite;

			for (i in 0..._recentPositions.length)
			{
				trailSprite = members[i];
				trailSprite.x = _recentPositions[i].x;
				trailSprite.y = _recentPositions[i].y;

				// And the angle...
				if (rotationsEnabled)
				{
					trailSprite.angle = _recentAngles[i];
					trailSprite.origin.x = _spriteOrigin.x;
					trailSprite.origin.y = _spriteOrigin.y;
				}

				// the scale...
				if (scalesEnabled)
				{
					trailSprite.scale.x = _recentScales[i].x;
					trailSprite.scale.y = _recentScales[i].y;
				}

				// and frame...
				if (framesEnabled && _graphic == null)
				{
					trailSprite.animation.frameIndex = _recentFrames[i];
					trailSprite.flipX = _recentFlipX[i];
					trailSprite.flipY = _recentFlipY[i];

					trailSprite.animation.curAnim = _recentAnimations[i];
				}

				// Is the trailsprite even visible?
				trailSprite.exists = true;
			}
		}

		super.update(elapsed);
	}

	function cacheValue<T>(array:Array<T>, value:T)
	{
		array.unshift(value);
		FlxArrayUtil.setLength(array, _trailLength);
	}

	public function resetTrail():Void
	{
		_recentPositions.splice(0, _recentPositions.length);
		_recentAngles.splice(0, _recentAngles.length);
		_recentScales.splice(0, _recentScales.length);
		_recentFrames.splice(0, _recentFrames.length);
		_recentFlipX.splice(0, _recentFlipX.length);
		_recentFlipY.splice(0, _recentFlipY.length);
		_recentAnimations.splice(0, _recentAnimations.length);

		for (i in 0...members.length)
		{
			if (members[i] != null)
			{
				members[i].exists = false;
			}
		}
	}

	/**
	 * A function to add a specific number of sprites to the trail to increase its length.
	 *
	 * @param 	Amount	The amount of sprites to add to the trail.
	 */
	public function increaseLength(Amount:Int):Void
	{
		// Can't create less than 1 sprite obviously
		if (Amount <= 0)
		{
			return;
		}

		_trailLength += Amount;

		// Create the trail sprites
		for (i in 0...Amount)
		{
			var trailSprite = new FlxSprite(0, 0);

			if (_graphic == null)
			{
				trailSprite.loadGraphicFromSprite(target);
			}
			else
			{
				trailSprite.loadGraphic(_graphic);
			}
			trailSprite.exists = false;
			add(trailSprite);
			trailSprite.alpha = _transp;
			_transp -= _difference;
			trailSprite.solid = solid;

			if (trailSprite.alpha <= 0)
			{
				trailSprite.kill();
			}
		}
	}

	/**
	 * In case you want to change the trailsprite image in runtime...
	 *
	 * @param 	Image	The image the sprites should load
	 */
	public function changeGraphic(Image:Dynamic):Void
	{
		_graphic = Image;

		for (i in 0..._trailLength)
		{
			members[i].loadGraphic(Image);
		}
	}

	/**
	 * Handy little function to change which events affect the trail.
	 *
	 * @param 	Angle 	Whether the trail reacts to angle changes or not.
	 * @param 	X 		Whether the trail reacts to x changes or not.
	 * @param 	Y 		Whether the trail reacts to y changes or not.
	 * @param	Scale	Wheater the trail reacts to scale changes or not.
	 */
	public function changeValuesEnabled(Angle:Bool, X:Bool = true, Y:Bool = true, Scale:Bool = true):Void
	{
		rotationsEnabled = Angle;
		xEnabled = X;
		yEnabled = Y;
		scalesEnabled = Scale;
	}
}
