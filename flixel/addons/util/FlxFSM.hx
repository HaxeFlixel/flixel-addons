package flixel.addons.util;

import flixel.util.FlxDestroyUtil;

/**
 * A generic Finite-state machine implementation.
 */
class FlxFSM<T> implements IFlxDestroyable
{
	/**
	 * The owner of this FSM instance. Gets passed to each state.
	 */
	public var owner(get, set):T;
	
	/**
	 * Current state
	 */
	public var state(get, set):FlxFSMState<T>;
	
	private var _owner:T;
	private var _state:FlxFSMState<T>;
	
	public function new(?Owner:T, ?State:FlxFSMState<T>)
	{
		set(Owner, State);
	}
	
	/**
	 * Set the owner and state simultaneously.
	 */
	public function set(Owner:T, State:FlxFSMState<T>):Void
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
	
	private function set_state(State:FlxFSMState<T>):FlxFSMState<T>
	{
		set(owner, State);
		return state;
	}
	
	private function get_state():FlxFSMState<T>
	{
		return _state;
	}
}

/**
 * A generic FSM State implementation
 */
class FlxFSMState<T> implements IFlxDestroyable
{
	public function new() { }
	
	/**
	 * Called when state becomes active.
	 * 
	 * @param	Owner	The object the state controls
	 * @param	FSM		The FSM instance this state belongs to. Used for changing the state to another.
	 */
	public function enter(Owner:T, FSM:FlxFSM<T>):Void { }
	
	/**
	 * Called every update loop.
	 * 
	 * @param	Owner	The object the state controls
	 * @param	FSM		The FSM instance this state belongs to. Used for changing the state to another.
	 */
	public function update(Owner:T, FSM:FlxFSM<T>):Void { }
	
	/**
	 * Called when the state becomes inactive.
	 * 
	 * @param	Owner	The object the state controls
	 */
	public function exit(Owner:T):Void { }
	
	public function destroy():Void { }
}