package flixel.addons.transition;

import flixel.addons.transition.TransitionData;
import flixel.addons.transition.TransitionEffect;
import flixel.addons.transition.TransitionFade;
import flixel.addons.transition.TransitionTiles;
import flixel.addons.transition.FlxTransitionSprite;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxTimer;

/**
 * This substate is automatically created to play the actual transition visuals inside a FlxTransitionState.
 * To achieve a specific effect, you should use a sub-class of this such as TileTransition or FadeTransition
 * @author Tim Hely, larsiusprime
 */
class Transition extends FlxSubState
{
	public var finishCallback(get, set):Void->Void;
	
	var _effect:TransitionEffect;
	
	public function new(data:TransitionData)
	{
		super(FlxColor.TRANSPARENT);
		
		_effect = createEffect(data);
		_effect.scrollFactor.set(0, 0);
		add(_effect);
	}
	
	public override function destroy():Void
	{
		super.destroy();
		
		finishCallback = null;
		
		_effect = FlxDestroyUtil.destroy(_effect);
	}
	
	public function start(newStatus:TransitionStatus):Void
	{
		_effect.start(newStatus);
	}
	
	public function setStatus(newStatus:TransitionStatus):Void
	{
		_effect.setStatus(newStatus);
	}
	
	function createEffect(data:TransitionData):TransitionEffect
	{
		switch (data.type)
		{
			case TransitionType.TILES:
				return new TransitionTiles(data);
			case TransitionType.FADE:
				return new TransitionFade(data);
			case TransitionType.NONE:
				throw "Unexpected TransitionType: NONE";
		}
	}
	
	function get_finishCallback():Void->Void
	{
		if (_effect != null)
		{
			return _effect.finishCallback;
		}
		
		return null;
	}
	
	function set_finishCallback(callback:Void->Void):Void->Void
	{
		if (_effect != null)
		{
			_effect.finishCallback = callback;
			
			return callback;
		}
		
		return null;
	}
}
