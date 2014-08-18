package flixel.addons.transition;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;

/**
 * 
 * @author larsiusprime
 */
class FadeTransition extends Transition
{
	private var back:FlxSprite;
	
	public function new(data:TransitionData) 
	{
		super(data);
		
		back = new FlxSprite(0, 0);
		back.makeGraphic(FlxG.width, FlxG.height, data.color);
		
		add(back);
	}
	
	public override function destroy():Void {
		super.destroy();
		back = null;
	}
	
	public override function start(NewStatus:TransitionStatus):Void
	{
		super.start(NewStatus);
		switch(NewStatus)
		{
			case IN:
				back.alpha = 0.0;
				_data.tweenOptions.complete = finishTween;
				FlxTween.tween(back, { "alpha":1.0 }, _data.duration, _data.tweenOptions);
			case OUT:
				back.alpha = 1.0;
				_data.tweenOptions.complete = finishTween;
				FlxTween.tween(back, { "alpha":0.0 }, _data.duration, _data.tweenOptions);
			default:
				//donothing
		}
	}
	
	public override function setStatus(NewStatus:TransitionStatus):Void
	{
		super.setStatus(NewStatus);
		switch(NewStatus)
		{
			case FULL, OUT:
				back.alpha = 1.0;
			case IN, EMPTY:
				back.alpha = 0.0;
			default:
		}
	}
	
	private function finishTween(f:FlxTween):Void
	{
		finishCallback();
	}
}