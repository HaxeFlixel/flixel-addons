package flixel.addons.util;

import flixel.FlxG;
import flixel.math.FlxRandom;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxPool;
import flixel.util.FlxSignal.FlxTypedSignal;

/**
 * A generic FSM State implementation. Extend this class to create new states.
 */
class FlxFSMState<T> implements IFlxDestroyable
{
	public function new() {}

	/**
	 * Called when state becomes active.
	 *
	 * @param	owner	The object the state controls
	 * @param	fsm		The FSM instance this state belongs to. Used for changing the state to another.
	 */
	public function enter(owner:T, fsm:FlxFSM<T>):Void {}

	/**
	 * Called every update loop.
	 *
	 * @param	owner	The object the state controls
	 * @param	fsm		The FSM instance this state belongs to. Used for changing the state to another.
	 */
	public function update(elapsed:Float, owner:T, fsm:FlxFSM<T>):Void {}

	/**
	 * Called when the state becomes inactive.
	 *
	 * @param	owner	The object the state controls
	 */
	public function exit(owner:T):Void {}

	public function destroy():Void {}
}

/**
 * Helper typedef for FlxExtendedFSM's pools
 */
typedef StatePool<T> = Map<String, FlxPool<FlxFSMState<T>>>;

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
	 * Class of current state
	 */
	public var stateClass:Class<FlxFSMState<T>>;

	/**
	 * The age of the active state
	 */
	public var age:Float;

	/**
	 * Name of this FSM. Used for locking/unlocking when in a stack.
	 */
	public var name:String;

	/**
	 * Binary flag. Used for locking/unlocking when in a stack.
	 */
	public var type:Int;

	/**
	 * The stack this FSM belongs to or null
	 */
	public var stack:FlxFSMStack<T>;

	/**
	 * Optional transition table for this FSM
	 */
	public var transitions:FlxFSMTransitionTable<T>;

	/**
	 * Optional map object containing FlxPools for FlxFSMStates
	 */
	public var pools:StatePool<T>;

	public function new(?owner:T, ?state:FlxFSMState<T>)
	{
		this.age = 0;
		this.owner = owner;
		this.state = state;
		this.type = 0;
		this.transitions = new FlxFSMTransitionTable<T>();
		this.pools = new StatePool<T>();
	}

	/**
	 * Updates the active state instance.
	 */
	public function update(elapsed:Float):Void
	{
		if (state != null && owner != null)
		{
			age += elapsed;
			state.update(elapsed, owner, this);
		}

		if (transitions != null && pools != null)
		{
			var newStateClass = transitions.poll(stateClass, this.owner);

			if (newStateClass != stateClass)
			{
				var curName = null;
				if (stateClass != null)
					curName = Type.getClassName(stateClass);
				var newName = Type.getClassName(newStateClass);

				if (newName != null && !pools.exists(newName))
				{
					pools.set(newName, new FlxPool<FlxFSMState<T>>(newStateClass));
				}

				var returnToPool = state;

				state = pools.get(newName).get();

				if (state != null && curName != null && pools.exists(curName))
				{
					pools.get(curName).put(returnToPool);
				}
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
		name = null;
		transitions = null;
		pools = null;
	}

	function set_owner(owner:T):T
	{
		if (this.owner != owner)
		{
			if (this.owner != null && state != null)
			{
				state.exit(this.owner);
			}
			this.owner = owner;
			if (this.owner != null && state != null)
			{
				age = 0;
				state.enter(this.owner, this);
			}
		}
		return this.owner;
	}

	function set_state(state:FlxFSMState<T>):FlxFSMState<T>
	{
		var newClass = Type.getClass(state);
		if (this.stateClass != newClass)
		{
			if (owner != null && this.state != null)
			{
				this.state.exit(owner);
			}
			this.state = state;
			if (this.state != null && owner != null)
			{
				age = 0;
				this.state.enter(owner, this);
			}
			this.stateClass = newClass;
		}
		return state;
	}
}

/**
 * Used for grouping FSM instances and updating them according to the stack's updateMode.
 */
class FlxFSMStack<T> extends FlxFSMStackSignal implements IFlxDestroyable
{
	/**
	 * Test if the stack is empty
	 */
	public var isEmpty(get, never):Bool;

	var _stack:Array<FlxFSM<T>>;

	var _alteredStack:Array<FlxFSM<T>>;

	var _hasLocks:Bool;

	var _lockedNames:Array<String>;

	var _lockedTypes:Int;

	var _lockRemaining:Bool;

	public function new()
	{
		super();
		_stack = [];
		_lockedNames = [];
		_lockedTypes = 0;
		_hasLocks = false;
		FlxFSMStackSignal._lockSignal.add(lockType);
	}

	/**
	 * Updates the states that have not been locked
	 */
	public function update(elapsed:Float)
	{
		if (_alteredStack != null) // Stack was edited during the last loop. Adopt the changes
		{
			_stack = _alteredStack.copy();
			_alteredStack = null;
		}

		for (fsm in _stack)
		{
			if (_hasLocks)
			{
				if (_lockRemaining == false && (fsm.type & _lockedTypes) == 0 && _lockedNames.indexOf(fsm.name) == -1)
				{
					fsm.update(elapsed);
				}
			}
			else
			{
				fsm.update(elapsed);
			}
		}

		if (_lockedNames.length != 0)
		{
			_lockedNames = [];
		}
		_lockRemaining = false;
		_lockedTypes = 0;
		_hasLocks = false;
	}

	/**
	 * Locks the specified FSM for the duration of the update loop
	 * @param	name	The name of the FSM to lock
	 */
	public function lock(name:String):Void
	{
		if (_lockedNames.indexOf(name) == -1)
		{
			_lockedNames.push(name);
			_hasLocks = true;
		}
	}

	/**
	 * Locks the remaining FSMs for the duration of the update loop
	 */
	public function lockRemaining():Void
	{
		_lockRemaining = true;
		_hasLocks = true;
	}

	/**
	 * Locks by type, so that if `FSM.type & bitflag != 0`, the FSM gets locked.
	 * @param	bitflag		You can use `FSMType` abstract for values or build your own.
	 */
	public function lockType(bitflag:Int):Void
	{
		_lockedTypes |= bitflag;
		_hasLocks = true;
	}

	/**
	 * Adds the FSM to the front of the stack
	 * @param	FSM		The FSM to add
	 */
	public function unshift(FSM:FlxFSM<T>)
	{
		if (_alteredStack == null)
		{
			_alteredStack = _stack.copy();
		}
		FSM.stack = this;
		_alteredStack.unshift(FSM);
	}

	/**
	 * Removes the first FSM from the stack
	 * @return	The removed FSM
	 */
	public function shift():FlxFSM<T>
	{
		if (_alteredStack == null)
		{
			_alteredStack = _stack.copy();
		}
		var FSM = _alteredStack.shift();
		FlxDestroyUtil.destroy(FSM);
		return FSM;
	}

	/**
	 * Adds the FSM to the end of the stack
	 * @param	FSM		The FSM to add
	 */
	public function push(FSM:FlxFSM<T>)
	{
		if (_alteredStack == null)
		{
			_alteredStack = _stack.copy();
		}
		FSM.stack = this;
		_alteredStack.push(FSM);
	}

	/**
	 * Removes the first FSM from the stack
	 * @return	The removed FSM
	 */
	public function pop():FlxFSM<T>
	{
		if (_alteredStack == null)
		{
			_alteredStack = _stack.copy();
		}
		var FSM = _alteredStack.pop();
		lock(FSM.name); // FSM isn't updated during the remainder the loop current
		FlxDestroyUtil.destroy(FSM);
		return FSM;
	}

	/**
	 * Removes the FSM from the stack and destroys it
	 * @param	FSM		The FSM to remove
	 */
	public function remove(FSM:FlxFSM<T>)
	{
		if (_alteredStack == null)
		{
			_alteredStack = _stack.copy();
		}
		if (_alteredStack.remove(FSM))
		{
			lock(FSM.name); // FSM isn't updated during the remainder the current loop
			FlxDestroyUtil.destroy(FSM);
		}
	}

	/**
	 * Removes the FSM with given name from the stack and destroys it
	 * @param	name	The name of the FSM to remove
	 */
	public function removeByName(name:String)
	{
		for (fsm in _stack)
		{
			if (fsm.name == name)
			{
				remove(fsm);
			}
		}
	}

	/**
	 * Destroys every member in stack and self
	 */
	public function destroy():Void
	{
		for (fsm in _stack)
		{
			FlxDestroyUtil.destroy(fsm);
		}
		lockRemaining();
		FlxFSMStackSignal._lockSignal.remove(lockType);
	}

	function get_isEmpty():Bool
	{
		return (_stack.length == 0);
	}
}

/**
 * Base class for `FlxFSMStack<T>`
 * Only function is to create a static `FlxTypedSignal` that's shared between stacks.
 * Otherwise signals would be type specific, and `FlxFSMStack<A>` could not dispatch
 * to `FlxFSMStack<B>`
 */
private class FlxFSMStackSignal
{
	static var _lockSignal:FlxTypedSignal<Int->Void>;

	public function new()
	{
		if (FlxFSMStackSignal._lockSignal == null)
		{
			FlxFSMStackSignal._lockSignal = new FlxTypedSignal<Int->Void>();
		}
	}

	/**
	 * Sends a message to all active FSMStacks to lock given types.
	 * @param	type	You can use `FSMType` abstract for values or build your own.
	 */
	public function globalLock(type:Int):Void
	{
		FlxFSMStackSignal._lockSignal.dispatch(type);
	}
}

/**
 * Contains the information on when to transition from a given state to another.
 */
class FlxFSMTransitionTable<T>
{
	var _table:Array<Transition<T>>;
	var _startState:Class<FlxFSMState<T>>;
	var _garbagecollect:Bool = false;

	public function new()
	{
		_table = new Array<Transition<T>>();
	}

	/**
	 * Polls the transition table for active states
	 * @param	currentState	The class of the current FlxFSMState
	 * @param	owner			The FlxFSMState the table belongs to
	 * @return	The state that should become or remain active.
	 */
	public function poll(currentState:Class<FlxFSMState<T>>, owner:T):Class<FlxFSMState<T>>
	{
		if (currentState == null && _startState != null)
		{
			return _startState;
		}

		if (_garbagecollect)
		{
			_garbagecollect = false;
			var removeThese = [];
			for (transition in _table)
			{
				if (transition.remove == true)
				{
					if (transition.from == currentState)
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
			if (transition.from == currentState || transition.from == null)
			{
				if (transition.evaluate(owner) == true)
				{
					return transition.to;
				}
			}
		}

		return currentState;
	}

	/**
	 * Adds a transition condition to the table.
	 * @param	from		The state the condition applies to
	 * @param	to			The state to transition
	 * @param	condition	Function that returns true if the transition conditions are met
	 */
	public function add(from:Class<FlxFSMState<T>>, to:Class<FlxFSMState<T>>, condition:T->Bool)
	{
		if (hasTransition(from, to, condition) == false)
		{
			var row = new Transition<T>();
			row.from = from;
			row.to = to;
			row.condition = condition;
			_table.push(row);
		}
		return this;
	}

	/**
	 * Adds a global transition condition to the table.
	 * @param	to		The state to transition
	 * @param	condition	Function that returns true if the transition conditions are met
	 */
	public function addGlobal(to:Class<FlxFSMState<T>>, condition:T->Bool)
	{
		if (hasTransition(null, to, condition) == false)
		{
			var row = new Transition<T>();
			row.to = to;
			row.condition = condition;
			_table.push(row);
		}
		return this;
	}

	/**
	 * Add a transition directly
	 * @param	transition	The transition to add
	 */
	public function addTransition(transition:Transition<T>)
	{
		if (_table.indexOf(transition) == -1)
		{
			_table.push(transition);
		}
	}

	/**
	 * Sets the starting State
	 * @param	with	The class of the starting State
	 */
	public function start(with:Class<FlxFSMState<T>>)
	{
		_startState = with;
		return this;
	}

	/**
	 * Replaces given state class with another.
	 * @param	target			State class to replace
	 * @param	replacement		State class to replace with
	 */
	public function replace(target:Class<FlxFSMState<T>>, replacement:Class<FlxFSMState<T>>)
	{
		for (transition in _table)
		{
			if (transition.to == target)
			{
				transition.remove = true;
				if (transition.from == null)
				{
					addGlobal(replacement, transition.condition);
				}
				else
				{
					add(transition.from, replacement, transition.condition);
				}
				_garbagecollect = true;
			}
			if (transition.from == target)
			{
				transition.remove = true;
				add(replacement, transition.to, transition.condition);
				_garbagecollect = true;
			}
		}
	}

	/**
	 * Removes a transition condition from the table
	 * @param	from	From State
	 * @param	to		To State
	 * @param	condition	Condition function
	 * @return	True when removed, false if not in table
	 */
	public function remove(?from:Class<FlxFSMState<T>>, ?to:Class<FlxFSMState<T>>, ?condition:Null<T->Bool>)
	{
		switch ([from, to, condition])
		{
			case [f, null, null]:
				for (transition in _table)
				{
					if (from == transition.from)
					{
						transition.remove = true;
						_garbagecollect = true;
					}
				}
			case [f, t, null]:
				for (transition in _table)
				{
					if (from == transition.from && to == transition.to)
					{
						transition.remove = true;
						_garbagecollect = true;
					}
				}
			case [null, t, c]:
				for (transition in _table)
				{
					if (to == transition.to && condition == transition.condition)
					{
						transition.remove = true;
						_garbagecollect = true;
					}
				}
			case [f, t, c]:
				for (transition in _table)
				{
					if (from == transition.from && to == transition.to && condition == transition.condition)
					{
						transition.remove = true;
						_garbagecollect = true;
					}
				}
		}
	}

	/**
	 * Tells if the table contains specific transition or transitions.
	 * @param	from	From State
	 * @param	to		To State
	 * @param	condition	Condition function
	 * @return	True if match found
	 */
	public function hasTransition(?from:Class<FlxFSMState<T>>, ?to:Class<FlxFSMState<T>>, ?condition:Null<T->Bool>):Bool
	{
		switch ([from, to, condition])
		{
			case [f, null, null]:
				for (transition in _table)
				{
					if (from == transition.from && transition.remove == false)
					{
						return true;
					}
				}
			case [f, t, null]:
				for (transition in _table)
				{
					if (from == transition.from && to == transition.to && transition.remove == false)
					{
						return true;
					}
				}
			case [null, t, c]:
				for (transition in _table)
				{
					if (to == transition.to && condition == transition.condition && transition.remove == false)
					{
						return true;
					}
				}
			case [f, t, c]:
				for (transition in _table)
				{
					if (from == transition.from && to == transition.to && condition == transition.condition && transition.remove == false)
					{
						return true;
					}
				}
		}
		return false;
	}
}

class Transition<T>
{
	public function new() {}

	/**
	 * If this function returns true, the transition becomes active.
	 * Note: you can override this function if you don't want to use functions passed as variables.
	 */
	public function evaluate(target:T):Bool
	{
		return condition(target);
	}

	/**
	 * The state this transition applies to, or null for global transition, ie. from any state
	 */
	public var from:Class<FlxFSMState<T>>;

	/**
	 * The state this transition leads to
	 */
	public var to:Class<FlxFSMState<T>>;

	/**
	 * Function used for evaluation.
	 * The evaluation function may be overridden, in which case this param may be redundant.
	 */
	public var condition:T->Bool;

	/**
	 * Used to mark this transition for removal
	 */
	public var remove:Bool = false;
}
