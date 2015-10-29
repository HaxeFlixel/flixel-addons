package flixel.addons.ui;
import lime.utils.ByteArray;
import openfl.events.Event;
import openfl.net.FileFilter;

#if flash
import flash.net.FileReference;
#end

#if sys
import sys.io.File;
#end

#if FLX_SYSTOOLS_DIALOGS
import systools.Dialogs;
#end

#if FLX_LINC_DIALOGS
import dialogs.Dialogs;
#end

/**
 * This abstracts all the various save dialog options into one system. Native targets require either the linc_dialogs or systools haxelib
 * @author larsiusprime
 */
class FlxSaveDialog
{

	/**
	 * Prompts the user with an "open file" dialog window and returns the designated filename as a string
	 * @param	title	Title to display on the dialog window
	 * @param	extensions
	 * @param	descriptions
	 * @param	callback	(only required for flash), on all other targets if this is supplied it will fire immediately
	 * @return	the filename the user wishes to open (on flash target this always returns "", use the callback in this case)
	 */
	
	public static function openFile(title:String, extensions:Array<String>, descriptions:Array<String>, callback:String->Void=null):String
	{
		var path = "";
		
		#if flash
			
			var file:FileReference = new FileReference();
			file.addEventListener(Event.SELECT, function(e:Event) { 
				if (callback != null)
				{
					callback(file.name);
				}
			}, false, 0, true);
			file.browse(makeFileFilters(extensions, descriptions));
			
		#elseif FLX_LINC_DIALOGS
			
			path = dialogs.Dialogs.open(title, makeFileFilters(extensions, descriptions), true);
			
		#elseif FLX_SYSTOOLS_DIALOGS
			
			var paths = systools.Dialogs.openFile(title, "", { count:1, descriptions:descriptions, extensions:extensions } );
			if (paths != null && paths.length > 0)
			{
				path = paths[0];
			}
			
		#elseif neko
			
			FlxG.log.error("On neko, you need to include the 'systools' haxelib to use the openFile option.");
			
		#elseif sys
			
			FlxG.log.error("You need to include either the 'linc_dialogs' or 'systools' haxelib to use the openFile option.");
			
		#else
			
			FlxG.log.error("The current platform target does not support the openFile option.");
			
		#end
		
		if (callback != null)
		{
			callback(path);
		}
		
		return path;
	}
	
	/**
	 * Prompts the user with a "save file" dialog window and returns the designated filename as a string
	 * @param	Filename	Default filename
	 * @param	Title		Title to display on the dialog window
	 * @param	Description	File type description
	 * @param	Extension	File type extension
	 * @return	the filename the user wishes to save to
	 */
	
	public static function savePath(Filename:String = "", title:String = "", Description:String = "", Extension:String = ""):String
	{
		var path = "";
		
		#if flash
			
			FlxG.log.error("Flash does not support savePath(), use save() instead");
			
		#elseif FLX_LINC_DIALOGS
			
			path = dialogs.Dialogs.save(title, { ext:Extension, desc:Description }, true);
			
		#elseif FLX_SYSTOOLS_DIALOGS
			
			var saveFile:Dynamic = null;
			path = systools.Dialogs.saveFile(title, "", "", { count:1, descriptions:[Description], extensions:[Extension] } );
			
		#elseif neko
			
			FlxG.log.error("On neko, you need to include the 'systools' haxelib to use the savePath option.");
			
		#elseif sys
			
			FlxG.log.error("You need to include either the 'linc_dialogs' or 'systools' haxelib to use the savePath option.");
			
		#else
			
			FlxG.log.error("The current platform target does not support the savePath option.");
			
		#end
		
		return path;
	}
	
	/**
	 * Prompts the user with a "save file" dialog window and saves the data to disk
	 * @param	Filename
	 * @param	Title		Title to display on the dialog window
	 * @param	Data		The data you want to save
	 * @param	Description	File type description
	 * @param	Extension	File type extension
	 */
	
