package flixel.addons.transition;
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
	height:Int,
	horizontal:Int,
	vertical:Int
}

/**
 * ...
 * @author larsiusprime
 */
class TransitionData
{
	public var type:TransitionType;
	public var tileData:TransitionTileData;
	public var color:FlxColor;
	public var duration:Float = 1.0;
	public var tweenOptions:TweenOptions;
	
	public function new(TransType:TransitionType=FADE,Color:FlxColor=FlxColor.WHITE,?TileData:TransitionTileData) 
	{
		type = TransType;
		tileData = TileData;
		color = Color;
		if (TransType == TILES)
		{
			if (tileData == null)
			{
				tileData = {asset:null, vertical:1, horizontal:1, width:32, height:32};
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
