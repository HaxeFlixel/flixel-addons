package flixel.addons.transition;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxTimer;
import openfl.display.BitmapData;

#if html5
@:keep @:bitmap("assets/images/transitions/circle.png")
private class RawGraphicTransTileCircle extends BitmapData {}
class GraphicTransTileCircle extends RawGraphicTransTileCircle
{
	static inline var WIDTH = 544;
	static inline var HEIGHT = 32;

	public function new(?onLoad)
	{
		super(WIDTH, HEIGHT, true, 0xFFffffff, onLoad);
		// Set properties because `@:bitmap` constructors ignore width/height
		this.width = WIDTH;
		this.height = HEIGHT;
	}
}

@:keep @:bitmap("assets/images/transitions/diamond.png")
private class RawGraphicTransTileDiamond extends BitmapData {}
class GraphicTransTileDiamond extends RawGraphicTransTileDiamond
{
	static inline var WIDTH = 544;
	static inline var HEIGHT = 32;

	public function new(?onLoad)
	{
		super(WIDTH, HEIGHT, true, 0xFFffffff, onLoad);
		// Set properties because `@:bitmap` constructors ignore width/height
		this.width = WIDTH;
		this.height = HEIGHT;
	}
}

@:keep @:bitmap("assets/images/transitions/square.png")
class RawGraphicTransTileSquare extends BitmapData {}
class GraphicTransTileSquare extends RawGraphicTransTileSquare
{
	static inline var WIDTH = 544;
	static inline var HEIGHT = 32;

	public function new(?onLoad)
	{
		super(WIDTH, HEIGHT, true, 0xFFffffff, onLoad);
		// Set properties because `@:bitmap` constructors ignore width/height
		this.width = WIDTH;
		this.height = HEIGHT;
	}
}
#else
@:keep @:bitmap("assets/images/transitions/circle.png")
class GraphicTransTileCircle extends BitmapData {}

@:keep @:bitmap("assets/images/transitions/diamond.png")
class GraphicTransTileDiamond extends BitmapData {}

@:keep @:bitmap("assets/images/transitions/square.png")
class GraphicTransTileSquare extends BitmapData {}
#end

/**
 *
 * @author Tim Hely
 */
class FlxTransitionSprite extends FlxSprite
{
	var _delay:Float;
	var _count:Float;
	var _starting:Bool = true;
	var _finished:Bool = false;

	public var status:TransitionStatus = IN;

	var _newStatus:TransitionStatus = NULL;

	public function new(X:Float = 0, Y:Float = 0, Delay:Float, Graphic:FlxGraphicAsset = null, GraphicWidth:Int = 32, GraphicHeight:Int = 32,
			FrameRate:Int = 40)
	{
		super(X, Y);
		if (Graphic == null)
		{
			Graphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
			GraphicWidth = 32;
			GraphicHeight = 32;
		}
		_delay = Delay;
		loadGraphic(Graphic, true, GraphicWidth, GraphicHeight);
		
		if (graphic == null)
			return;

		graphic.persist = true;
		graphic.destroyOnNoUse = false;

		var inArray:Array<Int> = [];
		var outArray:Array<Int> = [];
		for (i in 1...(numFrames - 1))
		{
			inArray.push(i);
		}
		outArray = inArray.copy();
		outArray.reverse();

		animation.add("empty", [0], 0, false);
		animation.add("in", inArray, FrameRate, false);
		animation.add("full", [numFrames - 1], 0, false);
		animation.add("out", outArray, FrameRate, false);

		setStatus(FULL);
	}

	public function start(NewStatus:TransitionStatus):Void
	{
		_starting = true;
		_finished = false;
		_count = 0;
		_newStatus = NewStatus;
	}

	function startStatus(NewStatus:TransitionStatus):Void
	{
		setStatus(NewStatus);
	}

	public function setStatus(Status:TransitionStatus):Void
	{
		var anim:String = switch (Status)
		{
			case IN: "in";
			case OUT: "out";
			case EMPTY, NULL: "empty";
			case FULL: "full";
		}

		animation.play(anim);
		#if (flixel < version("5.9.0"))
		animation.finishCallback = onFinishAnim;
		#else
		if (!animation.onFinish.has(onFinishAnim))
			animation.onFinish.add(onFinishAnim);
		#end
		status = Status;
	}

	function onFinishAnim(str:String):Void
	{
		if (!_finished)
		{
			_finished = true;
			switch (status)
			{
				case IN:
					setStatus(FULL);
				case OUT:
					setStatus(EMPTY);
				default:
			}
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (_starting)
		{
			_count += elapsed;
			if (_count >= _delay)
			{
				onTime();
			}
		}
	}

	function onTime():Void
	{
		_starting = false;
		_count = 0;
		setStatus(_newStatus);
		_newStatus = NULL;
	}
}

enum abstract TransitionStatus(Int)
{
	var IN = 0;
	var OUT = 1;
	var EMPTY = 2;
	var FULL = 3;
	var NULL = -1;
}
