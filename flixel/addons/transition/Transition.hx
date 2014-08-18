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
 * This substate is automatically created to play the actual transition visuals inside a FlxTransitionState.
 * To achieve a specific effect, you should use a sub-class of this such as TileTransition or FadeTransition
 * @author Tim Hely, larsiusprime
 */

class Transition extends FlxSubState
{
	private var _started:Bool = false;
	private var _endStatus:TransitionStatus;
	private var _data:TransitionData;
	
	public var finishCallback:Void->Void;
	
	public function new(data:TransitionData) 
	{
		_data = data;
		super(FlxColor.TRANSPARENT);
	}
	
	public override function destroy():Void {
		super.destroy();
		_data = null;
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
		//override per subclass
	}
}