package flixel.addons.text;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.system.FlxSound;
import flixel.util.FlxRandom;

/**
 * This is loosely based on the TypeText class by Noel Berry, who wrote it for his Ludum Dare 22 game - Abandoned
 * http://www.ludumdare.com/compo/ludum-dare-22/?action=preview&uid=1527
 * @author Noel Berry
 */

class FlxTypeText extends FlxText
{
	
	/**
	 * The speed of this text, in letters per second.
	 */
	public var speed:Float = 1.0;
	
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
	public var eraseDelay:Float = 1.0;
	
	/**
	 * The text that will ultimately be displayed.
	 */
	private var _finalText:String;
	
	/**
	 * This function is called when the message is done typing.
	 */
	private var _onComplete:Dynamic;
	
	/**
	 * This function is called when the message is done erasing, if that is enabled.
	 */
	private var _onErase:Dynamic;
	
	/**
	 * This is incremented every frame by FlxG.elapsed, and when greater than _speed, adds the next letter.
	 */
	private var _timer:Float = 0.0;
	
	/**
	 * A timer that is used while waiting between typing and erasing.
	 */
	private var _waitTimer:Float = 0.0;
	
	/**
	 * Internal tracker for current string length, not counting the prefix.
	 */
	private var _length:Int;
	
	/**
	 * Whether or not to type the text. Set to true by start() and false by pause().
	 */
	private var _typing:Bool;
	
	/**
	 * Whether or not to erase the text. Set to true by erase() and false by pause().
	 */
	private var _erasing:Bool;
	
	/**
	 * Whether or not we're waiting between the type and erase phases.
	 */
	private var _waiting:Bool;
	
	/**
	 * Whether or not to change the text. Set to false by start() and erase() and true by pause().
	 */
	private var _paused:Bool;
	
	/**
	 * Key(s) that will advance the text when pressed.
	 */
	private var _skipKeys:Array<String>;
	
	/**
	 * The sound that is played when letters are added; optional.
	 */
	private var _sound:FlxSound;
	
	/**
	 * Internal tracker for cursor blink time.
	 */
	private var _cursorTimer:Float = 0.0;
	
	/**
	 * Whether or not to add a "natural" uneven rhythm to the typing speed
	 */
	private var _typingVariation:Bool = false;
	
	/**
	 * How much to vary typing speed, as a percent. So, at 0.5, each letter will be "typed" up to 50% sooner or later than the speed variable is set.
	 */
	private var _typeVarPercent:Float = 0.5;
	
	/**
	 * Helper string to reduce garbage generation.
	 */
	static private var helperString:String = "";
	
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
	public function new( X:Float, Y:Float, Width:Int, Text:String, Size:Int = 8, EmbeddedFont:Bool = true )
	{
		super(X, Y, Width, "", Size, EmbeddedFont);
		_finalText = Text;
	}
	
	/**
	 * Set a function to be called when typing the message is complete.
	 * 
	 * @param	OnCompleteCallback	The function to call.
	 */
	public function setCompleteCallback( OnCompleteCallback:Dynamic ):Void
	{
		_onComplete = OnCompleteCallback;
	}
	
	/**
	 * Set a function to be called when erasing is complete.
	 * Make sure to set erase = true or else this will never be called!
	 * 
	 * @param	OnEraseCallback		The function to call.
	 */
	public function setEraseCallback( OnEraseCallback:Dynamic ):Void
	{
		_onErase = OnEraseCallback;
	}
	
	/**
	 * Start the text animation.
	 * 
	 * @param	ForceRestart	Whether or not to restart the animation if it's already going.
	 * @param	Speed			Optionally, you can pass a variable here to set the speed instead of setting speed separately.
	 */
	public function start( ForceRestart:Bool = false, ?Speed:Float ):Void
	{
		if ( Speed != null )
		{
			speed = Speed;
		}
		
		_typing = true;
		_erasing = false;
		_paused = false;
		_waiting = false;
		
		if ( ForceRestart )
		{
			text = "";
			_length = 0;
		}
	}
	
	/**
	 * Pause the text animation.
	 */
	public function pause():Void
	{
		_paused = true;
	}
	
	/**
	 * Resume the text animation, if paused.
	 */
	public function resume():Void
	{
		_paused = false;
	}
	
	/**
	 * Begin an animated erase of this text.
	 */
	public function erase():Void
	{
		_erasing = true;
		_typing = false;
		_paused = false;
		_waiting = false;
	}
	
