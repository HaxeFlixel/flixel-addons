package flixel.addons.util;

import flixel.FlxBasic;

/**
 * Special class for asynchonously performing a loop.
 * @author Timothy Ian Hely / SeiferTim
 */

class FlxAsyncLoop extends FlxBasic
{
	
	public var _started(default, null):Bool = false;
	public var _finished(default, null):Bool = false;
	private var _curIndex:Int = 0;
	private var _iterationsPerUpdate:Int;
	private var _iterations:Int;
	private var _callback:Void->Void;
	
	/**
	 * Creates an instance of the FlxAsyncLoop class, used to do a loop while still allowing update() to get called and the screen to refresh.
	 * 
	 * @param	Iterations				How many total times should it loop
	 * @param	Callback				The function that should be called each loop
	 * @param	?IterationsPerUpdate	Optional: how many loops before we allow an update() - defaults to 100.
	 */
	public function new(Iterations:Int, Callback:Void->Void, ?LoopObject:Dynamic = null, ?IterationsPerUpdate:Int = 100) 
	{
		super();
		visible = false;
		_object = LoopObject;
		_iterations = Iterations;
		_callback = Callback;
		_iterationsPerUpdate = IterationsPerUpdate;
	}
	
	
	/**
	 * Start the loop (if it's not already started or finished)
	 */
	public function start():Void
	{
		if (_finished || _started)
			return;
		_curIndex = 0;
		_started = true;
	}
	
	override public function update():Void 
	{
		if (!_started || _finished)
			return;
		
		var startNo:Int = _curIndex;
		for (i in startNo...Std.int(Math.min(startNo + _iterationsPerUpdate, _iterations)))
		{
			// call our function
			_callback();
			_curIndex++;
		}
		if (_curIndex >= _iterations)
			_finished = true;
		
		super.update();
	}
	
	
	override public function destroy():Void 
	{
		_curIndex = null;
		super.destroy();
	}
	
}