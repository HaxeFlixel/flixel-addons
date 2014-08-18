package flixel.addons.transition;

import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

/**
 * FlxTransition
 * @author Tim Hely
 */

class FlxTransition extends FlxSubState
{
	private var _started:Bool = false;
	private var _endStatus:TransitionStatus;
	private var _grpSprites:FlxTypedGroup<FlxTransitionSprite>;
	public var finishCallback:Void->Void;
	
	private var counter:Float = 0;
	private var lastCount:Int = 0;
	private var maxCounter:Float = 5;
	
	private var back:FlxSprite;
	
	public function new(data:TransitionData) 
	{
		super(FlxColor.TRANSPARENT);
		_grpSprites = new FlxTypedGroup<FlxTransitionSprite>();
		var delay:Float = 0;
		var tx:Int = 0;
		var ty:Int = 0;
		var yloops:Int = 0;
		var xloops:Int = 0;
		while (ty < FlxG.height)
		{
			while (tx < FlxG.width)
			{
				_grpSprites.add(new FlxTransitionSprite(tx, ty, delay, data.asset));
				tx += 32;
				xloops++;
				delay += .008;
			}
			ty += 32;
			tx = 0;
			xloops = 0;
			yloops++;
			delay = 0 + (yloops * .008);
		}
		add(_grpSprites);
	}
	
	public override function create():Void {
		super.create();
	}
	
	public function start(NewStatus:TransitionStatus):Void
	{
		trace("START : " + NewStatus);
		_started = true;
		counter = 0;
		maxCounter = 1;
		
		if (NewStatus == IN)
		{
			_endStatus = FULL;
		}
		else
		{
			_endStatus = EMPTY;
		}
	
		_grpSprites.forEach(function(t:FlxTransitionSprite) { t.start(NewStatus); } );
		
	}
	
	private function onComplete(f:FlxTween):Void
	{
		if (_started)
		{
			if (finishCallback != null)
			{
				finishCallback();
			}
		}
	}
	
	public function setStatus(NewStatus:TransitionStatus):Void
	{
		//counter = 0;
 		_grpSprites.forEach(function(t:FlxTransitionSprite) { t.setStatus(NewStatus); } );
	}
	
	override public function update():Void 
	{
		super.update();
		
		if (_started)
		{
			if (_grpSprites.members[_grpSprites.members.length - 1].status == _endStatus)
			{
				_started = false;
				
				if (finishCallback != null)
				{
					finishCallback();
				}
			}
		}
	}
	
}