package flixel.addons.text;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.system.FlxSound;
import flixel.math.FlxRandom;

#if !bitfive
import flash.media.Sound;

#if !flash
@:sound("assets/sounds/type.ogg")
class TypeSound extends Sound { }
#else
// Flash uses a WAV instead of MP3 because the sound is so short that MP3's encoding mutes most of it
@:sound("assets/sounds/type.wav")
class TypeSound extends Sound { }
#end
#end

/**
 * This is loosely based on the TypeText class by Noel Berry, who wrote it for his Ludum Dare 22 game - Abandoned
 * http://www.ludumdare.com/compo/ludum-dare-22/?action=preview&uid=1527
 * @author Noel Berry
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
	 */
	public var paused:Bool = false;
	/**
	 * The sounds that are played when letters are added; optional.
	 */
	public var sounds:Array<FlxSound>;
	/**
	 * Whether or not to use the default typing sound. Not available for openfl-bitfive.
	 */
	public var useDefaultSound:Bool = false;
	/**
	 * An array of keys as string values (e.g. "SPACE", "L") that will advance the text.
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
	private var _finalText:String = "";
	/**
	 * This is incremented every frame by elapsed, and when greater than delay, adds the next letter.
	 */
	private var _timer:Float = 0.0;
	/**
	 * A timer that is used while waiting between typing and erasing.
	 */
	private var _waitTimer:Float = 0.0;
	/**
	 * Internal tracker for current string length, not counting the prefix.
	 */
	private var _length:Int = 0;
	/**
	 * Whether or not to type the text. Set to true by start() and false by pause().
	 */
	private var _typing:Bool = false;
	/**
	 * Whether or not to erase the text. Set to true by erase() and false by pause().
	 */
	private var _erasing:Bool = false;
	/**
	 * Whether or not we're waiting between the type and erase phases.
	 */
	private var _waiting:Bool = false;
	/**
	 * Internal tracker for cursor blink time.
	 */
	private var _cursorTimer:Float = 0.0;
	/**
	 * Whether or not to add a "natural" uneven rhythm to the typing speed.
	 */
	private var _typingVariation:Bool = false;
	/**
	 * How much to vary typing speed, as a percent. So, at 0.5, each letter will be "typed" up to 50% sooner or later than the delay variable is set.
	 */
	private var _typeVarPercent:Float = 0.5;
	/**
	 * Helper string to reduce garbage generation.
	 */
	private static var helperString:String = "";
	/**
	 * Internal reference to the default sound object.
	 */
	private var _sound:FlxSound;
	
	/**
	 * Create a FlxTypeText object, which is very similar to FlxText except that the text is initially hidden and can be
	 * animated one character at a time by calling start().
	 * 
	 * @param	X				The X position for this object.
	 * @param	Y				The Y position for this object.
	 * @param	Width			The width of this object. Text wraps automatically.
	 * @param	Text			The text that will ultimately be displayed.
	 * @param	Size			The size of the text.
	 * @param	EmbeddedFont	Whether this text field uses embedded fonts or not.
	 */
	public function new(X:Float, Y:Float, Width:Int, Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
	{
		super(X, Y, Width, "", Size, EmbeddedFont);
		_finalText = Text;
	}
	
	/**
	 * Start the text animation.
	 * 
	 * @param   Delay          Optionally, set the delay between characters. Can also be set separately.
	 * @param   ForceRestart   Whether or not to start this animation over if currently animating; false by default.
	 * @param   AutoErase      Whether or not to begin the erase animation when the typing animation is complete.
	 *                         Can also be set separately.
	 * @param   SkipKeys       An array of keys as string values (e.g. "SPACE", "L") that will advance the text.
	 *                         Can also be set separately.
	 * @param   Callback       An optional callback function, to be called when the typing animation is complete.
	 */
	public function start(?Delay:Float, ForceRestart:Bool = false, AutoErase:Bool = false, ?SkipKeys:Array<FlxKey>, ?Callback:Void->Void):Void
	{
		if (Delay != null)
		{
			delay = Delay;
		}
		
		_typing = true;
		_erasing = false;
		paused = false;
		_waiting = false;
		
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
		
		#if !bitfive
		if (useDefaultSound)
		{
			loadDefaultSound();
		}
		#end
	}
	
	/**
	 * Internal function that replace last space in a line for a line break.
	 * To prevent a word start typing in a line and jump to next.
	 */
	private function insertBreakLines() 
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
	 * @param	SkipKeys		An array of keys as string values (e.g. "SPACE", "L") that will advance the text. Can also be set separately.
	 * @param	Callback		An optional callback function, to be called when the erasing animation is complete.
	 * @param	Params			Optional parameters to pass to the callback function.
	 */
	public function erase(?Delay:Float, ForceRestart:Bool = false, ?SkipKeys:Array<FlxKey>, ?Callback:Void->Void):Void
	{
		_erasing = true;
		_typing = false;
		paused = false;
		_waiting = false;
		
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
		
		if (Callback != null)
		{
			eraseCallback = Callback;
		}
		
		#if !bitfive
		if (useDefaultSound)
		{
			loadDefaultSound();
		}
		#end
	}
	
	/**
	 * Reset the text with a new text string. Automatically cancels typing, and erasing.
	 * 
	 * @param	Text	The text that will ultimately be displayed.
	 */
	public function resetText(Text:String):Void
	{
		text = "";
		_finalText = Text;
		_typing = false;
		_erasing = false;
		paused = false;
		_waiting = false;
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
	private function onComplete():Void
	{
		_timer = 0;
		_typing = false;
		
		if (completeCallback != null)
		{
			completeCallback();
		}
		
		if (autoErase && waitTime <= 0)
		{
			_erasing = true;
		}
		else if (autoErase)
		{
			_waitTimer = waitTime;
			_waiting = true;
		}
	}
	
	private function onErased():Void
	{
		_timer = 0;
		_erasing = false;
		
		if (eraseCallback != null)
		{
			eraseCallback();
		}
	}
	
	override public function update(elapsed:Float):Void
	{
		// If the skip key was pressed, complete the animation.
		#if !FLX_NO_KEYBOARD
		if (skipKeys != null && skipKeys.length > 0 && FlxG.keys.anyJustPressed(skipKeys))
		{
			skip();
		}
		#end
		
		if (_waiting && !paused)
		{
			_waitTimer -= elapsed;
			
			if (_waitTimer <= 0)
			{
				_waiting = false;
				_erasing = true;
			}
		}
		
		// So long as we should be animating, increment the timer by time elapsed.
		if (!_waiting && !paused)
		{
			if (_length < _finalText.length && _typing)
			{
				_timer += elapsed;
			}
			
			if (_length > 0 && _erasing)
			{
				_timer += elapsed;
			}
		}
		
		// If the timer value is higher than the rate at which we should be changing letters, increase or decrease desired string length.
		
		if (_typing || _erasing)
		{
			if (_typing && _timer >= delay)
			{
				_length ++;
			}
			
			if (_erasing && _timer >= eraseDelay)
			{
				_length --;
			}
			
			if ((_typing && _timer >= delay) || (_erasing && _timer >= eraseDelay))
			{
				if (_typingVariation)
				{
					if (_typing)
					{
						_timer = FlxG.random.float( -delay * _typeVarPercent / 2, delay * _typeVarPercent / 2);
					}
					else
					{
						_timer = FlxG.random.float( -eraseDelay * _typeVarPercent / 2, eraseDelay * _typeVarPercent / 2);
					}
				}
				else
				{
					_timer = 0;
				}
				
				if (sounds != null && !useDefaultSound)
				{
					for (sound in sounds)
					{
						sound.stop();
					}
					
					FlxG.random.getObject(sounds).play(true);
				}
				else if (useDefaultSound)
				{
					#if !bitfive
					_sound.play(true);
					#end
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
			if (_length >= _finalText.length && _typing && !_waiting && !_erasing)
			{
				onComplete();
			}
			
			// If we're done erasing, call the onErased() function
			if (_length == 0 && _erasing && !_typing && !_waiting)
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
		if (_erasing || _waiting)
		{
			_length = 0;
			_waiting = false;
		}
		else if (_typing)
		{
			_length = _finalText.length;
		}
	}
	
	#if !bitfive
	private function loadDefaultSound():Void
	{
		#if !FLX_NO_SOUND_SYSTEM
		_sound = FlxG.sound.load(new TypeSound());
		#else
		_sound = new FlxSound();
		_sound.loadEmbedded(new TypeSound());
		#end
	}
	#end
}
