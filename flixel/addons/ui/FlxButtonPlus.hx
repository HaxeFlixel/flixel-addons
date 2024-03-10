package flixel.addons.ui;

#if FLX_MOUSE
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.Lib;
import flixel.addons.display.FlxExtendedMouseSprite;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.*;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxGradient;
import flixel.math.FlxMath;

// TODO: Port to use touch as well

/**
 * A simple button class that calls a function when clicked by the mouse.
 *
 * @link http://www.photonstorm.com
 * @author Richard Davey / Photon Storm
 */
class FlxButtonPlus extends #if (flixel < "5.7.0") FlxSpriteGroup #else FlxSpriteContainer #end
{
	public static inline var NORMAL:Int = 0;
	public static inline var HIGHLIGHT:Int = 1;
	public static inline var PRESSED:Int = 2;

	/**
	 * The 1px thick border color that is drawn around this button
	 */
	public var borderColor:Int = FlxColor.WHITE;

	/**
	 * The color gradient of the button in its in-active (not hovered over) state
	 */
	public var offColor:Array<Int>;

	/**
	 * The color gradient of the button in its hovered state
	 */
	public var onColor:Array<Int>;

	/**
	 * This function is called when the button is clicked.
	 */
	public var onClickCallback:Void->Void;

	/**
	 * This function is called when the button is hovered over
	 */
	public var enterCallback:Void->Void;

	/**
	 * This function is called when the mouse leaves a hovered button (but didn't click)
	 */
	public var leaveCallback:Void->Void;

	public var buttonNormal(default, set):FlxExtendedMouseSprite;
	public var buttonHighlight(default, set):FlxExtendedMouseSprite;

	public var textNormal(default, set):FlxText;
	public var textHighlight(default, set):FlxText;

	/**
	 * If this button has text, set this to change the value
	 */
	public var text(never, set):String;

	/**
	 * Shows the current state of the button.
	 */
	var _status:Int = NORMAL;

	/**
	 * Whether or not the button has initialized itself yet.
	 */
	var _initialized:Bool = false;

	/**
	 * Creates a new FlxButton object with a gray background
	 * and a callback function on the UI thread.
	 *
	 * @param	X			The X position of the button.
	 * @param	Y			The Y position of the button.
	 * @param	Callback	The function to call whenever the button is clicked.
	 * @param	Label		Text to display on the button
	 * @param	Width		The width of the button.
	 * @param	Height		The height of the button.
	 */
	public function new(X:Float = 0, Y:Float = 0, ?Callback:Void->Void, ?Label:String, Width:Int = 100, Height:Int = 20)
	{
		offColor = [0xff008000, 0xff00ff00];
		onColor = [0xff800000, 0xffff0000];

		super(4);

		x = X;
		y = Y;
		onClickCallback = Callback;

		buttonNormal = new FlxExtendedMouseSprite();

		#if flash
		buttonNormal.makeGraphic(Width, Height, borderColor);
		#else
		buttonNormal.setSize(Width, Height);
		#end

		updateInactiveButtonColors(offColor);

		buttonNormal.solid = false;
		buttonNormal.scrollFactor.set();

		buttonHighlight = new FlxExtendedMouseSprite();

		#if flash
		buttonHighlight.makeGraphic(Width, Height, borderColor);
		#else
		buttonHighlight.setSize(Width, Height);
		#end

		updateActiveButtonColors(onColor);

		buttonHighlight.solid = false;
		buttonHighlight.visible = false;
		buttonHighlight.scrollFactor.set();

		add(buttonNormal);
		add(buttonHighlight);

		if (Label != null)
		{
			textNormal = new FlxText(0, 3, Width, Label);
			textNormal.setFormat(null, 8, 0xffffff, "center");

			textHighlight = new FlxText(0, 3, Width, Label);
			textHighlight.setFormat(null, 8, 0xffffff, "center");
			textHighlight.visible = false;

			add(textNormal);
			add(textHighlight);
		}
	}

