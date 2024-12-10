package flixel.addons.plugin.screengrab;

#if !js
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import flixel.addons.util.PNGEncoder;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
#if sys
#if (!lime_legacy || lime < "2.9.0")
import lime.ui.FileDialog;
import lime.ui.FileDialogType;
import openfl.display.PNGEncoderOptions;
#end
#else
import openfl.net.FileReference;
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

	static var _hotkeys:Array<FlxKey>;
	static var _autoSave:Bool = false;
	static var _autoHideMouse:Bool = false;
	static var _region:Rectangle;

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
	 * @param	Keys		The key(s) you press to capture the screen (i.e. [F1, SPACE])
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
	 * @return	The screen grab as a Flash Bitmap image
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

		#if FLX_MOUSE
		if (HideMouse)
		{
			FlxG.mouse.visible = false;
		}
		#end

		theBitmap.bitmapData.draw(FlxG.stage, m);

		#if FLX_MOUSE
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

	static function fixFilename(Filename:String):String
	{
		if (Filename == "")
		{
			var date:String = Date.now().toString();
			var nameArray:Array<String> = date.split(":");
			date = nameArray.join("-");

			Filename = "grab-" + date + ".png";
		}
		else if (Filename.substr(-4) != ".png")
		{
			Filename = Filename + ".png";
		}
		return Filename;
	}

	static function save(Filename:String = ""):Void
	{
		if (screenshot.bitmapData == null)
		{
			return;
		}

		Filename = fixFilename(Filename);

		var png:ByteArray;
		#if flash
		png = PNGEncoder.encode(screenshot.bitmapData);
		#elseif openfl_legacy
		png = screenshot.bitmapData.encode(screenshot.bitmapData.rect, "png");
		#else
		png = screenshot.bitmapData.encode(screenshot.bitmapData.rect, new PNGEncoderOptions());
		#end

		#if !sys
		var file:FileReference = new FileReference();
		file.save(png, Filename);
		#elseif (!lime_legacy || lime < "2.9.0")
		var documentsDirectory = "";
		#if lime_legacy
		documentsDirectory = openfl.filesystem.File.documentsDirectory.nativePath;
		#else
		documentsDirectory = lime.system.System.documentsDirectory;
		#end

		var fd:FileDialog = new FileDialog();

		var path = "";

		fd.onSelect.add(function(str:String)
		{
			path = fixFilename(str);
			var f = sys.io.File.write(path, true);
			f.writeString(png.readUTFBytes(png.length));
			f.close();
			path = null;
		});

		try
		{
			fd.browse(FileDialogType.SAVE, "*.png", documentsDirectory);
		}
		catch (msg:String)
		{
			path = Filename; // if there was an error write out to default directory (game install directory)
		}

		if (path != "" && path != null) // if path is empty, the user cancelled the save operation and we can safely do nothing
		{
			path = fixFilename(path);
			var f = sys.io.File.write(path, true);
			f.writeString(png.readUTFBytes(png.length));
			f.close();
		}
		#end
	}

	override public function update(elapsed:Float):Void
	{
		#if FLX_KEYBOARD
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
