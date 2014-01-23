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
		
	}
	
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
	
	public var finished(get_finished, null):Bool;
	
	function get_started():Bool 
	{
		return _started;
	}
	
	public var started(get_started, null):Bool;
	
}