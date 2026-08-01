package flixel.addons.text;

// TODO: remove this check when min flixel version is 5.6.0,
// So that FlxAddonDefines will handle this
#if (flixel < version("5.3.0"))
#error "Flixel-Addons is not compatible with flixel versions older than 5.3.0";
#end

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.sound.FlxSound;
import flixel.math.FlxRandom;
import openfl.media.Sound;

#if !flash
@:sound("assets/sounds/type.ogg")
class TypeSound extends Sound {}
#else
// Flash uses a WAV instead of MP3 because the sound is so short that MP3's encoding mutes most of it

@:sound("assets/sounds/type.wav")
class TypeSound extends Sound {}
#end

/**
 * Represents the current animation status of the FlxTypeText.
 */
enum abstract TypeTextStatus(Int) from Int to Int
{
	/** No animation occurring */
	var IDLE = 0;

	/** Actively typing characters */
	var TYPING = 1;

	/** Typing animation paused */
	var PAUSED_TYPING = 2;

	/** Waiting between typing completion and erase start (when autoErase=true) */
	var WAITING = 3;

	/** Waiting animation paused */
	var PAUSED_WAITING = 4;

	/** Actively erasing characters */
	var ERASING = 5;

	/** Erasing animation paused */
	var PAUSED_ERASING = 6;

	var self(get, never):TypeTextStatus;

	inline function get_self():TypeTextStatus
	{
		#if (haxe >= version("4.3.0"))
		return abstract;
		#else
		return cast this;
		#end
	}

	/**
	 * Whether the current status is any paused status
	 */
	public var isPaused(get, never):Bool;

	inline function get_isPaused():Bool
	{
		return self == PAUSED_TYPING
			|| self == PAUSED_WAITING
			|| self == PAUSED_ERASING;
	}

	/**
	 * Whether the current status is actively animating (not paused, not idle)
	 */
	public var isAnimating(get, never):Bool;

	inline function get_isAnimating():Bool
	{
		return self == TYPING
			|| self == WAITING
			|| self == ERASING;
	}

	/**
	 * Whether this is a typing-related status (including paused typing)
	 */
	public var isTyping(get, never):Bool;

	inline function get_isTyping():Bool
	{
		return self == TYPING || self == PAUSED_TYPING;
	}

	/**
	 * Whether this is an erasing-related status (including paused erasing)
	 */
	public var isErasing(get, never):Bool;

	inline function get_isErasing():Bool
	{
		return self == ERASING || self == PAUSED_ERASING;
	}

	/**
	 * Whether this is a waiting-related status (including paused waiting)
	 */
	public var isWaiting(get, never):Bool;

	inline function get_isWaiting():Bool
	{
		return self == WAITING || self == PAUSED_WAITING;
	}

	/**
	 * Get the paused version of the current status, or return unchanged if already paused/idle
	 */
	public inline function toPaused():TypeTextStatus
	{
		return switch self
		{
			case TYPING: PAUSED_TYPING;
			case ERASING: PAUSED_ERASING;
			case WAITING: PAUSED_WAITING;
			case _: self; // Already paused or idle
		}
	}

	/**
	 * Get the active (unpaused) version of the current status, or return unchanged if not paused
	 */
	public inline function toActive():TypeTextStatus
	{
		return switch self
		{
			case PAUSED_TYPING: TYPING;
			case PAUSED_ERASING: ERASING;
			case PAUSED_WAITING: WAITING;
			case _: self; // Not paused
		}
	}

	/**
	 * Convert to integer value
	 */
	public inline function toInt():Int
	{
		return this;
	}

	/**
	 * String representation for debugging
	 */
	public function toString():String
	{
		return switch self
		{
			case IDLE: "IDLE";
			case TYPING: "TYPING";
			case PAUSED_TYPING: "PAUSED_TYPING";
			case WAITING: "WAITING";
			case PAUSED_WAITING: "PAUSED_WAITING";
			case ERASING: "ERASING";
			case PAUSED_ERASING: "PAUSED_ERASING";
		}
	}

	public inline static function fromInt(value:Int):TypeTextStatus
	{
		return cast value;
	}
}

/**
 * This is loosely based on the TypeText class by Noel Berry, who wrote it for his Ludum Dare 22 game - Abandoned
 * http://www.ludumdare.com/compo/ludum-dare-22/?action=preview&uid=1527
 * @author Noel Berry
 * @see [Flixel Demos - FlxTypeText](https://haxeflixel.com/demos/FlxTypeText/)
 */
class FlxTypeText extends FlxText
{
	/**
	 * The delay between each character, in seconds.
	 */
	public var delay:Float = 0.05;

