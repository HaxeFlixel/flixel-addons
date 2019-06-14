package flixel.addons.util;

import flixel.FlxBasic;

/**
 * Special class for asynchonously performing a loop.
 * @author Timothy Ian Hely / SeiferTim
 */
class FlxAsyncLoop extends FlxBasic
{
	public var started(default, null):Bool = false;
	public var finished(default, null):Bool = false;

	var _curIndex:Int = 0;
	var _iterationsPerUpdate:Int;
	var _iterations:Int;
	var _callback:Void->Void;

	/**
	 * Creates an instance of the FlxAsyncLoop class, used to do a loop while still allowing update() to get called and the screen to refresh.
	 *
	 * @param	Iterations		How many total times should it loop
	 * @param	Callback		The function that should be called each loop
	 * @param	IterationsPerUpdate	Optional: how many loops before we allow an update() - defaults to 100.
	 */
	public function new(Iterations:Int, Callback:Void->Void, IterationsPerUpdate:Int = 100)
	{
		super();
		visible = false;
		_iterations = Iterations;
		_callback = Callback;
		_iterationsPerUpdate = IterationsPerUpdate;
	}

	/**
	 * Start the loop (if it's not already started or finished)
	 */
	public function start():Void
	{
		if (finished || started)
			return;
		_curIndex = 0;
		started = true;
	}

	override public function update(elapsed:Float):Void
	{
		if (!started || finished)
			return;

		for (i in _curIndex...Std.int(Math.min(_curIndex + _iterationsPerUpdate, _iterations)))
		{
			// call our function
			_callback();
			_curIndex++;
		}
		if (_curIndex >= _iterations)
			finished = true;

		super.update(elapsed);
	}

	override public function destroy():Void
	{
		_callback = null;
		super.destroy();
	}
}
