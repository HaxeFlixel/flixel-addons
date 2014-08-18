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
	
	public function new() 
	{
		super(FlxColor.TRANSPARENT);
		
		counter = 0;
		maxCounter = 5;
		
		back = new FlxSprite();
		back.makeGraphic(FlxG.width, FlxG.height, 0xFFFF0000);
		add(back);
		
		/*_grpSprites = new FlxTypedGroup<FlxTransitionSprite>();
		
		var delay:Float = 0;
		var tx:Int = 0;
		var ty:Int = 0;
		var yloops:Int = 0;
		var xloops:Int = 0;
		while (ty < FlxG.height)
		{
			while (tx < FlxG.width)
			{
				_grpSprites.add(new FlxTransitionSprite(tx, ty, delay));
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
		add(_grpSprites);*/
		_started = false;
	}
	
	public function start(NewStatus:TransitionStatus):Void
	{
		if (NewStatus == TransitionStatus.TRANS_IN)
		{
			_endStatus = TransitionStatus.TRANS_ON;
		}
		else
		{
			_endStatus = TransitionStatus.TRANS_OFF;
		}
		
		counter = 0;
		_started = true;
		
		/*back.alpha = startAlpha;
		FlxTween.tween(back, {"alpha":endAlpha}, 1, {complete:onComplete});*/
	
		/*_grpSprites.forEach(function(t:FlxTransitionSprite) { t.start(NewStatus); } );*/
		
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
 		//_grpSprites.forEach(function(t:FlxTransitionSprite) { t.setStatus(NewStatus); } );
	}
	
	override public function update():Void
	{
		super.update();
		if (_started) {
			
			if (_endStatus == TransitionStatus.TRANS_ON)
			{
				back.alpha = counter / maxCounter;
			}
			else
			{
				back.alpha = 1 - (counter / maxCounter);
			}
			
			counter += FlxG.elapsed;
			if (Std.int(counter) != lastCount) {
				trace("counter = " + counter);
			}
			lastCount = Std.int(counter);
			if (counter > maxCounter)
			{
				_started = false;
				if (finishCallback != null)
				{
					finishCallback();
				}
			}
		}
	}
	
	/*override public function update():Void 
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
	}*/
	
}