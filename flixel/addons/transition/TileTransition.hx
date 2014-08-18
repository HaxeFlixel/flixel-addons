package flixel.addons.transition;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.group.FlxGroup.FlxTypedGroup;

/**
 * 
 * @author larsiusprime
 */
class TileTransition extends Transition
{
	private var _grpSprites:FlxTypedGroup<FlxTransitionSprite>;
	
	public function new(data:TransitionData) 
	{
		super(data);
		
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
				var ts = new FlxTransitionSprite(tx, ty, delay, data.tileData.asset);
				ts.color = data.color;
				_grpSprites.add(ts);
				tx += data.tileData.width;
				xloops++;
				delay += .008;
			}
			ty += data.tileData.height;
			tx = 0;
			xloops = 0;
			yloops++;
			delay = 0 + (yloops * .008);
		}
		add(_grpSprites);
	}
	
	public override function destroy():Void {
		super.destroy();
		_grpSprites = null;
	}
	
	public override function start(NewStatus:TransitionStatus):Void
	{
		super.start(NewStatus);
		
		_grpSprites.forEach
		(
			function(t:FlxTransitionSprite)
			{
				t.start(NewStatus);
			} 
		);
	}
	
	public override function setStatus(NewStatus:TransitionStatus):Void
	{
		super.setStatus(NewStatus);
		_grpSprites.forEach(
			function(t:FlxTransitionSprite)
			{ 
				t.setStatus(NewStatus); 
			} 
		);
	}
	
	public override function update():Void 
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