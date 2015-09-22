 package flixel.addons.transition;
import flash.display.BitmapData;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.group.FlxGroup.FlxTypedGroup;

/**
 * 
 * @author larsiusprime
 */
class TransitionTiles extends Transition
{
	private var _grpSprites:FlxTypedGroup<FlxTransitionSprite>;
	private var _isCenter:Bool = false;
	
	public function new(data:TransitionData) 
	{
		super(data);
		
		_grpSprites = new FlxTypedGroup<FlxTransitionSprite>();
		var delay:Float = 0;
		var yloops:Int = 0;
		var xloops:Int = 0;
		
		if (data.tileData == null)
		{
			data.tileData = { asset:null, width:32, height:32 };
		}
		
		var tilesX:Int = Math.ceil(FlxG.width / data.tileData.width);
		var tilesY:Int = Math.ceil(FlxG.height / data.tileData.height);
		
		var maxTiles:Int = tilesX > tilesY ? tilesX : tilesY;
		
		var dTime:Float = data.duration / maxTiles;
		
		var xDelay:Float = dTime * Math.abs(data.direction.x);
		var yDelay:Float = dTime * Math.abs(data.direction.y);
		
		var addX:Int = data.tileData.width;
		var addY:Int = data.tileData.height;
		
		var tx:Int = 0;
		var ty:Int = 0;
		
		var startX:Int = 0;
		var startY:Int = 0;
		
		if (data.direction.x < 0)
		{
			addX *= -1;
			startX = FlxG.width+addX;
		}
		if (data.direction.y < 0)
		{
			addY *= -1;
			startY = FlxG.height+addY;
		}
		
		tx = startX;
		ty = startY;
		for (iy in 0...tilesY)
		{
			for (ix in 0...tilesX)
			{
				var ts = new FlxTransitionSprite(tx, ty, delay, data.tileData.asset);
				ts.color = data.color;
				ts.scrollFactor.set(0, 0);
				_grpSprites.add(ts);
				tx += addX;
				delay += xDelay;
			}
			ty += addY;
			tx = startX;
			delay = 0 + (iy * yDelay);
		}
		add(_grpSprites);
		
		_isCenter = (data.direction.x == 0 && data.direction.y == 0);
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
	
	public override function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		if (_started)
		{
			var allDone:Bool = true;
			for (sprite in _grpSprites.members)
			{
				if (sprite.status != _endStatus)
				{
					allDone = false;
					break;
				}
			}
			if (allDone)
			{
				_started = false;
				delayThenFinish();
			}
		}
	}
}