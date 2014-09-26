package flixel.addons.transition;

import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxTimer;
import openfl.display.BitmapData;

@:bitmap("assets/images/transitions/circle.png") class GraphicTransTileCircle extends BitmapData { }
@:bitmap("assets/images/transitions/diamond.png") class GraphicTransTileDiamond extends BitmapData { }
@:bitmap("assets/images/transitions/square.png") class GraphicTransTileSquare extends BitmapData { }

/**
 * 
 * @author Tim Hely
 */
class FlxTransitionSprite extends FlxSprite
{
	private var _frameRate:Int = 0;
	private var _delay:Float;
	public var status:TransitionStatus = IN;
	private var _newStatus:TransitionStatus = NULL;
	
	public function new(X:Float = 0, Y:Float = 0, Delay:Float, Graphic:FlxGraphicAsset = null, GraphicWidth:Int = 32, GraphicHeight:Int = 32, FrameRate:Int = 40) 
	{
		super(X, Y);
		
		if (Graphic == null)
		{
			Graphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
			GraphicWidth = 32;
			GraphicHeight = 32;
		}
		
		_delay = Delay;
		_frameRate = FrameRate;
		loadGraphic(Graphic, true, GraphicWidth, GraphicHeight);
	}
	
	override public function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String):FlxSprite 
	{
		super.loadGraphic(Graphic, Animated, Width, Height, Unique, Key);
		
		animation.add("empty", [0], 0, false);
		
		var inArray:Array<Int> = [];
		var outArray:Array<Int> = [];
		for (i in 1...(numFrames - 1))
		{
			inArray.push(i);
		}
		outArray = inArray.copy();
		outArray.reverse();
		
		FlxG.log.warn(inArray);
		
		animation.add("in", inArray, _frameRate, false);
		animation.add("full", [numFrames - 1], 0, false);
		animation.add("out", outArray, _frameRate, false);
		setStatus(FULL);
		
		return this;
	}
	
	public function start(NewStatus:TransitionStatus):Void
	{
		new FlxTimer(_delay, onTimer);
		_newStatus = NewStatus;
	}
	
	private function startStatus(NewStatus:TransitionStatus):Void
	{
		setStatus(NewStatus);
	}
	
	public function setStatus(Status:TransitionStatus):Void
	{
		var anim:String = switch (Status) 
		{
			case IN: "in";
			case OUT: "out";
			case EMPTY,NULL: "empty";
			case FULL: "full";
		}
		
		FlxG.log.warn(Status);
		FlxG.log.warn(anim);
		
		animation.play(anim);
		status = Status;
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		if (animation.finished)
		{
			switch (status) 
			{
				case IN:	setStatus(FULL);
				case OUT:	setStatus(EMPTY);
				default:
			}
		}
	}
	
	private function onTimer(f:FlxTimer = null):Void
	{
		setStatus(_newStatus);
		_newStatus = NULL;
	}
}

@:enum
abstract TransitionStatus(Int)
{
	var IN = 0;
	var OUT = 1;
	var EMPTY = 2;
	var FULL = 3;
	var NULL = -1;
}
