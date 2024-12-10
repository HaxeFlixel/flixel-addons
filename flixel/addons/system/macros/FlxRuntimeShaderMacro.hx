package flixel.addons.system.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ExprTools;

class FlxRuntimeShaderMacro
{
	/**
	 * Retrieves the value of a specified metadata tag (only `String` values) from the current class
	 * or any of its superclasses. The function searches the fields of the class
	 * for the specified metadata and returns its value as a macro expression.
	 * If `overwrite` is set to `false`, it will use the first non-null `String` value
	 * found and ignore any subsequent values.
	 *
	 * @param metaName The name of the metadata tag to retrieve.
	 * @param overwrite If `true`, the metadata value will be concatenated when found; if `false`, only the first non-null value will be used.
	 * @return The value of the specified metadata as an expression, or `null` if not found.
	 */
	public static macro function retrieveMetadata(metaName:String, overwrite:Bool = true):Expr
	{
		var result:String = null;

		final localClass:ClassType = Context.getLocalClass().get();

		result = checkClassForMetadata(localClass, metaName, overwrite, result);

		var parent:ClassType = localClass.superClass != null ? localClass.superClass.t.get() : null;

		while (parent != null)
		{
			result = checkClassForMetadata(parent, metaName, overwrite, result);

			parent = parent.superClass != null ? parent.superClass.t.get() : null;
		}

		// Context.info('Retrieving $metaName: $result', Context.currentPos());

		return macro $v{result};
	}

	#if macro
	@:noCompletion
	private static function checkClassForMetadata(classType:ClassType, metaName:String, overwrite:Bool, currentResult:String):String
	{
		var result:String = currentResult;

		for (field in [classType.constructor.get()].concat(classType.fields.get()))
		{
			for (meta in field.meta.get())
			{
				if (meta.name == metaName || meta.name == ':' + metaName)
				{
					final value:Dynamic = meta.params[0].getValue();

					if (!(value is String))
						continue;

					if (overwrite)
						result = result == null ? value : '$value\n$result';
					else if (result == null)
					{
						result = value;
						break;
					}
				}
			}

			if (!overwrite && result != null)
				break;
		}

		return result;
	}
	#end
}