	/**
	 * The delay between each character erasure, in seconds.
	 */
	public var eraseDelay:Float = 0.02;

	/**
	 * Set to true to show a blinking cursor at the end of the text.
	 */
	public var showCursor:Bool = false;

	/**
	 * The character to blink at the end of the text.
	 */
	public var cursorCharacter:String = "|";

	/**
	 * The speed at which the cursor should blink, if shown at all.
	 */
	public var cursorBlinkSpeed:Float = 0.5;

	/**
	 * Text to add at the beginning, without animating.
	 */
	public var prefix:String = "";

	/**
	 * Whether or not to erase this message when it is complete.
	 */
	public var autoErase:Bool = false;

	/**
	 * How long to pause after finishing the text before erasing it. Only used if autoErase is true.
	 */
	public var waitTime:Float = 1.0;

	/**
	 * Whether or not to animate the text. Set to false by start() and erase().
	 * @deprecated Use pause()/resume() methods or check currentStatus directly instead
	 */
	public var paused(get, set):Bool;

	inline function get_paused():Bool
	{
		return _status.isPaused;
	}

	function set_paused(value:Bool):Bool
	{
		_status = value ? _status.toPaused() : _status.toActive();
		return value;
	}

	/**
	 * The current animation status.
	 */
	public var currentStatus(get, never):TypeTextStatus;

	inline function get_currentStatus():TypeTextStatus
		return _status;

	/**
	 * The sounds that are played when letters are added; optional.
	 */
	public var sounds:Array<FlxSound>;

	/**
	 * Whether or not to use the default typing sound.
	 */
	public var useDefaultSound:Bool = false;

	/**
	 * Whether typing sound effects should always be played in their entirety, or if it's ok to restart them on new letters.
	 * For longer typing sounds, setting this to `true` usually makes more sense.
	 * @since 2.4.0
	 */
	public var finishSounds = false;

	/**
	 * An array of keys (e.g. `[FlxKey.SPACE, FlxKey.L]`) that will advance the text.
	 */
	public var skipKeys:Array<FlxKey> = [];

	/**
	 * This function is called when the message is done typing.
	 */
	public var completeCallback:Void->Void;

	/**
	 * This function is called when the message is done erasing, if that is enabled.
	 */
	public var eraseCallback:Void->Void;

	/**
	 * The text that will ultimately be displayed.
	 */
	var _finalText:String = "";

	/**
	 * This is incremented every frame by elapsed, and when greater than delay, adds the next letter.
	 */
	var _timer:Float = 0.0;

	/**
	 * A timer that is used while waiting between typing and erasing.
	 */
	var _waitTimer:Float = 0.0;

	/**
	 * Internal tracker for current string length, not counting the prefix.
	 */
	var _length:Int = 0;

	/**
	 * Current status of the text animation.
	 */
	var _status:TypeTextStatus = IDLE;

	/**
	 * Internal tracker for cursor blink time.
	 */
	var _cursorTimer:Float = 0.0;

	/**
	 * Whether or not to add a "natural" uneven rhythm to the typing speed.
	 */
	var _typingVariation:Bool = false;

	/**
	 * How much to vary typing speed, as a percent. So, at 0.5, each letter will be "typed" up to 50% sooner or later than the delay variable is set.
	 */
	var _typeVarPercent:Float = 0.5;

	/**
	 * Helper string to reduce garbage generation.
	 */
	static var helperString:String = "";

	/**
	 * Internal reference to the default sound object.
	 */
	var _sound:FlxSound;

	/**
	 * Create a FlxTypeText object, which is very similar to FlxText except that the text is initially hidden and can be
	 * animated one character at a time by calling start().
	 *
	 * @param	x				The X position for this object.
	 * @param	y				The Y position for this object.
	 * @param	width			The width of this object. Text wraps automatically.
	 * @param	text			The text that will ultimately be displayed.
	 * @param	size			The size of the text.
	 * @param	embeddedFont	Whether this text field uses embedded fonts or not.
	 */
	public function new(x:Float = 0, y:Float = 0, width:Int = 0, text:String = "", size:Int = 8, embeddedFont:Bool = true)
	{
		super(x, y, width, "", size, embeddedFont);
		_finalText = text;
	}

