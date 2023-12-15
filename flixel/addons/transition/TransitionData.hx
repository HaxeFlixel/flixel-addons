package flixel.addons.transition;

import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tweens.FlxTween.TweenOptions;
import flixel.util.FlxColor;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

enum abstract TransitionType(String)
{
	var NONE = "none";
	var TILES = "tiles";
	var FADE = "fade";
}

/**
 * Whether this transition will use a new camera, the top camera, or the default camera(s)
 * @since 3.3.0
 */
enum TransitionCameraMode
{
	/** The transition will use the current top-most camera, this is the default value */
	TOP;
	
	/** The transition will create and use a new camera above all others */
	NEW;
	
	/** The transition will use the default cameras */
	DEFAULT;
}

typedef TransitionTileData =
{
	asset:FlxGraphicAsset,
	width:Int,
	height:Int,
	?frameRate:Int
}

/**
 * @author larsiusprime
 */
class TransitionData implements IFlxDestroyable
{
	/** `NONE`, `TILE`, or `FADE` */
	public var type:TransitionType;
	
	/** The graphic to tile, when `TILE` type is used */
	public var tileData:TransitionTileData;
	
	/** The color of the transition */
	public var color:FlxColor;
	
	/** How long the transition will take */
	public var duration:Float = 1.0;
	
	/** Add a "wipe" effect to various transition styles */
	public var direction:FlxPoint;
	
	/** Used to override the options of the tween controlling this transtition */
	public var tweenOptions:TweenOptions;
	
	/** The area of the screen to display the transition */
	public var region:FlxRect;
	
	/**
	 * Whether this transition will use a new camera, the top camera, or the default camera
	 * @since 3.3.0
	 */
	public var cameraMode:TransitionCameraMode = TOP;
	
	public function destroy():Void
	{
		tileData = null;
		direction = null;
		tweenOptions = null;
		region = null;
		direction = null;
	}
	
	/**
	 * Used to define a transition for `FlxTransitionableState`
	 * 
	 * @param type          `NONE`, `TILE`, or `FADE`
	 * @param color         The color of the transition
	 * @param duration      How long the transition will take
	 * @param direction     Add a "wipe" effect to various transition styles
	 * @param tileData      The graphic to tile, when `TILE` type is used
	 * @param region        The area of the screen to display the transition
	 * @param cameraMode    Whether this transition will use a new camera, the top camera, or the default camera
	 */
	public function new(type = FADE, color = FlxColor.WHITE, duration = 1.0, ?direction:FlxPoint, ?tileData:TransitionTileData, ?region:FlxRect,
			cameraMode = TOP)
	{
		this.type = type;
		this.tileData = tileData;
		this.duration = duration;
		this.color = color;
		if (direction == null)
		{
			direction = new FlxPoint(0, 0);
		}
		else
		{
			direction.x = FlxMath.bound(direction.x, -1, 1);
			direction.y = FlxMath.bound(direction.y, -1, 1);
		}
		this.direction = direction;
		tweenOptions = {onComplete: null};
		if (region == null)
		{
			region = new FlxRect(0, 0, FlxG.width, FlxG.height);
		}
		this.region = region;
		this.cameraMode = cameraMode;
	}
}
