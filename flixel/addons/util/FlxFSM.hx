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
	
	public var transitions:FlxFSMTransitionTable<T>;
	
	private var _owner:T;
	private var _state:FlxFSMState<T>;
	
	public function new(?Owner:T, ?State:FlxFSMState<T>)
	{
		transitions = new FlxFSMTransitionTable<T>();
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
		state = transitions.poll(this);
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

class FlxFSMTransitionTable<T>
{
	private var _table:Array<TransitionRow<T>>;
	
	public function new()
	{
		_table = new Array<TransitionRow<T>>();
	}
	
	/**
	 * Polls the transition table for active states
	 * @param	FSM	The FlxFSMState the table belongs to
	 * @return	The state that should become or remain active.
	 */
	public function poll(FSM:FlxFSM<T>):FlxFSMState<T>
	{
		var currentState = FSM.state;
		var currentOwner = FSM.owner;
		for (transition in _table)
		{
			if (Type.getClass(transition.from) == Type.getClass(currentState))
			{
				if (transition.condition(currentOwner) == true)
				{
					return transition.to;
				}
			}
		}
		return currentState;
	}
	
	/**
	 * Adds a transition condition to the table
	 * @param	From	The state the condition applies to
	 * @param	To		The state to transition
	 * @param	Condition	Function that returns true if the transition conditions are met
	 */
	public function add(From:FlxFSMState<T>, To:FlxFSMState<T>, Condition:T->Bool)
	{
		_table.push(new TransitionRow<T>(From, To, Condition));
		return this;
	}
	
	/**
	 * Removes a transition condition from the table
	 * @param	From	From State
	 * @param	To		To State
	 * @param	Condition	Condition function
	 * @return	True when removed, false if not in table
	 */
	public function remove(From:FlxFSMState<T>, To:FlxFSMState<T>, Condition:T->Bool):Bool
	{
		for (transition in _table)
		{
			if (Type.getClass(transition.from) == Type.getClass(From)
				&& Type.getClass(transition.to) == Type.getClass(To)
				&& transition.condition == Condition)
			{
				return _table.remove(transition);
			}
		}
		return false;
	}
}

private class TransitionRow<T>
{
	public function new(From:FlxFSMState<T>, To:FlxFSMState<T>, Condition:T->Bool)
	{
		from = From;
		condition = Condition;
		to = To;
	}
	public var from:FlxFSMState<T>;
	public var condition:T->Bool;
	public var to:FlxFSMState<T>;
}