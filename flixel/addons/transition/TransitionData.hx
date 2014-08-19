package flixel.addons.transition;
import com.leveluplabs.tdrpg.IDestroyable;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween.TweenOptions;
import flixel.util.FlxColor;


@:enum
abstract TransitionType(String)
{
	var NONE = "none";
	var TILES = "tiles";
	var FADE = "fade";
}

typedef TransitionTileData = 
{
	asset:String,
	width:Int,
	height:Int
}

/**
 * ...
 * @author larsiusprime
 */
class TransitionData implements IDestroyable
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
		tweenOptions.complete = null;
		tweenOptions.ease = null;
		tweenOptions = null;
	}
	
	public function new(TransType:TransitionType=FADE,Color:FlxColor=FlxColor.WHITE,?Direction:FlxPoint,?TileData:TransitionTileData) 
	{
		type = TransType;
		tileData = TileData;
		color = Color;
		direction = Direction;
		if (direction == null) { direction = new FlxPoint(0, 0); }
		if (direction.x < -1) { direction.x = -1; } if (direction.x > 1) { direction.x = 1; }
		if (direction.y < -1) { direction.y = -1; } if (direction.y > 1) { direction.y = 1; }
		if (TransType == TILES)
		{
			if (tileData == null)
			{
				tileData = {asset:null, width:32, height:32};
			}
			if (tileData.asset == null || tileData.asset == "")
			{
				tileData.asset = "assets/images/transitions/diamond.png";
				tileData.width = 32;
				tileData.height = 32;
			}
		}
		tweenOptions = { complete:null };
	}
	
}
