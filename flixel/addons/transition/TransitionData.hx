package flixel.addons.transition;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween.TweenOptions;
import flixel.util.FlxColor;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

@:enum
abstract TransitionType(String)
{
	var NONE = "none";
	var TILES = "tiles";
	var FADE = "fade";
}

typedef TransitionTileData = 
{
	asset:FlxGraphicAsset,
	width:Int,
	height:Int
}

/**
 * ...
 * @author larsiusprime
 */
class TransitionData implements IFlxDestroyable
{
	public var type:TransitionType;
	public var tileData:TransitionTileData;
	public var color:FlxColor;
	public var duration:Float = 1.0;
	public var direction:FlxPoint;
	public var tweenOptions:TweenOptions;
	
	public function destroy():Void
	{
		tileData = null;
		direction = null;
		tweenOptions.onComplete = null;
		tweenOptions.ease = null;
		tweenOptions = null;
	}
	
	public function new(TransType:TransitionType=FADE,Color:FlxColor=FlxColor.WHITE,Duration:Float=1.0,?Direction:FlxPoint,?TileData:TransitionTileData) 
	{
		type = TransType;
		tileData = TileData;
		duration = Duration;
		color = Color;
		direction = Direction;
		if (direction == null) { direction = new FlxPoint(0, 0); }
		FlxMath.bound(direction.x, -1, 1);
		FlxMath.bound(direction.y, -1, 1);
		tweenOptions = { onComplete: null };
	}
}
