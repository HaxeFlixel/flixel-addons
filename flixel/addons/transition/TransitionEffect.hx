package flixel.addons.transition;

import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.addons.transition.TransitionData;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxTimer;

/**
 * @author larsiusprime
 */
@:allow(flixel.addons.transition.Transition)
class TransitionEffect extends FlxSpriteGroup
{
	public var finishCallback:Void->Void;
	public var finished(default, null):Bool = false;

	var _started:Bool = false;
	var _endStatus:TransitionStatus;
	var _finalDelayTime:Float = 0.0;

	var _data:TransitionData;

	public function new(data:TransitionData)
	{
		_data = data;
		super();
	}

	override public function destroy():Void
	{
		super.destroy();
		finishCallback = null;
	}

	public function start(NewStatus:TransitionStatus):Void
	{
		_started = true;

		if (NewStatus == IN)
		{
			_endStatus = FULL;
		}
		else
		{
			_endStatus = EMPTY;
		}
	}

	public function setStatus(NewStatus:TransitionStatus):Void
	{
		// override per subclass
	}

	function delayThenFinish():Void
	{
		new FlxTimer().start(_finalDelayTime, onFinish); // force one last render call before exiting
	}

	function onFinish(f:FlxTimer):Void
	{
		finished = true;
		if (finishCallback != null)
		{
			var callback = finishCallback;
			finishCallback = null;
			callback();
		}
	}
}
