package flixel.addons.util;

import flixel.util.FlxDestroyUtil;
import flixel.math.FlxRandom;
import flixel.FlxG;

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
	
	/**
	 * The age of the active state
	 */
	public var age:Float;
	
	/**
	 * The stack this FSM belongs to or null
	 */
	public var stack:FlxFSMStack<T>;
	
	public function new(?Owner:T, ?State:FlxFSMState<T>)
	{
		age = 0;
		owner = Owner;
		state = State;
	}
	
	/**
	 * Updates the active state instance.
	 */
	public function update():Void
	{
		if (transitions != null)
		{
			if (state == null)
			{
				state = transitions.poll(this);
			}
			if (state != null && owner != null)
			{
				age += FlxG.elapsed;
				state.update(owner, this);
				state = transitions.poll(this);
			}
		}
		else
		{
			if (state != null && owner != null)
			{
				age += FlxG.elapsed;
				state.update(owner, this);
			}
		}
	}
	
	/**
	 * Calls exit on current state
	 */
	public function destroy():Void
	{
		owner = null;
		state = null;
		stack = null;
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
				age = 0;
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
				age = 0;
				state.enter(owner, this);
			}
		}
		return state;
	}
}

/**
 * A generic FSM State implementation. Extend this class to create new states.
 */
class FlxFSMState<T> implements IFlxDestroyable
{
	public function new() {	}
	
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

@:enum
abstract StackUpdateMode(Int) from Int to Int
{
	var First = 0;
	var All = 1;
	var Turns = 2;
	var Random = 3;
}

/**
 * Used for grouping FSM instances and updating them according to the stack's updateMode.
 */
class FlxFSMStack<T> implements IFlxDestroyable
{
	/**
	 * Test if the stack is empty
	 */
	public var isEmpty(get, never):Bool;
	
	/**
	 * The manager of this stack or null
	 */
	public var manager:FlxFSMManager<T>;
	
	/**
	 * How the stack updates the states.
	 * First:  Only the last inserted FSM receives the update call.
	 * All:    Every FSM is updated in order.
	 * Turns:  The FSMs are updated in turns every update call.
	 * Random: FSMs are updated in random order.
	 */
	public var updateMode:StackUpdateMode;
	
	private var _fsms:Array<FlxFSM<T>>;
	private var _updateIndex:Int = 0;
	
	public function new()
	{
		_fsms = [];
		updateMode = StackUpdateMode.All;
	}
	
	/**
	 * Updates the stack according to updateMode
	 */
	public function update()
	{
		if (_fsms.length > 0)
		{
			switch (updateMode)
			{
				case StackUpdateMode.First:
					_fsms[0].update();
				case StackUpdateMode.All:
					for (fsm in _fsms)
					{
						fsm.update();
					}
				case StackUpdateMode.Turns:
					if (_updateIndex >= _fsms.length)
					{
						_updateIndex = 0;
					}
					_fsms[_updateIndex].update();
					_updateIndex = (_updateIndex + 1) % _fsms.length;
				case StackUpdateMode.Random:
					FlxRandom.getObject(_fsms).update();
			}
		}
	}
	
	/**
	 * Adds the FSM to the front of the stack
	 * @param	FSM
	 */
	public function add(FSM:FlxFSM<T>)
	{
		FSM.stack = this;
		_fsms.unshift(FSM);
	}
	
	/**
	 * Removes the FSM from the stack and destroys it
	 * @param	FSM
	 */
	public function remove(FSM:FlxFSM<T>)
	{
		if (_fsms.remove(FSM))
		{
			FlxDestroyUtil.destroy(FSM);
		}
	}
	
	/**
	 * Destroys every member in stack and self
	 */
	public function destroy():Void
	{
		for (fsm in _fsms)
		{
			FlxDestroyUtil.destroy(fsm);
		}
		manager = null;
	}
	
	private function get_isEmpty():Bool
	{
		return (_fsms.length == 0);
	}
}

/**
 * Creates, alters, updates and destroys stacks.
 */
class FlxFSMManager<T>
{
	private var _stacks:Map < String, FlxFSMStack<T> >;
	
	public function new()
	{
		_stacks = new Map();
	}
	
