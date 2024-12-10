package flixel.addons.display;

#if (nme || flash)
	#if (FLX_NO_COVERAGE_TEST && !(doc_gen))
		#error "FlxRuntimeShader isn't available with nme or flash."
	#end
#else
import flixel.addons.system.macros.FlxRuntimeShaderMacro;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.util.FlxStringUtil;
#if lime
import lime.utils.Float32Array;
#end
import openfl.display.BitmapData;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

/**
 * An wrapper for Flixel/OpenFL's shaders, which takes fragment and vertex source
 * in the constructor instead of using macros, so it can be provided data
 * at runtime (for example, when using mods).
 *
 * HOW TO USE:
 * 1. Create an instance of this class, passing the text of the `.frag` and `.vert` files.
 *    Note that you can set either of these to null (making them both null would make the shader do nothing???).
 * 2. Use `flxSprite.shader = runtimeShader` to apply the shader to the sprite.
 * 3. Use `runtimeShader.setFloat()`, `setBool()` etc. to modify any uniforms.
 * 4. Use `setBitmapData()` to add additional textures as `sampler2D` uniforms
 *
 * @author MasterEric
 * @see https://github.com/openfl/openfl/blob/develop/src/openfl/utils/_internal/ShaderMacro.hx
 * @see https://dixonary.co.uk/blog/shadertoy
 */