	/**
	 * Reset the text with a new text string. Automatically cancels typing, and erasing.
	 * 
	 * @param	Text	The text that will ultimately be displayed.
	 */
	public function resetText( Text:String ):Void
	{
		text = "";
		_finalText = Text;
		_typing = false;
		_erasing = false;
		_paused = false;
		_waiting = false;
	}
	
	/**
	 * Define the keys that can be used to advance text.
	 * 
	 * @param	Keys	An array of keys as string values (e.g. "SPACE", "L") that will advance the text.
	 */
	public function setSkipKeys( Keys:Array<String> ):Void
	{
		_skipKeys = Keys;
	}
	
	/**
	 * Set a sound that will be played each time a letter is added to the text.
	 * 
	 * @param	Sound	A FlxSound object.
	 */
	public function setSound( Sound:FlxSound ):Void
	{
		_sound = Sound;
	}
	
	/**
	 * If called with On set to true, a random variation will be added to the rate of typing.
	 * Especially with sound enabled, this can give a more "natural" feel to the typing.
	 * 
	 * @param	On			Whether or not to add the random variation.
	 * @param	Amount		How much variation to add, as a percentage of speed (0.5 = 50% is the maximum amount that will be added or subtracted from the speed variable). Only valid if >0 and <1.
	 */
	public function setTypingVariation( On:Bool, Amount:Float = 0.5 ):Void
	{
		_typingVariation = On;
		
		if ( Amount > 0 && Amount < 1 )
		{
			_typeVarPercent = Amount;
		}
		else
		{
			_typeVarPercent = 0.5;
		}
	}
	
	/**
	 * Internal function that is called when typing is complete.
	 */
	private function onComplete():Void
	{
		_timer = 0;
		_typing = false;
		
		if ( _onComplete != null )
		{
			Reflect.callMethod( null, _onComplete, null );
		}
		
		if ( autoErase && eraseDelay <= 0 )
		{
			_erasing = true;
		}
		else if ( autoErase )
		{
			_waitTimer = eraseDelay;
			_waiting = true;
		}
	}
	
	private function onErased():Void
	{
		_timer = 0;
		_erasing = false;
		
		if ( _onErase != null )
		{
			Reflect.callMethod( null, _onComplete, null );
		}
	}
	
	override public function update():Void
	{
		// If the skip key was pressed, complete the animation.
		
		#if !FLX_NO_KEYBOARD
		if ( FlxG.keyboard.anyJustPressed( _skipKeys ) )
		{
			if ( _erasing || _waiting )
			{
				_length = 0;
				_waiting = false;
			}
			else if ( _typing )
			{
				_length = _finalText.length;
			}
		}
		#end
		
		if ( _waiting && !_paused )
		{
			_waitTimer -= FlxG.elapsed;
			
			if ( _waitTimer <= 0 )
			{
				_waiting = false;
				_erasing = true;
			}
		}
		
		// So long as we should be animating, increment the timer by time elapsed.
		
		if ( !_waiting && !_paused )
		{
			if ( _length < _finalText.length && _typing )
			{
				_timer += FlxG.elapsed;
			}
			
			if ( _length > 0 && _erasing )
			{
				_timer += FlxG.elapsed;
			}
		}
		
		// If the timer value is higher than the rate at which we should be changing letters, increase or decrease desired string length.
		
		if ( _timer >= speed )
		{
			if ( _typing )
			{
				_length ++;
			}
			else if ( _erasing )
			{
				_length --;
			}
			
			if ( _typingVariation )
			{
				_timer = FlxRandom.floatRanged( -speed * _typeVarPercent / 2, speed * _typeVarPercent / 2 );
			}
			else
			{
				_timer = 0;
			}
			
			if ( _sound != null )
			{
				_sound.play( true );
			}
		}
		
		// Update the helper string with what could potentially be the new text.
		
		helperString = prefix + _finalText.substr( 0, _length );
		
		// Append the cursor if needed.
		
		if ( showCursor )
		{
			_cursorTimer += FlxG.elapsed;
			
			if ( _cursorTimer > cursorBlinkSpeed / 2 )
			{
				helperString += cursorCharacter.charAt( 0 );
			}
			
			if ( _cursorTimer > cursorBlinkSpeed )
			{
				_cursorTimer = 0;
			}
		}
		
		// If the text changed, update it.
		
		if ( helperString != text )
		{
			text = helperString;
			
			// If we're done animating, call the complete() function
			
			if ( _length >= _finalText.length && !_waiting && !_erasing )
			{
				onComplete();
			}
			
			if ( _length == 0 && _erasing )
			{
				onErased();
			}
		}
		
		super.update();
	}
}