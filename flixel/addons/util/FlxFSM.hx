package flixel.addons.util;
import flixel.interfaces.IFlxDestroyable;

/**
 * A generic Finite-state machine implementation.
 */
class FlxFSM<T> implements IFlxFSM<T>
{
	/**
	 * The owner of this FSM instance. Gets passed to each state.
	 */
	public var owner:T;
	
	private var currentState:IFlxFSMState<T>;
	private var previousState:IFlxFSMState<T>;
	
	public function new(?Owner:T) {
		if (Owner != null)
		{			
			owner = Owner;
		}
	}
	
	/**
	 * Changes the state of this FSM instance.
	 * 
	 * @param	State	FlxFSMState instance to change to
	 */
	public function changeState(State:IFlxFSMState<T>)
	{
		if (this.owner == null) throw "Can't change states if owner is null.";
		if (currentState != null)
		{
			currentState.exit(owner);
			previousState = currentState;
		}
		currentState = State;
		currentState.enter(owner, this);
	}
	
	/**
	 * Reverts back to earlier state if present.
	 */
	public function revertState()
	{
		if (this.owner == null) throw "Can't change states if owner is null.";
		if (previousState != null)
		{
			currentState.exit(owner);
			var state = currentState;
			currentState = previousState;
			currentState.enter(owner, this);
			previousState = state;
		}
	}
	
	/**
	 * Updates the active state instance.
	 */
	public function update():Void
	{
		if (currentState == null) return;
		if (owner == null) throw "Can't update states if owner is null.";
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
	
	public function destroy():Void
	{
		previousState = null;
		if (currentState != null && owner != null)
		{
			currentState.exit(owner);
		}
		currentState = null;
		owner = null;
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
	
	public function destroy():Void { }
}

interface IFlxFSMState<T> extends IFlxDestroyable
{
	public function enter(Owner:T, FSM:IFlxFSM<T>):Void;
	public function update(Owner:T, FSM:IFlxFSM<T>):Void;
	public function exit(Owner:T):Void;
}

interface IFlxFSM<T> extends IFlxDestroyable
{
	public var owner:T;
	public function changeState(State:IFlxFSMState<T>):Void;
	public function revertState():Void;
	public function update():Void;
	public function currently(StateClass:Class<IFlxFSMState<T>>):Bool;
	public function previously(StateClass:Class<IFlxFSMState<T>>):Bool;
}