	/**
	 * Start the text animation.
	 *
	 * @param   Delay          Optionally, set the delay between characters. Can also be set separately.
	 * @param   ForceRestart   Whether or not to start this animation over if currently animating; false by default.
	 * @param   AutoErase      Whether or not to begin the erase animation when the typing animation is complete.
	 *                         Can also be set separately.
	 * @param   SkipKeys       An array of keys as string values (e.g. `[FlxKey.SPACE, FlxKey.L]`) that will advance the text.
	 *                         Can also be set separately.
	 * @param   Callback       An optional callback function, to be called when the typing animation is complete.
	 */
	public function start(?Delay:Float, ForceRestart:Bool = false, AutoErase:Bool = false, ?SkipKeys:Array<FlxKey>, ?Callback:Void->Void):Void
	{
		if (Delay != null)
		{
			delay = Delay;
		}

		_status = TYPING;

		if (ForceRestart)
		{
			text = "";
			_length = 0;
		}

		autoErase = AutoErase;

		if (SkipKeys != null)
		{
			skipKeys = SkipKeys;
		}

		if (Callback != null)
		{
			completeCallback = Callback;
		}

		insertBreakLines();

		if (useDefaultSound)
		{
			loadDefaultSound();
		}
	}

	override public function applyMarkup(input:String, rules:Array<FlxTextFormatMarkerPair>):FlxText
	{
		super.applyMarkup(input, rules);
		resetText(text); // Stops applyMarkup from misaligning the colored section of text.
		return this;
	}

	/**
	 * Internal function that replace last space in a line for a line break.
	 * To prevent a word start typing in a line and jump to next.
	 */
	function insertBreakLines()
	{
		var saveText = text;

		var last = _finalText.length;
		var n0:Int = 0;
		var n1:Int = 0;

		while (true)
		{
			last = _finalText.substr(0, last).lastIndexOf(" ");

			if (last <= 0)
				break;

			text = prefix + _finalText;
			n0 = textField.numLines;

			var nextText = _finalText.substr(0, last) + "\n" + _finalText.substr(last + 1, _finalText.length);

			text = prefix + nextText;
			n1 = textField.numLines;

			if (n0 == n1)
			{
				_finalText = nextText;
			}
		}

		text = saveText;
	}

	/**
	 * Begin an animated erase of this text.
	 *
	 * @param	Delay			Optionally, set the delay between characters. Can also be set separately.
	 * @param	ForceRestart	Whether or not to start this animation over if currently animating; false by default.
	 * @param	SkipKeys		An array of keys as string values (e.g. `[FlxKey.SPACE, FlxKey.L]`) that will advance the text. Can also be set separately.
	 * @param	Callback		An optional callback function, to be called when the erasing animation is complete.
	 */
	public function erase(?Delay:Float, ForceRestart:Bool = false, ?SkipKeys:Array<FlxKey>, ?Callback:Void->Void):Void
	{
		_status = ERASING;

		if (Delay != null)
		{
			eraseDelay = Delay;
		}

		if (ForceRestart)
		{
			_length = _finalText.length;
			text = _finalText;
		}

		if (SkipKeys != null)
		{
			skipKeys = SkipKeys;
		}

		eraseCallback = Callback;

		if (useDefaultSound)
		{
			loadDefaultSound();
		}
	}

	/**
	 * Reset the text with a new text string. Automatically cancels typing, and erasing.
	 *
	 * @param	Text	The text that will ultimately be displayed.
	 */
	public function resetText(Text:String):Void
	{
		text = prefix;
		_finalText = Text;
		_status = IDLE;
		_length = 0;
	}

	/**
	 * If called with On set to true, a random variation will be added to the rate of typing.
	 * Especially with sound enabled, this can give a more "natural" feel to the typing.
	 * Much more noticable with longer text delays.
	 *
	 * @param	Amount		How much variation to add, as a percentage of delay (0.5 = 50% is the maximum amount that will be added or subtracted from the delay variable). Only valid if >0 and <1.
	 * @param	On			Whether or not to add the random variation. True by default.
	 */
	public function setTypingVariation(Amount:Float = 0.5, On:Bool = true):Void
	{
		_typingVariation = On;
		_typeVarPercent = FlxMath.bound(Amount, 0, 1);
	}

	/**
	 * Internal function that is called when typing is complete.
	 */
	function onComplete():Void
	{
		_timer = 0;

		if (useDefaultSound)
		{
			_sound.stop();
		}
		else if (sounds != null)
		{
			for (sound in sounds)
			{
				sound.stop();
			}
		}

		if (completeCallback != null)
		{
			completeCallback();
		}

		if (autoErase && waitTime <= 0)
		{
			_status = ERASING;
		}
		else if (autoErase)
		{
			_waitTimer = waitTime;
			_status = WAITING;
		}
		else
		{
			_status = IDLE;
		}
	}

	function onErased():Void
	{
		_timer = 0;
		_status = IDLE;

		if (eraseCallback != null)
		{
			eraseCallback();
		}
	}

