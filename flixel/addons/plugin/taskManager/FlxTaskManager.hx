package flixel.addons.plugin.taskManager;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.util.FlxDestroyUtil;

/**
 * The Task Manager is used to perform tasks (call methods) in specified order.
 * Allows you to quickly and easily program any action, such as the appearance of the buttons in the game menus.
 * Task Manager is started automatically when you add at least one task, and stops when all tasks are done.
 *
 * @author Anton Karlov
 * @since  08.22.2012
 * @author Zaphod
 * @since  11.19.2012
 */
// TODO: update docs
class FlxTaskManager extends FlxBasic
{
	/**
	 * This function will be called when all tasks in the task manager are completed
	 */
	public var onComplete:Void->Void;

	/**
	 * Number of tasks in the list
	 */
	public var length(default, null):Int = 0;

	/**
	 * The list of active tasks
	 */
	var _taskList:FlxTask;

	/**
	 * Determines whether tasks are performed in a loop
	 */
	var _cycle:Bool = false;

	/**
	 * Used to calculate the current pause between tasks
	 */
	var _delay:Float = 0;

	public function new(Cycle:Bool = false, ?OnComplete:Void->Void)
	{
		super();
		_cycle = Cycle;
		onComplete = OnComplete;
	}

	override public function destroy():Void
	{
		clear();
		onComplete = null;
		kill();
	}

	/**
	 * Adds a task to the end of queue, the method will be executed while it returns false.
	 * The task will be completed only when the method will return true. And manager will switch to the next task.
	 *
	 * @param	Function		Method-task to be executed in sequence.
	 * @param	IgnoreCycle		If true then the task will be deleted from the manager immediately after execution.
	 */
	public function addTask(Function:Void->Bool, IgnoreCycle:Bool = false):Void
	{
		push(new FlxTask(Function, IgnoreCycle, false));
	}

	/**
	 * Adds a task to the end of queue, the method will be executed only ONCE, after that we go to the next task.
	 *
	 * @param	Function		Method-task to be executed in sequence.
	 * @param	IgnoreCycle		If true then the task will be deleted from the manager immediately after execution.
	 */
	public function addInstantTask(Function:Void->Bool, IgnoreCycle:Bool = false):Void
	{
		push(new FlxTask(Function, IgnoreCycle, true));
	}

	/**
	 * Adds a task to the top of the queue, the method will be executed while it returns false.
	 * The task will be completed only when the method will return true, and the manager will move to the next task.
	 *
	 * @param	Function		Method-task to be executed in sequence.
	 * @param	IgnoreCycle		If true then the task will be deleted from the manager immediately after execution.
	 */
	public function addUrgentTask(Function:Void->Bool, IgnoreCycle:Bool = false):Void
	{
		unshift(new FlxTask(Function, IgnoreCycle, false));
	}

	/**
	 * Adds a task to the top of the queue, the method will be executed only ONCE, after that we go to the next task.
	 *
	 * @param	Function		Method-task to be executed in sequence.
	 * @param	IgnoreCycle		If true then the task will be deleted from the manager immediately after execution.
	 */
	public function addUrgentInstantTask(Function:Void->Bool, IgnoreCycle:Bool = false):Void
	{
		unshift(new FlxTask(Function, IgnoreCycle, true));
	}

	/**
	 * Adds a pause between tasks
	 *
	 * @param	Delay		Pause duration
	 * @param	IgnoreCycle	If true, the pause will be executed only once per cycle
	 */
	public function addPause(Delay:Float, IgnoreCycle:Bool = false):Void
	{
		addTask(taskPause.bind(Delay), IgnoreCycle);
	}

	/**
	 * Removes all the tasks from manager and stops it
	 */
	public function clear():Void
	{
		_taskList = FlxDestroyUtil.destroy(_taskList);
		_delay = 0;
		length = 0;
	}

	/**
	 * Move to the next task
	 *
	 * @param	IgnoreCycle 	Specifies whether to leave the previous problem in the manager
	 */
	public function nextTask(IgnoreCycle:Bool = false):Void
	{
		if (_cycle && !IgnoreCycle)
		{
			push(shift());
		}
		else
		{
			FlxDestroyUtil.destroy(shift());
		}
	}

	/**
	 * Current task processing
	 */
	override public function update(elapsed:Float):Void
	{
		if (_taskList != null)
		{
			var result:Bool = _taskList.func();

			if (_taskList.instant || result)
			{
				nextTask(_taskList.ignoreCycle);
			}
		}
		else
		{
			if (onComplete != null)
			{
				onComplete();
			}
		}
	}

	/**
	 * Method-task for a pause between tasks
	 *
	 * @param	Delay	 Delay
	 * @return	True if the task completed successfully, false otherwise
	 */
	function taskPause(Delay:Float):Bool
	{
		_delay += Delay;

		if (_delay > Delay)
		{
			_delay = 0;
			return true;
		}

		return false;
	}

	/**
	 * Adds the specified object to the end of the list
	 *
	 * @param	Task	The FlxTask to be added.
	 * @return	A pointer to the added FlxTask.
	 */
	function push(Task:FlxTask):FlxTask
	{
		if (Task == null)
		{
			return null;
		}

		length++;

		if (_taskList == null)
		{
			_taskList = Task;
			return Task;
		}

		var cur:FlxTask = _taskList;

		while (cur.next != null)
		{
			cur = cur.next;
		}

		cur.next = Task;
		return Task;
	}

	/**
	 * Adds task to the top of task list
	 *
	 * @param	Task	The FlxTask to be added.
	 * @return	A pointer to the added FlxTask.
	 */
	function unshift(Task:FlxTask):FlxTask
	{
		length++;

		if (_taskList == null)
		{
			return Task;
		}

		var item:FlxTask = _taskList;
		_taskList = Task;
		_taskList.next = item;

		return Task;
	}

	/**
	 * Removes first task
	 *
	 * @return	The task that has been removed
	 */
	function shift():FlxTask
	{
		if (_taskList == null)
		{
			return null;
		}

		var item:FlxTask = _taskList;
		_taskList = item.next;
		item.next = null;
		length--;

		return item;
	}
}
