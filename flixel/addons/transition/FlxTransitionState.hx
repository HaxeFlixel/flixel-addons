package flixel.addons.transition;

import flixel.FlxState;

class FlxTransitionState extends FlxState
{
	private var _loading:Bool = true;
	private var _transIn:TransitionData;
	private var _transOut:TransitionData;
	
	public static var defaultTransIn:TransitionData=null;
	public static var defaultTransOut:TransitionData=null;
	
	/**
	 * Create a state with the ability to do visual transitions
	 * @param	TransIn		Plays when the state begins
	 * @param	TransOut	Plays when the state ends
	 */
	
	public function new(?TransIn:TransitionData,?TransOut:TransitionData)
	{
		_transIn = TransIn;
		_transOut = TransOut;
		if (_transIn == null && defaultTransIn != null)
		{
			_transIn = defaultTransIn;
		}
		if (_transOut == null && defaultTransOut != null)
		{
			_transOut = defaultTransOut;
		}
		super();
	}
	
	override public function create():Void 
	{
		super.create();
		
		if (_transIn != null)
		{
			var _trans:FlxTransition = new FlxTransition(_transIn);
		
			_trans.setStatus(FULL);
			openSubState(_trans);
			
			_trans.finishCallback = finishTransIn;
			_trans.start(OUT);
		}
	}
	
	private function finishTransIn()
	{
		_loading = false;
		closeSubState();
	}
	
	private function finishTransOut()
	{
		closeSubState();
	}
	
	private function startExitTransition():Void
	{
		_loading = true;
		
		if (_transOut != null)
		{
			var _trans:FlxTransition = new FlxTransition(_transOut);
			
			_trans.setStatus(EMPTY);
			openSubState(_trans);
			
			_trans.finishCallback = finishTransOut;
			_trans.start(IN);
		}
	}
}