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
 * FlxTransitionSprite
 * @author Tim Hely
 */
class FlxTransitionSprite extends FlxSprite
{

	private var _delay:Float;
	private var _timer:Float;
	public var status:TransitionStatus = TRANS_IN;
	private var _newStatus:TransitionStatus = TRANS_NULL;
	

	
	public function new(X:Float=0, Y:Float=0, Delay:Float, Graphic:FlxGraphicAsset="assets/images/transitions/diamond.png", GraphicWidth:Int=32, GraphicHeight:Int=32, FrameRate:Int=40) 
	{
		super(X, Y);
		_delay = Delay;
		loadGraphic(Graphic, true, GraphicWidth, GraphicHeight);
		animation.add("off", [0], 0, false);
		
		var inArray:Array<Int> = [];
		var outArray:Array<Int> = [];
		for (i in 1...frames-1)
		{
			inArray.push(i);
		}
		outArray = inArray.copy();
		outArray.reverse();
		
		animation.add("in", inArray, FrameRate, false);
		animation.add("on", [frames-1], 0, false);
		animation.add("out", outArray, FrameRate, false);
		setStatus(TRANS_ON);
		_timer = -1;
	}
	
	public function start(NewStatus:TransitionStatus):Void
	{
		_timer = _delay;
		_newStatus = NewStatus;
	}

	private function startStatus(_, NewStatus:TransitionStatus):Void
	{
		setStatus(NewStatus);
	}
	
	
	public function setStatus(Status:TransitionStatus):Void
	{
		var anim:String="off";
		switch (Status) 
		{
			case TRANS_IN:
				anim = "in";
			case TRANS_OUT:
				anim = "out";
			case TRANS_OFF,TRANS_NULL:
				anim = "off";
			case TRANS_ON:
				anim = "on";
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
				_newStatus = TRANS_NULL;
			}
		}
		if (animation.finished)
		{
			switch (status) 
			{
				case TRANS_IN:
					setStatus(TRANS_ON);
				case TRANS_OUT:
					setStatus(TRANS_OFF);
				default:
			}
		}
		
	}
}

@:enum
abstract TransitionStatus(Int)
{
	var TRANS_IN = 0;
	var TRANS_OUT = 1;
	var TRANS_ON = 2;
	var TRANS_OFF = 3;
	var TRANS_NULL = -1;
}
