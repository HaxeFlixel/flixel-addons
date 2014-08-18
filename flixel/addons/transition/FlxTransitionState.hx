package flixel.addons.transition;

import flixel.FlxState;

class FlxTransitionState extends FlxState
{
	private var _loading:Bool = true;
	
	public function new(t:FlxTransition)
	{
		super();
	}
	
	override public function create():Void 
	{
		super.create();
		
		var _trans:FlxTransition = new FlxTransition();
		if (_trans != null)
		{
			_trans.setStatus(TRANS_ON);
			openSubState(_trans);
			
			_trans.finishCallback = finishTransIn;
			_trans.start(TRANS_OUT);
		}
	}
	
	/*override public function update():Void
	{
		#if debug
		if (FlxG.keys.justPressed.SPACE)
		{
			trace("SPOT CHECK!");
		}
		#end
		super.update();
	}*/
	
	private function finishTransIn()
	{
		_loading = false;
		closeSubState();
	}
	
	private function finishTransOut()
	{
		closeSubState();
		//override per subclass
	}
	
	private function startExitTransition():Void
	{
		_loading = true;
		
		var _trans:FlxTransition = new FlxTransition();
		
		_trans.setStatus(TRANS_OFF);
		openSubState(_trans);
		
		_trans.finishCallback = finishTransOut;
		_trans.start(TRANS_IN);
	}
}