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
	public var owner(default, set):T;
	
	/**
	 * Current state
	 */
	public var state(default, set):FlxFSMState<T>;
	
	/**
	 * Transition table
	 */
	public var transitions:FlxFSMTransitionTable<T>;
	
	public function new(?Owner:T, ?State:FlxFSMState<T>)
	{
		transitions = new FlxFSMTransitionTable<T>();
		owner = Owner;
		state = State;
	}
	
	/**
	 * Updates the active state instance.
	 */
	public function update():Void
	{
		if (state == null)
		{
			state = transitions.poll(this);
		}
		if (state != null && owner != null)
		{
			state.update(owner, this);
			state = transitions.poll(this);
		}
	}
	
	/**
	 * Calls exit on current state
	 */
	public function destroy():Void
	{
		owner = null;
		state = null;
	}
	
	private function set_owner(Owner:T):T
	{
		if (owner != Owner)
		{
			if (owner != null && state != null)
			{
				state.exit(owner);
			}
			owner = Owner;
			if (owner != null && state != null)
			{
				state.enter(Owner, this);
			}
		}
		return owner;
	}
	
	private function set_state(State:FlxFSMState<T>):FlxFSMState<T>
	{
		if (Type.getClass(state) != Type.getClass(State))
		{
			if (owner != null && state != null)
			{
				state.exit(owner);
			}
			state = State;
			if (state != null && owner != null)
			{
				state.enter(owner, this);
			}
		}
		return state;
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

typedef FlxFSMStack<T> = Array < FlxFSM<T> > ;
typedef FlxFSMStackMap<T> = Map < String, FlxFSMStack<T> > ;

class FlxFSMGroup<T>
{
	private var _stacks:FlxFSMStackMap<T>;
	
	public function new() {
		_stacks = new FlxFSMStackMap<T>();
	}
	
	public function update()
	{
		for (stack in _stacks)
		{
			if (stack.length > 0)
			{
				stack[0].update();
			}
		}
	}
	
	public function removeStack(Key:String = "__Default__")
	{
		if (_stacks.exists(Key))
		{
			for (fsm in _stacks.get(Key))
			{
				FlxDestroyUtil.destroy(fsm);
			}
			return _stacks.remove(Key);
		}
		return;
	}
	
	public function pushToStack(FSM:FlxFSM<T>, Key:String = "__Default__")
	{
		if (_stacks.exists(Key) == false)
		{
			_stacks.set(Key, new FlxFSMStack<T>());
		}
		_stacks.get(Key).unshift(FSM);
	}
	
	public function removeFromStack(FSM:FlxFSM<T>, Key:String = "__Default__")
	{
		if (_stacks.exists(Key))
		{
			var newStack = new FlxFSMStack<T>();
			for (fsm in _stacks.get(Key))
			{
				if (Type.getClass(fsm) != Type.getClass(FSM))
				{
					newStack.push(fsm);
				}
				else
				{
					FlxDestroyUtil.destroy(fsm);
				}
			}
			if (newStack.length == 0)
			{
				_stacks.remove(Key);
			}
			else
			{				
				_stacks.set(Key, newStack);
			}
		}
	}
	
	public function destroy():Void
	{
		for (key in _stacks.keys())
		{
			removeStack(key);
		}
	}
}

private class FlxFSMTransitionTable<T>
{
	/**
	 * Storage of activated states. You can add states manually with class path => state instance
	 * pairs in case your states are pooled and should not be created separately.
	 */
	public var states:Map<String, FlxFSMState<T>>;
	
	private var _table:Array<TransitionRow<T>>;
	private var _startState:String;
	
	public function new()
	{
		_table = new Array<TransitionRow<T>>();
		states = new Map();
	}
	
	/**
	 * Polls the transition table for active states
	 * @param	FSM	The FlxFSMState the table belongs to
	 * @return	The state that should become or remain active.
	 */
	public function poll(FSM:FlxFSM<T>):FlxFSMState<T>
	{
		if (FSM.state == null && _startState != null)
		{
			return states.get(_startState);
		}
		var currentStateClass = Type.getClass(FSM.state);
		var currentOwner = FSM.owner;
		for (transition in _table)
		{
			if (transition.from == currentStateClass || transition.from == null)
			{
				if (transition.condition(currentOwner) == true)
				{
						var className = Type.getClassName(transition.to);
						if (states.exists(className) == false)
						{
							states.set(className, Type.createEmptyInstance(transition.to));
						}
						return states.get(className);
				}
			}
			
		}
		return FSM.state;
	}
	
	/**
	 * Adds a transition condition to the table.
	 * @param	From	The state the condition applies to
	 * @param	To		The state to transition
	 * @param	Condition	Function that returns true if the transition conditions are met
	 */
	public function add(From:Class<FlxFSMState<T>>, To:Class<FlxFSMState<T>>, Condition:T->Bool)
	{
		if (hasTransition(From, To, Condition) == false)
		{
			_table.push(new TransitionRow<T>(From, To, Condition));
		}
		return this;
	}
	
	/**
	 * Adds a global transition condition to the table.
	 * @param	To		The state to transition
	 * @param	Condition	Function that returns true if the transition conditions are met
	 */
	public function addGlobal(To:Class<FlxFSMState<T>>, Condition:T->Bool)
	{
		if (hasTransition(null, To, Condition) == false)
		{
			_table.push(new TransitionRow<T>(null, To, Condition));
		}
		return this;
	}
	
	/**
	 * Sets the starting State
	 * @param	With
	 */
	public function start(With:Class<FlxFSMState<T>>)
	{
		_startState = Type.getClassName(With);
		if (states.exists(_startState) == false)
		{
			states.set(_startState, Type.createEmptyInstance(With));
		}
		return this;
	}
	
	/**
	 * Replaces given state class with another.
	 * @param	Target			State class to replace
	 * @param	Replacement		State class to replace with
	 */
	public function replace(Target:Class<FlxFSMState<T>>, Replacement:Class<FlxFSMState<T>>)
	{
		for (transition in _table)
		{
			if (transition.to == Target)
			{
				transition.to = Replacement;
			}
			if (transition.from == Target)
			{
				transition.to = Replacement;
			}
		}
	}
	
	/**
	 * Removes a transition condition from the table
	 * @param	From	From State
	 * @param	To		To State
	 * @param	Condition	Condition function
	 * @return	True when removed, false if not in table
	 */
	public function remove(?From:Class<FlxFSMState<T>>, ?To:Class<FlxFSMState<T>>, ?Condition:T->Bool)
	{
		var removeThese = [];
		switch([From, To, Condition])
		{
			case [f, null, null]:
				for (transition in _table)
				{
					if (From == transition.from)
					{
						removeThese.push(transition);
					}
				}
			case [f, t, null]:
				for (transition in _table)
				{
					if (From == transition.from && To == transition.to)
					{
						removeThese.push(transition);
					}
				}
			case [null, t, c]:
				for (transition in _table)
				{
					if (To == transition.to && Condition == transition.condition)
					{
						removeThese.push(transition);
					}
				}
			case [f, t, c]:
				for (transition in _table)
				{
					if (From == transition.from && To == transition.to && Condition == transition.condition)
					{
						removeThese.push(transition);
					}
				}
		}
		for (transition in removeThese)
		{
			_table.remove(transition);
		}
	}
	
	/**
	 * Tells if the table contains specific transition or transitions.
	 * @param	?From	From State
	 * @param	?To		To State
	 * @param	?Condition	Condition function
	 * @return	True if match found
	 */
	public function hasTransition(?From:Class<FlxFSMState<T>>, ?To:Class<FlxFSMState<T>>, ?Condition:T->Bool):Bool
	{
		switch([From, To, Condition])
		{
			case [f, null, null]:
				for (transition in _table)
				{
					if (From == transition.from)
					{
						return true;
					}
				}
			case [f, t, null]:
				for (transition in _table)
				{
					if (From == transition.from && To == transition.to)
					{
						return true;
					}
				}
			case [null, t, c]:
				for (transition in _table)
				{
					if (To == transition.to && Condition == transition.condition)
					{
						return true;
					}
				}
			case [f, t, c]:
				for (transition in _table)
				{
					if (From == transition.from && To == transition.to && Condition == transition.condition)
					{
						return true;
					}
				}
		}
		return false;
	}
}

private class TransitionRow<T>
{
	public function new(?From:Class<FlxFSMState<T>>, ?To:Class<FlxFSMState<T>>, ?Condition:T->Bool)
	{
		set(From, To, Condition);
	}
	
	public function set(?From:Class<FlxFSMState<T>>, ?To:Class<FlxFSMState<T>>, ?Condition:T->Bool)
	{
		from = From;
		condition = Condition;
		to = To;
	}
	
	public var from:Class<FlxFSMState<T>>;
	public var condition:T->Bool;
	public var to:Class<FlxFSMState<T>>;
}
