package flixel.addons.system.macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr.Position;

// private enum UserAddonDefines {}
// private enum HelperAddonDefines {}

/**
 * The purpose of these "defines" classes is mainly to properly communicate version compatibility
 * among flixel libs, we shouldn't be overly concerned with backwards compatibility, but we do want
 * to know when a change breaks compatibility between Flixel-Addons and Flixel.
 * 
 * @since 3.2.2
 */
@:allow(flixel.system.macros.FlxDefines)
@:access(flixel.system.macros.FlxDefines)
class FlxAddonDefines
{
	/**
	 * Called from `flixel.system.macros.FlxDefines` on versions 5.6.0 or later
	 */
	public static function run()
	{
		#if !display
		checkCompatibility();
		#end
	}
	
	static function checkCompatibility()
	{
		/** this function is only ran in flixel versions 5.6.0 or later, meaning this error will
		 * never happen. So we've added flixel version checks in the following modules:
		 * - `FlxEffectSprite`
		 * - `FlxTypeText`
		 * - `FlxTransitionableState`
		 * - `FlxWeapon`
		 * 
		 * When the minimum version of flixel is changed to 5.6.0 or greater, remove the above
		 * checks and this comment.
		 */
		#if (flixel < "5.3.0")
		FlxDefines.abortVersion("Flixel", "5.3.0 or newer", "flixel", (macro null).pos);
		#end
	}
	
	static function isValidUserDefine(define:Any)
	{
		return false;
	}
	
	static function abortVersion(dependency:String, supported:String, found:String, pos:Position)
	{
		abort('Flixel-Addons: Unsupported $dependency version! Supported versions are $supported (found ${Context.definedValue(found)}).', pos);
	}
	
	static function abort(message:String, pos:Position)
	{
		Context.fatalError(message, pos);
	}
}
#end