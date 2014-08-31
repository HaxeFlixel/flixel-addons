package flixel.addons.transition;

import flixel.FlxState;

/**
 * FlxTransitionableState
 * 
 * A FlxState which can perform visual transitions
 * 
 * Usage:
 * 
 * First, extend FlxTransitionableState as ie, FooState
 * 
 * Method 1: 
 *  
 *  var in:TransitionData = new TransitionData(...);		//add your data where "..." is
 *  var out:TransitionData = new TransitionData(...);
 * 
 *  FlxG.switchState(new FooState(in,out));
 * 
 * Method 2:
 * 
 *  FlxTransitionableState.defaultTransIn = new TransitionData(...);
 *  FlxTransitionableState.defaultTransOut = new TransitionData(...);
 *  
 *  FlxG.switchState(new FooState());
 * 
 */

class FlxTransitionableState extends FlxState
{
	//global default transitions for ALL states, used if _transIn/_transOut are null
	public static var defaultTransIn:TransitionData=null;
	public static var defaultTransOut:TransitionData=null;
	
	public var hasTransIn(get, null):Bool;
	public var hasTransOut(get, null):Bool;
	
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
	
	override public function destroy():Void
	{
		_transIn = null;
		_transOut = null;
		_onExit = null;
	}
	
	override public function create():Void 
	{
		super.create();
		if (_transIn != null && _transIn.type != NONE)
		{
			var _trans = getTransition(_transIn);
		
			_trans.setStatus(FULL);
			openSubState(_trans);
			
			_trans.finishCallback = finishTransIn;
			_trans.start(OUT);
		}
	}
	
	public override function isTransitionNeeded():Bool
	{
		//If the transition exists and we have NOT yet finished our transition visual
		return ((hasTransOut) && (_transOutFinished == false));
	}
	
	public override function transitionToState(Next:FlxState):Void
	{
		//play the exit transition, and when it's done call FlxG.switchState
		exitTransition(
			function():Void
			{
				FlxG.switchState(Next);
			}
		);
	}
	
	//beginning & ending transitions for THIS state:
	private var _transIn:TransitionData;
	private var _transOut:TransitionData;
	
	private var _transOutFinished:Bool = false;
	
	private var _onExit:Void->Void;
	
	private function get_hasTransIn():Bool
	{
		return _transIn != null && _transIn.type != NONE;
	}
	
	private function get_hasTransOut():Bool
	{
		return _transOut != null && _transOut.type != NONE;
	}
	
	private function getTransition(data:TransitionData):Transition
	{
		switch(data.type)
		{
			case TILES:	return new TransitionTiles(data);
			case FADE:	return new TransitionFade(data);
			default:
		}
		
		return null;
	}
	
	private function finishTransIn()
	{
		closeSubState();
	}
	
	private function finishTransOut()
	{
		_transOutFinished = true;
		if (_onExit != null)
		{
			_onExit();
		}
	}
	
	private function exitTransition(?OnExit:Void->Void):Void
	{
		_onExit = OnExit;
		if (hasTransOut)
		{
			var _trans = getTransition(_transOut);
			
			_trans.setStatus(EMPTY);
			openSubState(_trans);
			
			_trans.finishCallback = finishTransOut;
			_trans.start(IN);
		}
		else
		{
			_onExit();
		}
	}
}