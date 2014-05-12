package flixel.addons.util;

/**
 * A generic Finite-state machine implementation.
 */
class FlxFSM<T> implements IFlxFSM<T>
{
	/**
	 * The owner of this FSM instance. Gets passed to each state.
	 */
	public var owner:T;
	
	private var lock:Bool;
	private var currentState:IFlxFSMState<T>;
	private var previousState:IFlxFSMState<T>;
	
	public function new() { }
	
	/**
	 * Changes the state of this FSM instance.
	 * 
	 * @param	State	FlxFSMState instance to change to
	 * @param	Force	By default you can't change states more than once each update loop, unless Force is set as true
	 */
	public function changeState(State:IFlxFSMState<T>, Force:Bool = false)
	{
		if (lock && !Force) return;
		if (owner == null) throw "Can't change states if owner is null.";
		if (currentState != null)
		{
			currentState.exit(owner);
			previousState = currentState;
		}
		currentState = State;
		currentState.enter(owner, this);
		lock = true;
	}
	
	/**
	 * Updates the active state instance.
	 */
	public function update():Void
	{
		if (currentState == null) return;
		if (owner == null) throw "Can't update states if owner is null.";
		lock = false;
		currentState.update(owner, this);
	}
	
	/**
	 * Tells if a given class is the active state
	 * 
	 * @param	StateClass
	 * @return	True if current state is an instance of StateClass
	 */
	public function currently(StateClass:Class<IFlxFSMState<T>>):Bool
	{
		if (currentState != null)
		{
			return (Type.getClass(currentState) == StateClass);
		}
		return false;
	}
	
	/**
	 * Tells if a given class is the previous state.
	 * @param	StateClass
	 * @return	True if previous state is an instance of StateClass
	 */
	public function previously(StateClass:Class<IFlxFSMState<T>>):Bool
	{
		if (previousState != null)
		{
			return (Type.getClass(previousState) == StateClass);
		}
		return false;
	}
	
}

/**
 * A generic FSM State implementation
 */
class FlxFSMState<T> implements IFlxFSMState<T>
{
	public function new() { }
	
	/**
	 * Called when state becomes active.
	 * 
	 * @param	Owner	The object the state controls
	 * @param	FSM		The FSM instance this state belongs to. Used for changing the state to another.
	 */
	public function enter(Owner:T, FSM:IFlxFSM<T>):Void { }
	
	/**
	 * Called every update loop.
	 * 
	 * @param	Owner	The object the state controls
	 * @param	FSM		The FSM instance this state belongs to. Used for changing the state to another.
	 */
	public function update(Owner:T, FSM:IFlxFSM<T>):Void { }
	
	/**
	 * Called when the state becomes inactive.
	 * 
	 * @param	Owner	The object the state controls
	 */
	public function exit(Owner:T):Void { }
}

interface IFlxFSMState<T>
{
	public function enter(Owner:T, FSM:IFlxFSM<T>):Void;
	public function update(Owner:T, FSM:IFlxFSM<T>):Void;
	public function exit(Owner:T):Void;
}

interface IFlxFSM<T>
{
	public var owner:T;
	public function changeState(State:IFlxFSMState<T>, Force:Bool = false):Void;
	public function update():Void;
	public function currently(StateClass:Class<IFlxFSMState<T>>):Bool;
	public function previously(StateClass:Class<IFlxFSMState<T>>):Bool;
}