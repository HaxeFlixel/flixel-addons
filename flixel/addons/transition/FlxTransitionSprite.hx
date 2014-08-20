package flixel.addons.transition;

import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.addons.util.FlxFSM.Transition;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.layer.frames.FlxSpriteFrames;
import flixel.util.FlxTimer;
import openfl.display.BitmapData;

@:bitmap("assets/images/transitions/circle.png") private class TransTileGraphicCircle extends BitmapData { }
@:bitmap("assets/images/transitions/diamond.png") private class TransTileGraphicDiamond extends BitmapData { }
@:bitmap("assets/images/transitions/square.png") private class TransTileGraphicSquare extends BitmapData { }

/**
 * 
 * @author Tim Hely
 */
class FlxTransitionSprite extends FlxSprite
{
	public static inline var CIRCLE = "circle";
	public static inline var DIAMOND = "diamond";
	public static inline var SQUARE = "square";
	
	private var _delay:Float;
	public var status:TransitionStatus = IN;
	private var _newStatus:TransitionStatus = NULL;
	
	public function new(X:Float=0, Y:Float=0, Delay:Float, Graphic:FlxGraphicAsset=DIAMOND, GraphicWidth:Int=32, GraphicHeight:Int=32, FrameRate:Int=40) 
	{
		super(X, Y);
		switch(Graphic)
		{
			case CIRCLE: Graphic = TransTileGraphicCircle;
			case DIAMOND: Graphic = TransTileGraphicDiamond;
			case SQUARE: Graphic = TransTileGraphicSquare;
		}
		_delay = Delay;
		loadGraphic(Graphic, true, GraphicWidth, GraphicHeight);
		animation.add("empty", [0], 0, false);
		
		var inArray:Array<Int> = [];
		var outArray:Array<Int> = [];
		for (i in 1...frames-1)
		{
			inArray.push(i);
		}
		outArray = inArray.copy();
		outArray.reverse();
		
		animation.add("in", inArray, FrameRate, false);
		animation.add("full", [frames-1], 0, false);
		animation.add("out", outArray, FrameRate, false);
		setStatus(FULL);
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
		
		animation.play(anim);
		status = Status;
	}
	
	override public function update():Void 
	{
		super.update();
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
	
	private function onTimer(f:FlxTimer=null):Void
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