	/**
	 * Updates all the stacks within this manager
	 */
	public function update()
	{
		for (stack in _stacks)
		{
			stack.update();
		}
	}
	
	/**
	 * Destroys the given stack and removes it from the list
	 * @param	Key
	 */
	public function removeStack(Key:String = "__Default__")
	{
		if (_stacks.exists(Key))
		{
			FlxDestroyUtil.destroy(_stacks.get(Key));
			_stacks.remove(Key);
		}
	}
	
	/**
	 * Adds the given FSM to specified stack. If the stack with given Key does not exist, it is created.
	 * @param	FSM
	 * @param	Key
	 */
	public function pushToStack(FSM:FlxFSM<T>, Key:String = "__Default__", UpdateMode:StackUpdateMode = StackUpdateMode.First)
	{
		if (_stacks.exists(Key) == false)
		{
			var stack = new FlxFSMStack<T>();
			stack.manager = this;
			_stacks.set(Key, stack);
		}
		_stacks.get(Key).updateMode = UpdateMode;
		_stacks.get(Key).add(FSM);
	}
	
	/**
	 * Removes the given FSM from the specified stack.
	 * @param	FSM
	 * @param	Key
	 */
	public function removeFromStack(FSM:FlxFSM<T>, Key:String = "__Default__")
	{
		if (_stacks.exists(Key))
		{
			var stack = _stacks.get(Key);
			stack.remove(FSM);
			if (stack.isEmpty)
			{
				_stacks.remove(Key);
			}
		}
	}
	
	public function destroy():Void
	{
		for (key in _stacks.keys())
		{
			removeStack(key);
		}
		_stacks = null;
	}
}

/**
 * Contains the information on when to transition from a given state to another.
 */
class FlxFSMTransitionTable<T>
{
	/**
	 * Storage of activated states. You can add states manually with class path => state instance
	 * pairs in case your states are pooled and should not be created separately.
	 */
	public var states:Map<String, FlxFSMState<T>>;
	
	private var _table:Array<TransitionRow<T>>;
	private var _startState:String;
	private var _garbagecollect:Bool = false;
	
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
		
		if (_garbagecollect)
		{
			_garbagecollect = false;
			var removeThese = [];
			for (transition in _table)
			{
				if (transition.remove == true)
				{
					if (transition.from == currentStateClass)
					{
						_garbagecollect = true;
					}
					else
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
				transition.remove = true;
				if (transition.from == null)
				{
					addGlobal(Replacement, transition.condition);
				}
				else
				{					
					add(transition.from, Replacement, transition.condition);
				}
				_garbagecollect = true;
			}
			if (transition.from == Target)
			{
				transition.remove = true;
				add(Replacement, transition.to, transition.condition);
				_garbagecollect = true;
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
		switch([From, To, Condition])
		{
			case [f, null, null]:
				for (transition in _table)
				{
					if (From == transition.from)
					{
						transition.remove = true;
						_garbagecollect = true;
					}
				}
			case [f, t, null]:
				for (transition in _table)
				{
					if (From == transition.from && To == transition.to)
					{
						transition.remove = true;
						_garbagecollect = true;
					}
				}
			case [null, t, c]:
				for (transition in _table)
				{
					if (To == transition.to && Condition == transition.condition)
					{
						transition.remove = true;
						_garbagecollect = true;
					}
				}
			case [f, t, c]:
				for (transition in _table)
				{
					if (From == transition.from && To == transition.to && Condition == transition.condition)
					{
						transition.remove = true;
						_garbagecollect = true;
					}
				}
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
					if (From == transition.from && transition.remove == false)
					{
						return true;
					}
				}
			case [f, t, null]:
				for (transition in _table)
				{
					if (From == transition.from && To == transition.to && transition.remove == false)
					{
						return true;
					}
				}
			case [null, t, c]:
				for (transition in _table)
				{
					if (To == transition.to && Condition == transition.condition && transition.remove == false)
					{
						return true;
					}
				}
			case [f, t, c]:
				for (transition in _table)
				{
					if (From == transition.from && To == transition.to && Condition == transition.condition && transition.remove == false)
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
	public var remove:Bool = false;
}
