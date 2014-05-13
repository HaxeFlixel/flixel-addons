package flixel.addons.plugin.taskManager;

import flixel.util.FlxDestroyUtil;

/**
 * @author Anton Karlov
 * @since  08.22.2012
 * @author Zaphod
 * @since  11.19.2012
 */
class AntTask implements IFlxDestroyable
{
	/**
	 * Method-task to be executed
	 */
	public var func:Void->Bool;
	/**
	 * If true then the task will be deleted from the manager immediately after execution.
	 */
	public var ignoreCycle:Bool;
	/**
	 * If true the task will be completed right after it's first call
	 */
	public var instant:Bool;
	/**
	 * Pointer to the next task.
	 */
	public var next:AntTask;
	
	/**
	 * Creates a new AntTask
	 */
	public function new(Func:Void->Bool, IgnoreCycle:Bool = false, Instant:Bool = false, ?Next:AntTask)
	{
		func = Func;
		ignoreCycle = IgnoreCycle;
		instant = Instant;
		next = Next;
	}
	
	/**
	 * Destroys the list.
	 */
	public function destroy():Void
	{
		next = FlxDestroyUtil.destroy(next);
		func = null;
	}
}