package flixel.addons.transition;

import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.addons.util.FlxFSM.Transition;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.layer.frames.FlxSpriteFrames;
import flixel.util.FlxTimer;

/**
 * 
 * @author Tim Hely
 */
class FlxTransitionSprite extends FlxSprite
{

	private var _delay:Float;
	private var _timer:Float;
	public var status:TransitionStatus = IN;
	private var _newStatus:TransitionStatus = NULL;
	
	public function new(X:Float=0, Y:Float=0, Delay:Float, Graphic:FlxGraphicAsset="assets/images/transitions/diamond.png", GraphicWidth:Int=32, GraphicHeight:Int=32, FrameRate:Int=40) 
	{
		super(X, Y);
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
		_timer = -1;
	}
	
	public function start(NewStatus:TransitionStatus):Void
	{
		_timer = _delay;
		_newStatus = NewStatus;
	}

	private function startStatus(NewStatus:TransitionStatus):Void
	{
		setStatus(NewStatus);
	}
	
	
	public function setStatus(Status:TransitionStatus):Void
	{
		var anim:String="empty";
		switch (Status) 
		{
			case IN:	anim = "in";
			case OUT:	anim = "out";
			case EMPTY,NULL:	anim = "empty";
			case FULL:	anim = "full";
		}
		
		animation.play(anim);
		status = Status;
	}
	
	override public function update():Void 
	{
		super.update();
		if (_timer >= 0)
		{
			_timer -= FlxG.elapsed;
			if (_timer < 0)
			{
				setStatus(_newStatus);
				_newStatus = NULL;
			}
		}
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
