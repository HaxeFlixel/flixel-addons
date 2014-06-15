package flixel.addons.util;

import flixel.util.FlxDestroyUtil;
import flixel.math.FlxRandom;
import flixel.FlxG;
import flixel.util.FlxPool;

/**
 * A generic FSM State implementation. Extend this class to create new states.
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
	
	public function new(?owner:T, ?state:FlxFSMState<T>)
	{
		this.age = 0;
		this.owner = owner;
		this.state = state;
		this.type = FSMType.any;
	}
	
	/**
	 * Updates the active state instance.
	 */
	public function update():Void
	{
		if (state != null && owner != null)
		{
			age += FlxG.elapsed;
			state.update(owner, this);
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
		type = FSMType.any;
	}
	
	private function set_owner(owner:T):T
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
	
	private function set_state(state:FlxFSMState<T>):FlxFSMState<T>
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
 * Sample bitflags for FSM's type
 */
@:enum
abstract FSMType(Int) from Int to Int
{
	var any = 1;
	var actor = 2;
	var ai = 4;
	var animation = 8;
	var area = 16;
	var audio = 32;
	var collision = 64;
	var damage = 128;
	var effect = 256;
	var environment = 512;
	var game = 1024;
	var machine = 2048;
	var menu = 4096;
	var npc = 8192;
	var particle = 16384;
	var physics = 32768;
	var pickup = 65536;
	var player = 131072;
	var projectile = 262144;
	var text = 524288;
}

/**
 * Helper typedef for FlxExtendedFSM's pools
 */
typedef StatePool<T> = Map<String, FlxPool<FlxFSMState<T>>>

/**
 * Extended FSM that implements transition tables and pooling.
 */
class FlxExtendedFSM<T> extends FlxFSM<T>
{
	/**
	 * The transition table for this FSM
	 */
	public var transitions:FlxFSMTransitionTable<T>;
	
	/**
	 * A Map object containing FlxPools for FlxFSMStates
	 */
	public var pools:StatePool<T>;
	
	public function new(?owner:T, ?transitions:FlxFSMTransitionTable<T>, ?pool:StatePool<T>)
	{
		super(owner);
		
		if (transitions != null)
		{			
			this.transitions = transitions;
		}
		else
		{
			this.transitions = new FlxFSMTransitionTable();
		}

		if (pool != null)
		{			
			this.pools = pool;
		}
		else
		{
			this.pools = new StatePool();
		}
	}
	
	/**
	 * Updates FSM and inits transitions
	 */
	override public function update():Void
	{
		super.update();
		
		if (transitions != null && pools != null)
		{
			var newStateClass = transitions.poll(stateClass, this.owner);
			
			if (newStateClass != stateClass)
			{
				var curName = Type.getClassName(stateClass);
				var newName = Type.getClassName(newStateClass);
				
				if (pools.exists(newName) == false)
				{
					pools.set(newName, new FlxPool<FlxFSMState<T>>(newStateClass));
				}
				
				var returnToPool = state;
				
				state = pools.get(newName).get();
				
				if (pools.exists(curName))
				{
					pools.get(curName).put(returnToPool);
				}
			}
		}
	}
	
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
	
	private var _stack:Array<FlxFSM<T>>;
	
	private var _alteredStack:Array<FlxFSM<T>>;
	
	private var _locked:Array<String>;
	
	private var _lockedTypes:Int;
	
	private var _lockRemaining:Bool;
	
	public function new()
	{
		_stack = [];
		_locked = [];
		_lockedTypes = 0;
	}
	
	/**
	 * Updates the states that have not been locked
	 */
	public function update()
	{
		if (_alteredStack != null) // Stack was edited during the last loop. Adopt the changes
		{
			_stack = _alteredStack.copy();
			_alteredStack = null;
		}
		
		for (fsm in _stack)
		{
			if (_lockRemaining == false && (fsm.type & _lockedTypes) == 0 && _locked.indexOf(fsm.name) == -1)
			{				
				fsm.update();
			}
		}
		
		_locked = [];
		_lockRemaining = false;
		_lockedTypes = 0;
	}
	
	/**
	 * Locks the specified FSM for the duration of the update loop
	 * @param	name
	 */
	public function lock(name:String):Void
	{
		if (_locked.indexOf(name) == -1)
		{
			_locked.push(name);
		}
	}
	
	/**
	 * Locks the remaining FSMs for the duration of the update loop
	 */
	public function lockRemaining():Void
	{
		_lockRemaining = true;
	}
	
	/**
	 * Locks by type, so that if `FSM.type & bitflag != 0`, the FSM gets locked.
	 * @param	bitflag		You can use `FSMType` abstract for values or build your own.
	 */
	public function lockType(bitflag:Int):Void
	{
		_lockedTypes |= bitflag;
	}
	
	/**
	 * Adds the FSM to the front of the stack
	 * @param	FSM
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
	 * @param	FSM
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
		lock(FSM.name);	// FSM isn't updated during the remainder the loop current
		FlxDestroyUtil.destroy(FSM);
		return FSM;
	}
	
	/**
	 * Removes the FSM from the stack and destroys it
	 * @param	The removed FSM
	 */
	public function remove(FSM:FlxFSM<T>)
	{
		if (_alteredStack == null)
		{
			_alteredStack = _stack.copy();
		}
		if (_alteredStack.remove(FSM))
		{
			lock(FSM.name); // FSM isn't updated during the remainder the loop current
			FlxDestroyUtil.destroy(FSM);
		}
	}
	
	/**
	 * Removes the FSM with given name from the stack and destroys it
	 * @param	The removed FSM
	 */
	public function removeByName(name:String)
	{	
		var toRemove:FlxFSM<T> = null;
		for (fsm in _stack)
		{
			if (fsm.name == name)
			{
				toRemove = fsm;
				break;
			}
		}
		if (toRemove != null)
		{			
			remove(toRemove);
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
	}
	
	private function get_isEmpty():Bool
	{
		return (_stack.length == 0);
	}
}

/**
 * Contains the information on when to transition from a given state to another.
 */
class FlxFSMTransitionTable<T>
{
	
	private var _table:Array<TransitionRow<T>>;
	private var _startState:Class<FlxFSMState<T>>;
	private var _garbagecollect:Bool = false;
	
	public function new()
	{
		_table = new Array<TransitionRow<T>>();
	}
	
	/**
	 * Polls the transition table for active states
	 * @param	FSM	The FlxFSMState the table belongs to
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
				if (transition.condition(owner) == true)
				{
						return transition.to;
				}
			}
		}
		
		return currentState;
	}
	
	/**
	 * Adds a transition condition to the table.
	 * @param	From	The state the condition applies to
	 * @param	To		The state to transition
	 * @param	Condition	Function that returns true if the transition conditions are met
	 */
	public function add(from:Class<FlxFSMState<T>>, to:Class<FlxFSMState<T>>, condition:T->Bool)
	{
		if (hasTransition(from, to, condition) == false)
		{
			_table.push(new TransitionRow<T>(from, to, condition));
		}
		return this;
	}
	
	/**
	 * Adds a global transition condition to the table.
	 * @param	To		The state to transition
	 * @param	Condition	Function that returns true if the transition conditions are met
	 */
	public function addGlobal(to:Class<FlxFSMState<T>>, condition:T->Bool)
	{
		if (hasTransition(null, to, condition) == false)
		{
			_table.push(new TransitionRow<T>(null, to, condition));
		}
		return this;
	}
	
	/**
	 * Sets the starting State
	 * @param	With
	 */
	public function start(with:Class<FlxFSMState<T>>)
	{
		_startState = with;
		return this;
	}
	
	/**
	 * Replaces given state class with another.
	 * @param	Target			State class to replace
	 * @param	Replacement		State class to replace with
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
	 * @param	From	From State
	 * @param	To		To State
	 * @param	Condition	Condition function
	 * @return	True when removed, false if not in table
	 */
	public function remove(?from:Class<FlxFSMState<T>>, ?to:Class<FlxFSMState<T>>, ?condition:T->Bool)
	{
		switch([from, to, condition])
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
	 * @param	?From	From State
	 * @param	?To		To State
	 * @param	?Condition	Condition function
	 * @return	True if match found
	 */
	public function hasTransition(?from:Class<FlxFSMState<T>>, ?to:Class<FlxFSMState<T>>, ?condition:T->Bool):Bool
	{
		switch([from, to, condition])
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

private class TransitionRow<T>
{
	public function new(?from:Class<FlxFSMState<T>>, ?to:Class<FlxFSMState<T>>, ?condition:T->Bool)
	{
		set(from, to, condition);
	}
	
	public function set(?from:Class<FlxFSMState<T>>, ?to:Class<FlxFSMState<T>>, ?condition:T->Bool)
	{
		this.from = from;
		this.condition = condition;
		this.to = to;
	}
	
	public var from:Class<FlxFSMState<T>>;
	public var condition:T->Bool;
	public var to:Class<FlxFSMState<T>>;
	public var remove:Bool = false;
}