	public static function saveFile(Filename:String, Data:Dynamic, Title:String = "", Description:String = "", Extension:String = ""):Void
	{
		if (Std.is(Data, ByteArray))
		{
			saveBytes(Filename, cast Data, Description, Extension);
		}
		else if (Std.is(Data, String))
		{
			saveString(Filename, cast Data, Description, Extension);
		}
		else
		{
			saveString(Filename, Std.string(Data), Description, Extension);
		}
	}
	
	/**
	 * Prompts the user with a "save file" dialog window and saves the string to disk
	 * @param	Filename
	 * @param	Data
	 * @param	Title		Title to display on the dialog window
	 * @param	Description	File type description
	 * @param	Extension	File type extension
	 */
	public static function saveString(Filename:String = "", Data:String, Title:String = "", Description:String="", Extension:String=""):Void
	{
		
		#if flash
			
			var file:FileReference = new FileReference();
			file.save(Data, Filename);
			
		#elseif sys
			
			var bytes:ByteArray = new ByteArray(Data.length);
			bytes.writeUTFBytes(Data);
			saveBytes(Filename, bytes, Description, Extension);
			
		#else
			
			FlxG.log.error("The current platform target does not support the saveString option.");
			
		#end
	}
	
	/**
	 * Prompts the user with a "save file" dialog window and saves the bytes to disk
	 * @param	Filename
	 * @param	Bytes		
	 * @param	Title		Title to display on the dialog window
	 * @param	Description	File type description
	 * @param	Extension	File type extension
	 */
	public static function saveBytes(Filename:String = "", Bytes:ByteArray, Title:String = "", Description:String="", Extension:String=""):Void
	{
		var path = "";
		
		#if flash
		
			var file:FileReference = new FileReference();
			file.save(Bytes, Filename);
			
		#elseif FLX_LINC_DIALOGS
			
			path = dialogs.Dialogs.save(Title, { ext:Extension, desc:Description }, true);
			
		#elseif FLX_SYSTOOLS_DIALOGS
			
			var saveFile:Dynamic = null;
			path = systools.Dialogs.saveFile(Title, "", "", { count:1, descriptions:[Description], extensions:[Extension]});
			
		#elseif neko
			
			FlxG.log.error("On neko, you need to include the 'systools' haxelib to use the SaveBytes option.");
			
		#elseif sys
			
			FlxG.log.error("You need to include either the 'linc_dialogs' or 'systools' haxelib to use the SaveBytes option.");
			
		#else
			
			FlxG.log.error("The current platform target does not support the SaveBytes option.");
			
		#end
		
		if (path != "" && path != null) //if path is empty, the user cancelled the save operation and we can safely do nothing
		{
			var f = File.write(path, true);
			f.writeBytes(Bytes, 0, Bytes.length);
			f.close();
		}
	}
	
	#if flash
	
		private static function makeFileFilters(extensions:Array<String>, descriptions:Array<String>):Array<flash.net.FileFilter>
		{
			var ffs = [];
			var el = extensions == null ? 0 : extensions.length;
			var dl = descriptions == null ? 0 : descriptions.length;
			var max = Std.int(Math.max(el, dl));
			for (i in 0...max)
			{
				var ff = new FileFilter("", "");
				if (el > i)
				{
					ff.extension = extensions[i];
				}
				if (dl > i)
				{
					ff.description = descriptions[i];
				}
				ffs.push(ff);
			}
			return ffs;
		}
		
	#elseif FLX_LINC_DIALOGS
		
		private function makeFileFilters(extensions:Array<String>, descriptions:Array<String>):Array<dialogs.Dialogs.FileFilter>
		{
			var ffs = [];
			var el = extensions == null ? 0 : extensions.length;
			var dl = descriptions == null ? 0 : descriptions.length;
			var max = Math.max(el, dl);
			for (i in 0...max)
			{
				var ff = { ext:"", desc:"" };
				if (el > i)
				{
					ff.ext = extensions[i];
				}
				if (dl > i)
				{
					ff.desc = descriptions[i];
				}
				ffs.push(ff);
			}
			return ffs;
		}
		
	#end
}