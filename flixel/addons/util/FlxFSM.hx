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
	public var owner(get, set):T;
	
	/**
	 * Current state
	 */
	public var state(get, set):IFlxFSMState<T>;
	
	private var _owner:T;
	private var _state:IFlxFSMState<T>;
	
	public function new(?Owner:T, ?State:IFlxFSMState<T>) {
		set(Owner, State);
	}
	
	/**
	 * Set the owner and state simultaneously.
	 * @param	Owner
	 * @param	State
	 */
	public function set(Owner:T, State:IFlxFSMState<T>):Void
	{
		var stateIsDifferent:Bool = (Type.getClass(_state) != Type.getClass(State));
		var ownerIsDifferent:Bool = (owner != Owner);
		
		if (stateIsDifferent || ownerIsDifferent)
		{
			if (_owner != null && _state != null)
			{
				_state.exit(_owner);
			}
			if (stateIsDifferent)
			{
				_state = State;
			}
			if (ownerIsDifferent)
			{
				_owner = Owner;
			}
			if (_state != null && owner != null)
			{
				_state.enter(_owner, this);
			}
		}
	}
	
	/**
	 * Updates the active state instance.
	 */
	public function update():Void
	{
		if (_state == null || _owner == null) return;
		_state.update(_owner, this);
	}
	
	/**
	 * Calls exit on current state
	 */
	public function destroy():Void
	{
		set(null, null);
	}
	
	private function set_owner(Owner:T):T
	{
		set(Owner, _state);
		return owner;
	}
	
	private function get_owner():T
	{
		return _owner;
	}
	
	private function set_state(State:IFlxFSMState<T>):IFlxFSMState<T>
	{
		set(owner, State);
		return state;
	}
	
	private function get_state():IFlxFSMState<T>
	{
		return _state;
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
	public var owner(get, set):T;
	public var state(get, set):IFlxFSMState<T>;
	public function set(Owner:T, State:IFlxFSMState<T>):Void;
	public function update():Void;
}