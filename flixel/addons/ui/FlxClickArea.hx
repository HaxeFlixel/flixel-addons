package flixel.addons.ui;

import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.Lib;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.ui.FlxButton;
import flixel.math.FlxPoint;

/**
 * Trimmed-down button, invisible click area, only responds to onUP
 */
class FlxClickArea extends FlxObject
{
	/**
	 * Shows the current state of the button, either NORMAL,
	 * HIGHLIGHT or PRESSED
	 */
	public var status:Int;

	/**
	 * This function is called when the button is released.
	 * We recommend assigning your main button behavior to this function
	 * via the FlxClickArea constructor.
	 */
	public var onUp:Void->Void;

	/**
	 * Tracks whether or not the button is currently pressed.
	 */
	var _pressed:Bool;

	/**
	 * Whether or not the button has initialized itself yet.
	 */
	var _initialized:Bool;

	/**
	 * Creates a new FlxClickArea object
	 * and a callback function on the UI thread.
	 *
	 * @param	X			The X position of the button.
	 * @param	Y			The Y position of the button.
	 * @param   Width		Width of the area
	 * @param 	Height		Height of the area
	 * @param	OnUp		The function to call whenever the button is clicked.
	 */
	public function new(X:Float = 0, Y:Float = 0, Width:Float = 80, Height:Float = 20, ?OnUp:Void->Void)
	{
		super(X, Y);

		width = Width;
		height = Height;

		onUp = OnUp;

		status = FlxButton.NORMAL;
		_pressed = false;
		_initialized = false;

		scrollFactor.x = 0;
		scrollFactor.y = 0;
	}

	/**
	 * Called by the game state when state is changed (if this object belongs to the state)
	 */
	override public function destroy():Void
	{
		if (FlxG.stage != null)
		{
			#if FLX_MOUSE
			Lib.current.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			#end

			#if FLX_TOUCH
			Lib.current.stage.removeEventListener(TouchEvent.TOUCH_END, onMouseUp);
			#end
		}

		onUp = null;

		super.destroy();
	}

	/**
	 * Called by the game loop automatically, handles mouseover and click detection.
	 */
	override public function update(elapsed:Float):Void
	{
		if (!_initialized)
		{
			if (FlxG.stage != null)
			{
				#if FLX_MOUSE
				Lib.current.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				#end
				#if FLX_TOUCH
				Lib.current.stage.addEventListener(TouchEvent.TOUCH_END, onMouseUp);
				#end
				_initialized = true;
			}
		}
		super.update(elapsed);

		updateButton(); // Basic button logic
	}

	/**
	 * Basic button update logic
	 */
	function updateButton():Void
	{
		// Figure out if the button is highlighted or pressed or what
		var continueUpdate = false;

		#if FLX_MOUSE
		continueUpdate = true;
		#end

		#if FLX_TOUCH
		continueUpdate = true;
		#end

		if (continueUpdate)
		{
			var offAll:Bool = true;
			for (camera in cameras)
			{
				#if FLX_MOUSE
				FlxG.mouse.getWorldPosition(camera, _point);
				offAll = (updateButtonStatus(_point, camera, FlxG.mouse.justPressed) == false) ? false : offAll;
				#end
				#if FLX_TOUCH
				for (touch in FlxG.touches.list)
				{
					touch.getWorldPosition(camera, _point);
					offAll = (updateButtonStatus(_point, camera, touch.justPressed) == false) ? false : offAll;
				}
				#end

				if (!offAll)
				{
					break;
				}
			}
			if (offAll)
			{
				status = FlxButton.NORMAL;
			}
		}
	}

	/**
	 * Updates status and handles the onDown and onOver logic (callback function).
	 */
	function updateButtonStatus(Point:FlxPoint, Camera:FlxCamera, JustPressed:Bool):Bool
	{
		var offAll:Bool = true;

		if (overlapsPoint(Point, true, Camera))
		{
			offAll = false;

			if (JustPressed)
			{
				status = FlxButton.PRESSED;
			}
			if (status == FlxButton.NORMAL)
			{
				status = FlxButton.HIGHLIGHT;
			}
		}

		return offAll;
	}

	/**
	 * Internal function for handling the actual callback call (for UI thread dependent calls like FlxStringUtil.openURL()).
	 */
	function onMouseUp(event:Event):Void
	{
		if (!exists || !visible || !active || (status != FlxButton.PRESSED))
		{
			return;
		}
		if (onUp != null)
		{
			onUp();
		}
		status = FlxButton.NORMAL;
	}
}
