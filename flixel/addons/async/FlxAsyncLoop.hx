package flixel.addons.async;

import flixel.FlxBasic;

/**
 * Special class for asynchonously performing a loop.
 * @author Timothy Ian Hely / SeiferTim
 */

class FlxAsyncLoop extends FlxBasic
{
	
	private var _started:Bool;
	private var _finished:Bool;
	private var _curNo:Int;
	private var _iterationsPer:Int;
	private var _iterations:Int;
	
	private var _function:Dynamic;
	private var _object:Dynamic;
	
	/**
	 * Creates an instance of the FlxAsyncLoop class, used to do a loop while still allowing update() to get called and the screen to refresh.
	 * 
	 * @param	Iterations				How many total times should it loop
	 * @param	LoopFunction			The function that should be called each loop
	 * @param	?LoopObject				Optional: an object to pass to the function
	 * @param	?IterationsPerUpdate	Optional: how many loops before we allow an update() - defaults to 100.
	 */
	public function new(Iterations:Int, LoopFunction:Dynamic, ?LoopObject:Dynamic = null, ?IterationsPerUpdate:Int = 100) 
	{
		super();
		
		_started = false;
		_finished = false;
		_object = LoopObject;
		_iterations = Iterations;
		_function = LoopFunction;
		_curNo = 0;
		_iterationsPer = IterationsPerUpdate;
	}
	
	override public function draw():Void 
	{
		// we don't want to draw anything here.
	}
	
	/**
	 * Start the loop (if it's not already started or finished)
	 */
	public function start():Void
	{
		if (_finished || _started) return;
		_curNo = 0;
		_started = true;
	}
	
	override public function update():Void 
	{
		if (!_started || _finished) return;
		
		var startNo:Int = _curNo;
		for (i in startNo...Std.int(Math.min(startNo + _iterationsPer, _iterations)))
		{
			// call our function
			_function(_object);
			_curNo++;
		}
		if (_curNo >= _iterations)
			_finished = true;
			
		super.update();
	}
	
	
	override public function destroy():Void 
	{
		_object = null;
		_function = null;
		super.destroy();
	}
	
	function get_finished():Bool 
	{
		return _finished;
	}
	/**
	 * will be true once the loop has finished
	 */
	public var finished(get_finished, null):Bool;
	
	function get_started():Bool 
	{
		return _started;
	}
	/**
	 * will be true once start() is called and the loop starts
	 */
	public var started(get_started, null):Bool;
	
}