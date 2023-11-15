package flixel.addons.transition;

import flixel.addons.transition.TransitionData.TransitionType;
import flixel.addons.transition.TransitionEffect;
import flixel.addons.transition.TransitionFade;
import flixel.addons.transition.TransitionTiles;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
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

	var _effectCamera:FlxCamera;
	var _effect:TransitionEffect;

	public function new(data:TransitionData)
	{
		super(FlxColor.TRANSPARENT);

		_effectCamera = new FlxCamera(0, 0, Std.int(data.region.width), Std.int(data.region.height));
		_effectCamera.bgColor = 0x0;
		
		_effect = createEffect(data);
		_effect.scrollFactor.set(0, 0);
		add(_effect);
	}

	public override function destroy():Void
	{
		super.destroy();

		finishCallback = null;

		_effect = FlxDestroyUtil.destroy(_effect);

		if (_effectCamera != null)
		{
			// may already be removed via state switching
			if (FlxG.cameras.list.contains(_effectCamera))
				FlxG.cameras.remove(_effectCamera, true);


			_effectCamera = null;
		}
	}

	public function start(NewStatus:TransitionStatus):Void
	{
		_effect.start(NewStatus);
		
		FlxG.cameras.add(_effectCamera, false);
		_effect.cameras = [_effectCamera];
	}

	public function setStatus(NewStatus:TransitionStatus):Void
	{
		_effect.setStatus(NewStatus);
	}

	function createEffect(Data:TransitionData):TransitionEffect
	{
		switch (Data.type)
		{
			case TransitionType.TILES:
				return new TransitionTiles(Data);
			case TransitionType.FADE:
				return new TransitionFade(Data);
			default:
				return null;
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

	function set_finishCallback(f:Void->Void):Void->Void
	{
		if (_effect != null)
		{
			_effect.finishCallback = f;
			return f;
		}

		return null;
	}
}