	/**
	 * If you wish to replace the two buttons (normal and hovered-over) with FlxSprites, then pass them here.
	 * Note: The pixel data is extract from the passed FlxSprites and assigned locally, it doesn't actually use the sprites
	 * or keep a reference to them.
	 *
	 * @param	Normal		The FlxSprite to use when the button is in-active (not hovered over)
	 * @param	Highlight	The FlxSprite to use when the button is hovered-over by the mouse
	 */
	public function loadButtonGraphic(Normal:FlxSprite, Highlight:FlxSprite):Void
	{
		buttonNormal.pixels = Normal.pixels;
		buttonHighlight.pixels = Highlight.pixels;

		if (_status == HIGHLIGHT)
		{
			buttonNormal.visible = false;
		}
		else
		{
			buttonHighlight.visible = false;
		}
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
				Lib.current.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				_initialized = true;
			}
		}

		super.update(elapsed);

		// Basic button logic
		updateButton();
	}

	/**
	 * Basic button update logic
	 */
	function updateButton():Void
	{
		var prevStatus:Int = _status;
		var offAll:Bool = true;

		for (camera in buttonNormal.cameras)
		{
			if (FlxMath.mouseInFlxRect(true, buttonNormal.rect))
			{
				offAll = false;

				if (FlxG.mouse.justPressed)
				{
					_status = PRESSED;
				}

				if (_status == NORMAL)
				{
					_status = HIGHLIGHT;
				}
			}
		}

		if (offAll)
		{
			_status = NORMAL;
		}

		if (_status != prevStatus)
		{
			if (_status == NORMAL)
			{
				buttonHighlight.visible = false;
				buttonNormal.visible = true;

				if (textNormal != null)
				{
					textHighlight.visible = false;
					textNormal.visible = true;
				}

				if (leaveCallback != null)
				{
					leaveCallback();
				}
			}
			else if (_status == HIGHLIGHT)
			{
				buttonNormal.visible = false;
				buttonHighlight.visible = true;

				if (textNormal != null)
				{
					textNormal.visible = false;
					textHighlight.visible = true;
				}

				if (enterCallback != null)
				{
					enterCallback();
				}
			}
		}
	}

	/**
	 * WARNING: This will remove this object entirely. Use kill() if you
	 * want to disable it temporarily only and reset() it later to revive it.
	 * Called by the game state when state is changed (if this object belongs to the state)
	 */
	override public function destroy():Void
	{
		if (FlxG.stage != null)
		{
			Lib.current.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}

		buttonNormal = FlxDestroyUtil.destroy(buttonNormal);
		buttonHighlight = FlxDestroyUtil.destroy(buttonHighlight);
		textNormal = FlxDestroyUtil.destroy(textNormal);
		textHighlight = FlxDestroyUtil.destroy(textHighlight);

		onClickCallback = null;
		enterCallback = null;
		leaveCallback = null;

		super.destroy();
	}

	/**
	 * Internal function for handling the actual callback call (for UI thread dependent calls like FlxStringUtil.openURL()).
	 */
	function onMouseUp(E:MouseEvent):Void
	{
		if (exists && visible && active && (_status == PRESSED) && (onClickCallback != null))
		{
			onClickCallback();
		}
	}

	/**
	 * If you want to change the color of this button in its in-active (not hovered over) state, then pass a new array of color values
	 */
	public function updateInactiveButtonColors(Colors:Array<Int>):Void
	{
		offColor = Colors;

		var w = buttonNormal.width;
		var h = buttonNormal.height;

		#if flash
		buttonNormal.stamp(FlxGradient.createGradientFlxSprite(Std.int(w - 2), Std.int(h - 2), offColor), 1, 1);
		#else
		var colA:Int;
		var colRGB:Int;

		var normalKey:String = "Gradient: " + w + " x " + h + ", colors: [";

		for (col in offColor)
		{
			colA = (col >> 24) & 255;
			colRGB = col & 0x00ffffff;

			normalKey = normalKey + colRGB + "_" + colA + ", ";
		}

		normalKey = normalKey + "]";

		if (FlxG.bitmap.checkCache(normalKey) == false)
		{
			var normalGraphics:FlxGraphic = FlxG.bitmap.create(Std.int(w), Std.int(h), FlxColor.TRANSPARENT, false, normalKey);
			normalGraphics.bitmap.fillRect(new Rectangle(0, 0, w, h), borderColor);
			FlxGradient.overlayGradientOnBitmapData(normalGraphics.bitmap, Std.int(w - 2), Std.int(h - 2), offColor, 1, 1);
		}

		buttonNormal.pixels = FlxG.bitmap.get(normalKey).bitmap;
		#end
	}

	/**
	 * If you want to change the color of this button in its active (hovered over) state, then pass a new array of color values
	 */
	public function updateActiveButtonColors(Colors:Array<Int>):Void
	{
		onColor = Colors;

		var w = buttonHighlight.width;
		var h = buttonHighlight.height;

		#if flash
		buttonHighlight.stamp(FlxGradient.createGradientFlxSprite(Std.int(w - 2), Std.int(h - 2), onColor), 1, 1);
		#else
		var colA:Int;
		var colRGB:Int;

		var highlightKey:String = "Gradient: " + w + " x " + h + ", colors: [";

		for (col in onColor)
		{
			colA = (col >> 24) & 255;
			colRGB = col & 0x00ffffff;

			highlightKey = highlightKey + colRGB + "_" + colA + ", ";
		}

		highlightKey = highlightKey + "]";

		if (FlxG.bitmap.checkCache(highlightKey) == false)
		{
			var highlightGraphics:FlxGraphic = FlxG.bitmap.create(Std.int(w), Std.int(h), FlxColor.TRANSPARENT, false, highlightKey);
			highlightGraphics.bitmap.fillRect(new Rectangle(0, 0, w, h), borderColor);
			FlxGradient.overlayGradientOnBitmapData(highlightGraphics.bitmap, Std.int(w - 2), Std.int(h - 2), onColor, 1, 1);
		}

		buttonHighlight.pixels = FlxG.bitmap.get(highlightKey).bitmap;
		#end
	}

	function set_text(NewText:String):String
	{
		if ((textNormal != null) && (textNormal.text != NewText))
		{
			textNormal.text = NewText;
			textHighlight.text = NewText;
		}

		return NewText;
	}

	inline function set_buttonNormal(Value:FlxExtendedMouseSprite):FlxExtendedMouseSprite
	{
		if (Value == null)
		{
			return buttonNormal = null;
		}
		if (buttonHighlight != buttonNormal)
		{
			FlxDestroyUtil.destroy(buttonNormal);
		}
		replace(buttonNormal, Value);
		if (_status != NORMAL)
		{
			Value.visible = false;
			buttonHighlight.visible = true;
		}
		return buttonNormal = Value;
	}

	inline function set_buttonHighlight(Value:FlxExtendedMouseSprite):FlxExtendedMouseSprite
	{
		if (Value == null)
		{
			return buttonHighlight = null;
		}
		if (buttonHighlight != buttonNormal)
		{
			FlxDestroyUtil.destroy(buttonHighlight);
		}
		if (_status != HIGHLIGHT)
		{
			Value.visible = false;
			buttonNormal.visible = true;
		}
		replace(buttonHighlight, Value);
		return buttonHighlight = Value;
	}

	inline function set_textNormal(Value:FlxText):FlxText
	{
		if (Value == null)
		{
			return textNormal = null;
		}
		if (textNormal != textHighlight)
		{
			FlxDestroyUtil.destroy(textNormal);
		}
		if (_status != NORMAL)
		{
			Value.visible = false;
			textHighlight.visible = true;
		}
		replace(textNormal, Value);
		return textNormal = Value;
	}

	inline function set_textHighlight(Value:FlxText):FlxText
	{
		if (Value == null)
		{
			return textHighlight = null;
		}
		if (textNormal != textHighlight)
		{
			FlxDestroyUtil.destroy(textHighlight);
		}
		if (_status != HIGHLIGHT)
		{
			Value.visible = false;
			textNormal.visible = true;
		}
		replace(textHighlight, Value);
		return textHighlight = Value;
	}
}
#end
