package flixel.addons.system;

import flixel.system.FlxAnim;

class FlxAnimExt extends FlxAnim
{
	/**
	 * An array of dynamic elements that let you add arbritary data to each frame
	 */
	public var framesData(default, null):Array<Dynamic>;
	
	/**
	 * Constructor
	 * @param	Name		What this animation should be called (e.g. "run")
	 * @param	Frames		An array of numbers indicating what frames to play in what order (e.g. 1, 2, 3)
	 * @param	FrameRate	The speed in frames per second that the animation should play at (e.g. 40)
	 * @param	Looped		Whether or not the animation is looped or just plays once
	 * @param	FramesData	An array of dynamic elements that let you add arbritary data to each frame
	 */
	public function new(Name:String, Frames:Array<Int>, FrameRate:Float = 0, Looped:Bool = true, ?FramesData:Array<Dynamic>)
	{
		super(Name, Frames, FrameRate, Looped);
		
		framesData = FramesData;
	}
}