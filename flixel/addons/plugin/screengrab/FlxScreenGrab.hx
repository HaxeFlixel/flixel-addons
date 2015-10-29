package flixel.addons.plugin.screengrab;
import flixel.addons.ui.FlxSaveDialog;

#if (sys && systools)
import systools.Dialogs;
#end

#if !js
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import flixel.addons.util.PNGEncoder;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

#if flash
import flash.net.FileReference;
#end

/**
 * Captures a screen grab of the game and stores it locally, optionally saving as a PNG.
 * 
 * @link http://www.photonstorm.com
 * @author Richard Davey / Photon Storm
 */
class FlxScreenGrab extends FlxBasic
{
	public static var screenshot(default, null):Bitmap;
	
	private static var _hotkeys:Array<FlxKey>;
	private static var _autoSave:Bool = false;
	private static var _autoHideMouse:Bool = false;
	private static var _region:Rectangle;
	
	/**
	 * Defines the region of the screen that should be captured. If you need it to be a fixed location then use this.
	 * If you want to grab the whole SWF size, you don't need to set this as that is the default.
	 * Remember that if your game is running in a zoom mode > 1 you need to account for this here.
	 * 
	 * @param	X		The x coordinate (in Flash display space, not Flixel game world)
	 * @param	Y		The y coordinate (in Flash display space, not Flixel game world)
	 * @param	Width	The width of the grab region
	 * @param	Height	The height of the grab region
	 */
	public static function defineCaptureRegion(X:Int, Y:Int, Width:Int, Height:Int):Void
	{
		_region = new Rectangle(X, Y, Width, Height);
	}
	
	/**
	 * Clears a previously defined capture region
	 */
	public static function clearCaptureRegion():Void
	{
		_region = null;
	}
	
	/**
	 * Specify which key will capture a screen shot. Use the String value of the key in the same way FlxG.keys does (so "F1" for example)
	 * Optionally save the image to a file immediately. This uses the file systems "Save as" dialog window and pauses your game during the process.
	 * 
	 * @param	Key			The key(s) you press to capture the screen (i.e. [F1, SPACE])
	 * @param	SaveToFile	If true it will immediately encodes the grab to a PNG and open a "Save As" dialog window when the hotkey is pressed
	 * @param	HideMouse	If true the mouse will be hidden before capture and displayed afterwards when the hotkey is pressed
	 */
	public static function defineHotKeys(Keys:Array<FlxKey>, SaveToFile:Bool = false, HideMouse:Bool = false):Void
	{
		_hotkeys = Keys;
		_autoSave = SaveToFile;
		_autoHideMouse = HideMouse;
	}
	
	/**
	 * Clears all previously defined hotkeys
	 */
	public static function clearHotKeys():Void
	{
		_hotkeys = [];
		_autoSave = false;
		_autoHideMouse = false;
	}
	
	/**
	 * Takes a screen grab immediately of the given region or a previously defined region
	 * 
	 * @param	CaptureRegion	A Rectangle area to capture. This over-rides that set by "defineCaptureRegion". If neither are set the full SWF size is used.
	 * @param	SaveToFile		Boolean If set to true it will immediately encode the grab to a PNG and open a "Save As" dialog window
	 * @param	HideMouse		Boolean If set to true the mouse will be hidden before capture and displayed again afterwards
	 * @return	Bitmap			The screen grab as a Flash Bitmap image
	 */
	public static function grab(?CaptureRegion:Rectangle, ?SaveToFile:Bool = false, HideMouse:Bool = false):Bitmap
	{
		var bounds:Rectangle;
		
		if (CaptureRegion != null)
		{
			bounds = new Rectangle(CaptureRegion.x, CaptureRegion.y, CaptureRegion.width, CaptureRegion.height);
		}
		else if (_region != null)
		{
			bounds = new Rectangle(_region.x, _region.y, _region.width, _region.height);
		}
		else
		{
			bounds = new Rectangle(0, 0, FlxG.stage.stageWidth, FlxG.stage.stageHeight);
		}
		
		var theBitmap:Bitmap = new Bitmap(new BitmapData(Math.floor(bounds.width), Math.floor(bounds.height), true, 0x0));
		
		var m:Matrix = new Matrix(1, 0, 0, 1, -bounds.x, -bounds.y);
		
		#if !FLX_NO_MOUSE
		if (HideMouse)
		{
			FlxG.mouse.visible = false;
		}
		#end
		
		theBitmap.bitmapData.draw(FlxG.stage, m);
		
		#if !FLX_NO_MOUSE
		if (HideMouse)
		{
			FlxG.mouse.visible = true;
		}
		#end
		
		screenshot = theBitmap;
		
		if (SaveToFile)
		{
			save();
		}
		
		return theBitmap;
	}
	
	private static function save(Filename:String = ""):Void
	{
		if (screenshot.bitmapData == null)
		{
			return;
		}
		
		if (Filename == "")
		{
			var date:String = Date.now().toString();
			var nameArray:Array<String> = date.split(":");
			date = nameArray.join("-");
			
			Filename = "grab-" + date + ".png";
		}
		else if (Filename.substr( -4) != ".png")
		{
			Filename = Filename + ".png";
		}
	
		var png:ByteArray = null;
	#if flash
		png = PNGEncoder.encode(screenshot.bitmapData);
	#elseif systools
		#if lime_legacy
			png = screenshot.bitmapData.encode('png');
		#else
			png = screenshot.bitmapData.encode(screenshot.bitmapData.rect, 'png');
		#end
	#end
		
		FlxSaveDialog.saveFile(Filename, png, "png files", "*.png");
	}
	
	
	override public function update(elapsed:Float):Void
	{
		#if !FLX_NO_KEYBOARD
		if (FlxG.keys.anyJustReleased(_hotkeys))
		{
			grab(null, _autoSave, _autoHideMouse);
		}
		#end
	}
	
	override public function destroy():Void
	{
		clearCaptureRegion();
		clearHotKeys();
	}
}
#end