class FlxRuntimeShader extends FlxGraphicsShader
{
	/**
	 * Replace the `#pragma header` and `#pragma body` with the fragment shader header and body.
	 */
	@:noCompletion private function __processFragmentSource(input:String):String
	{
		if (fragmentSource != null && fragmentSource.length > 0)
			glFragmentSource = fragmentSource;
		else
			glFragmentSource = FlxRuntimeShaderMacro.retrieveMetadata('glFragmentSource', false);

		if (vertexSource != null && vertexSource.length > 0)
			glVertexSource = vertexSource;
		else
			glVertexSource = FlxRuntimeShaderMacro.retrieveMetadata('glVertexSource', false);

	/**
	 * Replace the `#pragma header` and `#pragma body` with the vertex shader header and body.
	 */
	@:noCompletion private function __processVertexSource(input:String):String
	{
		var result = StringTools.replace(input, PRAGMA_HEADER, glVertexHeaderRaw);
		result = StringTools.replace(result, PRAGMA_BODY, glVertexBodyRaw);
		return result;
	}

	/**
	 * Modify a float parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setFloat(name:String, value:Float):Void
	{
		final shaderParameter:ShaderParameter<Float> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader float parameter "$name" not found.');
			return;
		}

		shaderParameter.value = [value];
	}

	/**
	 * Modify a float array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setFloatArray(name:String, value:Array<Float>):Void
	{
		final shaderParameter:ShaderParameter<Float> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader float parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value[0];
	}

	/**
	 * Modify an integer parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setInt(name:String, value:Int):Void
	{
		final shaderParameter:ShaderParameter<Float> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader float[] parameter "$name" not found.');
			return;
		}

		shaderParameter.value = value;
	}

	/**
	 * Modify an integer array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setIntArray(name:String, value:Array<Int>):Void
	{
		final shaderParameter:ShaderParameter<Float> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader float[] parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value;
	}

	/**
	 * Modify a boolean parameter of the shader.
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBool(name:String, value:Bool):Void
	{
		final shaderParameter:ShaderParameter<Int> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader int parameter "$name" not found.');
			return;
		}

		shaderParameter.value = [value];
	}

	/**
	 * Modify a boolean array parameter of the shader.
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBoolArray(name:String, value:Array<Bool>):Void
	{
		final shaderParameter:ShaderParameter<Int> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader int parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value[0];
	}

	/**
	 * Modify a bitmap data parameter of the shader.
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBitmapData(name:String, value:openfl.display.BitmapData):Void
	{
		final shaderParameter:ShaderParameter<Int> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader int[] parameter "$name" not found.');
			return;
		}

		shaderParameter.value = value;
	}

	/**
	 * Retrieve a float parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getFloat(name:String):Null<Float>
	{
		final shaderParameter:ShaderParameter<Int> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader int[] parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value;
	}

	/**
	 * Retrieve a float array parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getFloatArray(name:String):Null<Array<Float>>
	{
		final shaderParameter:ShaderParameter<Bool> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader bool parameter "$name" not found.');
			return;
		}

		shaderParameter.value = [value];
	}

	/**
	 * Retrieve an integer parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getInt(name:String):Null<Int>
	{
		final shaderParameter:ShaderParameter<Bool> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader bool parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value[0];
	}

	/**
	 * Retrieve an integer array parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getIntArray(name:String):Null<Array<Int>>
	{
		final shaderParameter:ShaderParameter<Bool> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader bool[] parameter "$name" not found.');
			return;
		}

		shaderParameter.value = value;
	}

	/**
	 * Retrieve a boolean parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getBool(name:String):Null<Bool>
	{
		final shaderParameter:ShaderParameter<Bool> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			FlxG.log.warn('Shader bool[] parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value;
	}

	/**
	 * Modify a bitmap data input of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function getBoolArray(name:String):Null<Array<Bool>>
	{
		final shaderInput:ShaderInput<BitmapData> = Reflect.field(data, name);

		if (shaderInput == null)
		{
			FlxG.log.warn('Shader sampler2D input "$name" not found.');
			return;
		}

		shaderInput.input = value;
	}

	/**
	 * Retrieve a bitmap data input of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getBitmapData(name:String):Null<openfl.display.BitmapData>
	{
		final shaderInput:ShaderInput<BitmapData> = Reflect.field(data, name);

		if (shaderInput == null)
		{
			FlxG.log.warn('Shader sampler2D input "$name" not found.');
			return null;
		}

		return shaderInput.input;
	}

	/**
	 * Convert the shader to a readable string name. Useful for debugging.
	 */
	public function toString():String
	{
		return FlxStringUtil.getDebugString([for (field in Reflect.fields(data)) LabelValuePair.weak(field, Reflect.field(data, field))]);
	}

	@:noCompletion
	private override function __processGLData(source:String, storageType:String):Void
	{
		var lastMatch = 0, position, regex, name, type;

		if (storageType == "uniform")
		{
			regex = ~/uniform ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/;
		}
		else
		{
			regex = ~/attribute ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/;
		}

		@:privateAccess
		while (regex.matchSub(source, lastMatch))
		{
			type = regex.matched(1);
			name = regex.matched(2);

			if (StringTools.startsWith(name, "gl_"))
				continue;

			var isUniform = (storageType == "uniform");

			if (StringTools.startsWith(type, "sampler"))
			{
				var input = new ShaderInput<BitmapData>();
				input.name = name;
				input.__isUniform = isUniform;
				__inputBitmapData.push(input);

				switch (name)
				{
					case "openfl_Texture":
						__texture = input;
					case "bitmap":
						__bitmap = input;
					default:
				}

				Reflect.setField(__data, name, input);

				try
				{
					if (__isGenerated)
						Reflect.setField(this, name, input);
				}
				catch (e:Dynamic) {}
			}
			else if (!Reflect.hasField(__data, name) || Reflect.field(__data, name) == null)
			{
				var parameterType:ShaderParameterType = switch (type)
				{
					case "bool": BOOL;
					case "double", "float": FLOAT;
					case "int", "uint": INT;
					case "bvec2": BOOL2;
					case "bvec3": BOOL3;
					case "bvec4": BOOL4;
					case "ivec2", "uvec2": INT2;
					case "ivec3", "uvec3": INT3;
					case "ivec4", "uvec4": INT4;
					case "vec2", "dvec2": FLOAT2;
					case "vec3", "dvec3": FLOAT3;
					case "vec4", "dvec4": FLOAT4;
					case "mat2", "mat2x2": MATRIX2X2;
					case "mat2x3": MATRIX2X3;
					case "mat2x4": MATRIX2X4;
					case "mat3x2": MATRIX3X2;
					case "mat3", "mat3x3": MATRIX3X3;
					case "mat3x4": MATRIX3X4;
					case "mat4x2": MATRIX4X2;
					case "mat4x3": MATRIX4X3;
					case "mat4", "mat4x4": MATRIX4X4;
					default: null;
				}

				var length = switch (parameterType)
				{
					case BOOL2, INT2, FLOAT2: 2;
					case BOOL3, INT3, FLOAT3: 3;
					case BOOL4, INT4, FLOAT4, MATRIX2X2: 4;
					case MATRIX3X3: 9;
					case MATRIX4X4: 16;
					default: 1;
				}

				var arrayLength = switch (parameterType)
				{
					case MATRIX2X2: 2;
					case MATRIX3X3: 3;
					case MATRIX4X4: 4;
					default: 1;
				}

				switch (parameterType)
				{
					case BOOL, BOOL2, BOOL3, BOOL4:
						var parameter = new ShaderParameter<Bool>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						parameter.__isBool = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramBool.push(parameter);

						if (name == "openfl_HasColorTransform")
						{
							__hasColorTransform = parameter;
						}

						Reflect.setField(__data, name, parameter);

						try
						{
							if (__isGenerated)
								Reflect.setField(this, name, parameter);
						}
						catch (e:Dynamic) {}

					case INT, INT2, INT3, INT4:
						var parameter = new ShaderParameter<Int>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						parameter.__isInt = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramInt.push(parameter);

						Reflect.setField(__data, name, parameter);

						try
						{
							if (__isGenerated)
								Reflect.setField(this, name, parameter);
						}
						catch (e:Dynamic) {}

					default:
						var parameter = new ShaderParameter<Float>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						#if lime
						if (arrayLength > 0)
							parameter.__uniformMatrix = new Float32Array(arrayLength * arrayLength);
						#end
						parameter.__isFloat = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramFloat.push(parameter);

						if (StringTools.startsWith(name, "openfl_"))
						{
							switch (name)
							{
								case "openfl_Alpha": __alpha = parameter;
								case "openfl_ColorMultiplier": __colorMultiplier = parameter;
								case "openfl_ColorOffset": __colorOffset = parameter;
								case "openfl_Matrix": __matrix = parameter;
								case "openfl_Position": __position = parameter;
								case "openfl_TextureCoord": __textureCoord = parameter;
								case "openfl_TextureSize": __textureSize = parameter;
								default:
							}
						}

						Reflect.setField(__data, name, parameter);

						try
						{
							if (__isGenerated)
								Reflect.setField(this, name, parameter);
						}
						catch (e:Dynamic) {}
				}
			}

			position = regex.matchedPos();
			lastMatch = position.pos + position.len;
		}
	}

	@:noCompletion
	private override function set_glFragmentSource(value:String):String
	{
		if (value != null)
			value = value.replace("#pragma header", FlxRuntimeShaderMacro.retrieveMetadata('glFragmentHeader')).replace("#pragma body", FlxRuntimeShaderMacro.retrieveMetadata('glFragmentBody'));

		if (value != __glFragmentSource)
			__glSourceDirty = true;

		return __glFragmentSource = value;
	}

	@:noCompletion
	private override function set_glVertexSource(value:String):String
	{
		if (value != null)
			value = value.replace("#pragma header", FlxRuntimeShaderMacro.retrieveMetadata('glVertexHeader')).replace("#pragma body", FlxRuntimeShaderMacro.retrieveMetadata('glVertexBody'));

		if (value != __glVertexSource)
			__glSourceDirty = true;

		return __glVertexSource = value;
	}
}
