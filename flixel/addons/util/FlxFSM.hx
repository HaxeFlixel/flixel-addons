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
	 * The age of the active state
	 */
	public var age:Float;
	
	/**
	 * The stack this FSM belongs to or null
	 */
	public var stack:FlxFSMStack<T>;
	
	public var active:Bool = false;
	
	public function new(?Owner:T, ?State:FlxFSMState<T>)
	{
		age = 0;
		owner = Owner;
		state = State;
		active = true;
	}
	
	/**
	 * Updates the active state instance.
	 */
	public function update():Void
	{
		if (active == true && state != null && owner != null)
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
		active = false;
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
	
	private var currentState:Class<FlxFSMState<T>>;
	
	public function new(?Owner:T, ?Transitions:FlxFSMTransitionTable<T>, ?Pool:StatePool<T>)
	{
		super(Owner);
		transitions = Transitions;
		if (Pool != null)
		{			
			pools = Pool;
		}
		else
		{
			pools = new StatePool();
		}
	}
	
	override public function update():Void
	{
		super.update();
		
		if (transitions != null && pools != null)
		{
			var newState = transitions.poll(currentState, this.owner);
			
			if (newState != currentState)
			{
				var currentName = Type.getClassName(currentState);
				var newName = Type.getClassName(newState);
				
				if (pools.exists(newName) == false)
				{
					pools.set(newName, new FlxPool<FlxFSMState<T>>(newState));
				}
				
				var returnToPool = state;
				
				state = pools.get(newName).get();
				
				if (pools.exists(currentName))
				{
					pools.get(currentName).put(returnToPool);
				}
				
				currentState = newState;
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
	
	private var _fsms:Array<FlxFSM<T>>;
	
	public function new()
	{
		_fsms = [];
	}
	
	/**
	 * Updates the stack according to updateMode
	 */
	public function update()
	{
		for (fsm in _fsms)
		{
			fsm.update();
		}
	}
	
	public function add(FSM:FlxFSM<T>)
	{
		unshift(FSM);
	}
	/**
	 * Adds the FSM to the front of the stack
	 * @param	FSM
	 */
	public function unshift(FSM:FlxFSM<T>)
	{
		FSM.stack = this;
		_fsms.unshift(FSM);
	}
	
	/**
	 * Adds the FSM to the end of the stack
	 * @param	FSM
	 */
	public function push(FSM:FlxFSM<T>)
	{
		FSM.stack = this;
		_fsms.push(FSM);
	}
	
	/**
	 * 
	 * @return
	 */
	public function pop():FlxFSM<T>
	{
		var FSM = _fsms.pop();
		FlxDestroyUtil.destroy(FSM);
		return FSM;
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
	}
	
	private function get_isEmpty():Bool
	{
		return (_fsms.length == 0);
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
	public function poll(CurrentState:Class<FlxFSMState<T>>, Owner:T):Class<FlxFSMState<T>>
	{
		if (CurrentState == null && _startState != null)
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
					if (transition.from == CurrentState)
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
			if (transition.from == CurrentState || transition.from == null)
			{
				if (transition.condition(Owner) == true)
				{
						return transition.to;
				}
			}
		}
		
		return CurrentState;
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
		_startState = With;
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
