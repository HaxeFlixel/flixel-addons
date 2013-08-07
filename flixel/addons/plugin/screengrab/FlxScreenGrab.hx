package flixel.addons.plugin.screengrab;

#if !js
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import flixel.FlxG;
import flixel.plugin.FlxPlugin;

#if flash
import flash.net.FileReference;
#end

/**
 * Captures a screen grab of the game and stores it locally, optionally saving as a PNG.
 * 
 * @link http://www.photonstorm.com
 * @author Richard Davey / Photon Storm
 */
class FlxScreenGrab extends FlxPlugin
{
	static public var screenshot:Bitmap;
	
	static private var _hotkey:String = "";
	static private var _autoSave:Bool = false;
	static private var _autoHideMouse:Bool = false;
	static private var _region:Rectangle;
	
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
	static public function defineCaptureRegion(X:Int, Y:Int, Width:Int, Height:Int):Void
	{
		_region = new Rectangle(X, Y, Width, Height);
	}
	
	/**
	 * Clears a previously defined capture region
	 */
	static public function clearCaptureRegion():Void
	{
		_region = null;
	}
	
	/**
	 * Specify which key will capture a screen shot. Use the String value of the key in the same way FlxG.keys does (so "F1" for example)
	 * Optionally save the image to a file immediately. This uses the file systems "Save as" dialog window and pauses your game during the process.
	 * 
	 * @param	Key			String The key you press to capture the screen (i.e. "F1", "SPACE", etc - see system.input.Keyboard.as source for reference)
	 * @param	SaveToFile	Boolean If set to true it will immediately encodes the grab to a PNG and open a "Save As" dialog window when the hotkey is pressed
	 * @param	HideMouse	Boolean If set to true the mouse will be hidden before capture and displayed afterwards when the hotkey is pressed
	 */
	static public function defineHotKey(Key:String, SaveToFile:Bool = false, HideMouse:Bool = false):Void
	{
		_hotkey = Key;
		_autoSave = SaveToFile;
		_autoHideMouse = HideMouse;
	}
	
	/**
	 * Clears a previously defined hotkey
	 */
	static public function clearHotKey():Void
	{
		_hotkey = "";
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
	static public function grab(?CaptureRegion:Rectangle, ?SaveToFile:Bool = false, HideMouse:Bool = false):Bitmap
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
		if (_autoHideMouse || HideMouse)
		{
			FlxG.mouse.hide();
		}
		#end
		
		theBitmap.bitmapData.draw(FlxG.stage, m);
		
		#if !FLX_NO_MOUSE
		if (_autoHideMouse || HideMouse)
		{
			FlxG.mouse.show();
		}
		#end
		
		screenshot = theBitmap;
		
		if (SaveToFile || _autoSave)
		{
			save();
		}
		
		return theBitmap;
	}
	
	static private function save(Filename:String = ""):Void
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
		
		#if flash
		var png:ByteArray = PNGEncoder.encode(screenshot.bitmapData);
		var file:FileReference = new FileReference();
		file.save(png, Filename);
		#else
		var png:ByteArray = screenshot.bitmapData.encode('x');
		var f = sys.io.File.write(Filename, true);
		f.writeString(png.readUTFBytes(png.length));
		f.close();
		#end
	}
	
	override public function update():Void
	{
		#if !FLX_NO_KEYBOARD
		if (_hotkey != "")
		{
			if (FlxG.keys.justReleased(_hotkey))
			{
				grab();
			}
		}
		#end
	}
	
	override public function destroy():Void
	{
		clearCaptureRegion();
		clearHotKey();
	}
}
#end