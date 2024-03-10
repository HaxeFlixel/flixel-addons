package flixel.addons.transition;

import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.addons.transition.TransitionData;
import flixel.group.FlxGroup;
import flixel.group.*;
import flixel.util.FlxTimer;

/**
 * @author larsiusprime
 */
@:allow(flixel.addons.transition.Transition)
class TransitionEffect extends #if (flixel < "5.7.0") FlxSpriteGroup #else FlxSpriteContainer #end
{
	public var finishCallback:Void->Void;
	public var finished(default, null):Bool = false;
	
	var _started:Bool = false;
	var _endStatus:TransitionStatus;
	var _finalDelayTime:Float = 0.0;
	var _customCamera:FlxCamera;
	
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
		
		if (_customCamera != null)
		{
			// may already be removed via state switching
			if (FlxG.cameras.list.contains(_customCamera))
				FlxG.cameras.remove(_customCamera, true);
				
			_customCamera = null;
		}
	}
	
	public function start(newStatus:TransitionStatus):Void
	{
		_started = true;
		
		if (newStatus == IN)
		{
			_endStatus = FULL;
		}
		else
		{
			_endStatus = EMPTY;
		}
		
		switch (_data.cameraMode)
		{
			case NEW:
				// create a new camera above everything else
				_customCamera = new FlxCamera(0, 0, Std.int(_data.region.width), Std.int(_data.region.height));
				_customCamera.bgColor = 0x0;
				FlxG.cameras.add(_customCamera, false);
				camera = _customCamera;
			case TOP:
				// get the last added camera so it shows up on top of everything
				final cams = FlxG.cameras.list;
				camera = cams[cams.length - 1];
			case DEFAULT:
				// do nothing
		}
	}
	
	public function setStatus(newStatus:TransitionStatus):Void
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
