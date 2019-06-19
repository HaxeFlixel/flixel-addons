package flixel.addons.tile;

import flixel.util.FlxDestroyUtil;

class FlxTileAnimation implements IFlxDestroyable
{
	/**
	 * String name of the animation (e.g. "walk")
	 */
	public var name:String;

	/**
	 * Seconds between frames (basically the framerate)
	 */
	public var delay:Float;

	/**
	 * A list of frames stored as int objects
	 */
	public var frames:Array<Int>;

	/**
	 * Whether or not the animation is looped
	 */
	public var looped:Bool;

	/**
	 * An array of dynamic elements that let you add arbritary data to each frame
	 */
	public var framesData(default, null):Array<Dynamic>;

	/**
	 * Animation frameRate - the speed in frames per second that the animation should play at.
	 */
	public var frameRate(default, set):Float;

	/**
	 * @param	Name		What this animation should be called (e.g. "run")
	 * @param	Frames		An array of numbers indicating what frames to play in what order (e.g. 1, 2, 3)
	 * @param	FrameRate	The speed in frames per second that the animation should play at (e.g. 40)
	 * @param	Looped		Whether or not the animation is looped or just plays once
	 * @param	FramesData	An array of dynamic elements that let you add arbritary data to each frame
	 */
	public function new(Name:String, Frames:Array<Int>, FrameRate:Float = 0, Looped:Bool = true, ?FramesData:Array<Dynamic>)
	{
		name = Name;
		frameRate = FrameRate;
		frames = Frames;
		looped = Looped;
		framesData = FramesData;
	}

	/**
	 * Clean up memory.
	 */
	public function destroy():Void
	{
		frames = null;
		framesData = null;
	}

	function set_frameRate(value:Float):Float
	{
		delay = 0;
		frameRate = value;
		if (value > 0)
		{
			delay = 1.0 / value;
		}
		return value;
	}
}