	override public function update(elapsed:Float):Void
	{
		// If the skip key was pressed, complete the animation.
		#if FLX_KEYBOARD
		if (skipKeys != null && skipKeys.length > 0 && FlxG.keys.anyJustPressed(skipKeys))
		{
			skip();
		}
		#end

		if (_status == WAITING)
		{
			_waitTimer -= elapsed;

			if (_waitTimer <= 0)
			{
				_status = ERASING;
			}
		}

		// So long as we should be animating, increment the timer by time elapsed.
		if (_status == TYPING || _status == ERASING)
		{
			if (_length < _finalText.length && _status == TYPING)
			{
				_timer += elapsed;
			}

			if (_length > 0 && _status == ERASING)
			{
				_timer += elapsed;
			}
		}

		// If the timer value is higher than the rate at which we should be changing letters, increase or decrease desired string length.

		if (_status == TYPING || _status == ERASING)
		{
			if (_status == TYPING && _timer >= delay)
			{
				_length += Std.int(_timer / delay);
				if (_length > _finalText.length)
					_length = _finalText.length;
			}

			if (_status == ERASING && _timer >= eraseDelay)
			{
				_length -= Std.int(_timer / eraseDelay);
				if (_length < 0)
					_length = 0;
			}

			if ((_status == TYPING && _timer >= delay) || (_status == ERASING && _timer >= eraseDelay))
			{
				if (_typingVariation)
				{
					if (_status == TYPING)
					{
						_timer = FlxG.random.float(-delay * _typeVarPercent / 2, delay * _typeVarPercent / 2);
					}
					else
					{
						_timer = FlxG.random.float(-eraseDelay * _typeVarPercent / 2, eraseDelay * _typeVarPercent / 2);
					}
				}
				else
				{
					_timer %= delay;
				}

				if (sounds != null && !useDefaultSound)
				{
					if (!finishSounds)
					{
						for (sound in sounds)
						{
							sound.stop();
						}
					}

					FlxG.random.getObject(sounds).play(!finishSounds);
				}
				else if (useDefaultSound)
				{
					_sound.play(!finishSounds);
				}
			}
		}

		// Update the helper string with what could potentially be the new text.
		helperString = prefix + _finalText.substr(0, _length);

		// Append the cursor if needed.
		if (showCursor)
		{
			_cursorTimer += elapsed;

			// Prevent word wrapping because of cursor
			var isBreakLine = (prefix + _finalText).charAt(helperString.length) == "\n";

			if (_cursorTimer > cursorBlinkSpeed / 2 && !isBreakLine)
			{
				helperString += cursorCharacter.charAt(0);
			}

			if (_cursorTimer > cursorBlinkSpeed)
			{
				_cursorTimer = 0;
			}
		}

		// If the text changed, update it.
		if (helperString != text)
		{
			text = helperString;

			// If we're done typing, call the onComplete() function
			if (_length >= _finalText.length && _status == TYPING)
			{
				onComplete();
			}

			// If we're done erasing, call the onErased() function
			if (_length == 0 && _status == ERASING)
			{
				onErased();
			}
		}

		super.update(elapsed);
	}

	/**
	 * Immediately finishes the animation. Called if any of the skipKeys is pressed.
	 * Handy for custom skipping behaviour (for example with different inputs like mouse or gamepad).
	 */
	public function skip():Void
	{
		switch (_status)
		{
			case ERASING | PAUSED_ERASING | WAITING | PAUSED_WAITING:
				_length = 0;
				_status = IDLE;

			case TYPING | PAUSED_TYPING:
				_length = _finalText.length;
				// Will trigger onComplete() in update(), which handles status transition

			default:
				// Already idle, do nothing
		}
	}

	/**
	 * Pause the current animation.
	 */
	public function pause():Void
	{
		_status = _status.toPaused();
	}

	/**
	 * Resume the current animation if paused.
	 */
	public function resume():Void
	{
		_status = _status.toActive();
	}

	/**
	 * Stop all animation and return to idle status.
	 * Unlike resetText(), this preserves the current text display.
	 */
	public function stop():Void
	{
		_status = IDLE;
		_timer = 0;
		_waitTimer = 0;
	}

	function loadDefaultSound():Void
	{
		#if FLX_SOUND_SYSTEM
			#if (flixel < version("6.2.0"))
			_sound = FlxG.sound.load(new TypeSound());
			#else
			_sound = FlxG.sound.create(new TypeSound());
			#end
		#else
			_sound = new FlxSound();
			#if (flixel < version("6.2.0"))
			_sound.loadEmbedded(new TypeSound());
			#else
			_sound.load(new TypeSound());
			#end
		#end
	}
}
