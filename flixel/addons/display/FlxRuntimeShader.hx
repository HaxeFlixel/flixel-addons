package flixel.addons.display;

import flixel.system.FlxAssets.FlxShader;
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
class FlxRuntimeShader extends FlxShader
{
	#if FLX_DRAW_QUADS
	// We need to add stuff from FlxGraphicsShader too!
	#else
	// Only stuff from openfl.display.GraphicsShader is needed
	#end
	// These variables got copied from openfl.display.GraphicsShader
	// and from flixel.graphics.tile.FlxGraphicsShader.

	static final PRAGMA_HEADER:String = "#pragma header";
	static final PRAGMA_BODY:String = "#pragma body";

	/**
	 * Constructs a GLSL shader.
	 * @param fragmentSource The fragment shader source.
	 * @param vertexSource The vertex shader source.
	 * Note you also need to `initialize()` the shader MANUALLY! It can't be done automatically.
	 */
	public function new(fragmentSource:String = null, vertexSource:String = null, glVersion:String = null):Void
	{
		if (glVersion != null)
			this.glVersion = glVersion;

		if (fragmentSource == null)
		{
			this.glFragmentSource = __processFragmentSource(glFragmentSourceRaw);
		}
		else
		{
			this.glFragmentSource = __processFragmentSource(fragmentSource);
		}

		if (vertexSource == null)
		{
			var s = __processVertexSource(glVertexSourceRaw);
			this.glVertexSource = s;
		}
		else
		{
			var s = __processVertexSource(vertexSource);
			this.glVertexSource = s;
		}

		@:privateAccess {
			// This tells the shader that the glVertexSource/glFragmentSource have been updated.
			this.__glSourceDirty = true;
		}

		super();
	}

	/**
	 * Replace the `#pragma header` and `#pragma body` with the fragment shader header and body.
	 */
	@:noCompletion private function __processFragmentSource(input:String):String
	{
		var result = StringTools.replace(input, PRAGMA_HEADER, glFragmentHeaderRaw);
		result = StringTools.replace(result, PRAGMA_BODY, glFragmentBodyRaw);
		return result;
	}

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
<<<<<<< HEAD
		var prop:ShaderParameter<Float> = Reflect.field(this.data, name);
		@:privateAccess
		if (prop == null)
		{
			trace('[WARN] Shader float property ${name} not found.');
			return;
		}
=======
		var prop:ShaderParameter<Float> = Reflect.field(data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader float property "$name" not found.');
			return;
		}

>>>>>>> flixel/dev
		prop.value = [value];
	}

	/**
<<<<<<< HEAD
=======
	 * Retrieve a float parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getFloat(name:String):Null<Float>
	{
		var prop:ShaderParameter<Float> = Reflect.field(data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader float property "$name" not found.');
			return null;
		}

		return prop.value[0];
	}

	/**
>>>>>>> flixel/dev
	 * Modify a float array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setFloatArray(name:String, value:Array<Float>):Void
	{
<<<<<<< HEAD
		var prop:ShaderParameter<Float> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader float[] property ${name} not found.');
			return;
		}
=======
		var prop:ShaderParameter<Float> = Reflect.field(data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader float[] property "$name" not found.');
			return;
		}

>>>>>>> flixel/dev
		prop.value = value;
	}

	/**
<<<<<<< HEAD
=======
	 * Retrieve a float array parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getFloatArray(name:String):Null<Array<Float>>
	{
		var prop:ShaderParameter<Float> = Reflect.field(data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader float[] property "$name" not found.');
			return null;
		}

		return prop.value;
	}

	/**
>>>>>>> flixel/dev
	 * Modify an integer parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setInt(name:String, value:Int):Void
	{
<<<<<<< HEAD
		var prop:ShaderParameter<Int> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader int property ${name} not found.');
			return;
		}
=======
		var prop:ShaderParameter<Int> = Reflect.field(data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader int property "$name" not found.');
			return;
		}

>>>>>>> flixel/dev
		prop.value = [value];
	}

	/**
<<<<<<< HEAD
=======
	 * Retrieve an integer parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getInt(name:String):Null<Int>
	{
		var prop:ShaderParameter<Int> = Reflect.field(data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader int property "$name" not found.');
			return null;
		}

		return prop.value[0];
	}

	/**
>>>>>>> flixel/dev
	 * Modify an integer array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setIntArray(name:String, value:Array<Int>):Void
	{
<<<<<<< HEAD
		var prop:ShaderParameter<Int> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader int[] property ${name} not found.');
			return;
		}
=======
		var prop:ShaderParameter<Int> = Reflect.field(data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader int[] property "$name" not found.');
			return;
		}

>>>>>>> flixel/dev
		prop.value = value;
	}

	/**
<<<<<<< HEAD
	 * Modify a boolean parameter of the shader.
=======
	 * Retrieve an integer array parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getIntArray(name:String):Null<Array<Int>>
	{
		var prop:ShaderParameter<Int> = Reflect.field(data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader int[] property "$name" not found.');
			return null;
		}

		return prop.value;
	}

	/**
	 * Modify a bool parameter of the shader.
	 *
>>>>>>> flixel/dev
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBool(name:String, value:Bool):Void
	{
<<<<<<< HEAD
		var prop:ShaderParameter<Bool> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader bool property ${name} not found.');
			return;
		}
=======
		var prop:ShaderParameter<Bool> = Reflect.field(data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader bool property "$name" not found.');
			return;
		}

>>>>>>> flixel/dev
		prop.value = [value];
	}

	/**
<<<<<<< HEAD
	 * Modify a boolean array parameter of the shader.
=======
	 * Retrieve a bool parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getBool(name:String):Null<Bool>
	{
		var prop:ShaderParameter<Bool> = Reflect.field(data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader bool property "$name" not found.');
			return null;
		}

		return prop.value[0];
	}

	/**
	 * Modify a bool array parameter of the shader.
	 *
>>>>>>> flixel/dev
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBoolArray(name:String, value:Array<Bool>):Void
	{
<<<<<<< HEAD
		var prop:ShaderParameter<Bool> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader bool[] property ${name} not found.');
			return;
		}
=======
		var prop:ShaderParameter<Bool> = Reflect.field(data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader bool[] property "$name" not found.');
			return;
		}

>>>>>>> flixel/dev
		prop.value = value;
	}

	/**
<<<<<<< HEAD
	 * Modify a bitmap data parameter of the shader.
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBitmapData(name:String, value:openfl.display.BitmapData):Void
	{
		var prop:ShaderInput<openfl.display.BitmapData> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader sampler2D property ${name} not found.');
			return;
		}
=======
	 * Retrieve a bool array parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getBoolArray(name:String):Null<Array<Bool>>
	{
		var prop:ShaderParameter<Bool> = Reflect.field(data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader bool[] property "$name" not found.');
			return null;
		}

		return prop.value;
	}

	/**
	 * Modify a bitmap data parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setSampler2D(name:String, value:BitmapData):Void
	{
		var prop:ShaderInput<BitmapData> = Reflect.field(data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader sampler2D property "$name" not found.');
			return;
		}

>>>>>>> flixel/dev
		prop.input = value;
	}

	/**
<<<<<<< HEAD
	 * Retrieve a float parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getFloat(name:String):Null<Float>
	{
		var prop:ShaderParameter<Float> = Reflect.field(this.data, name);
		if (prop == null || prop.value.length == 0)
		{
			trace('[WARN] Shader float property ${name} not found.');
			return null;
		}
		return prop.value[0];
	}

	/**
	 * Retrieve a float array parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getFloatArray(name:String):Null<Array<Float>>
	{
		var prop:ShaderParameter<Float> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader float[] property ${name} not found.');
			return null;
		}
		return prop.value;
	}

	/**
	 * Retrieve an integer parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getInt(name:String):Null<Int>
	{
		var prop:ShaderParameter<Int> = Reflect.field(this.data, name);
		if (prop == null || prop.value.length == 0)
		{
			trace('[WARN] Shader int property ${name} not found.');
			return null;
		}
		return prop.value[0];
	}

	/**
	 * Retrieve an integer array parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getIntArray(name:String):Null<Array<Int>>
	{
		var prop:ShaderParameter<Int> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader int[] property ${name} not found.');
			return null;
		}
		return prop.value;
	}

	/**
	 * Retrieve a boolean parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getBool(name:String):Null<Bool>
	{
		var prop:ShaderParameter<Bool> = Reflect.field(this.data, name);
		if (prop == null || prop.value.length == 0)
		{
			trace('[WARN] Shader bool property ${name} not found.');
			return null;
		}
		return prop.value[0];
	}

	/**
	 * Retrieve a boolean array parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getBoolArray(name:String):Null<Array<Bool>>
	{
		var prop:ShaderParameter<Bool> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader bool[] property ${name} not found.');
			return null;
		}
		return prop.value;
	}

	/**
	 * Retrieve a bitmap data parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getBitmapData(name:String):Null<openfl.display.BitmapData>
	{
		var prop:ShaderInput<openfl.display.BitmapData> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('[WARN] Shader sampler2D property ${name} not found.');
			return null;
		}
		return prop.input;
	}

	public function toString():String
	{
		return 'FlxRuntimeShader';
	}
}
=======
	 * Retrieve a bitmap data parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getSampler2D(name:String):Null<BitmapData>
	{
		var prop:ShaderInput<BitmapData> = Reflect.field(data, name);

		if (prop == null)
		{
			FlxG.log.warn('Shader sampler2D property "$name" not found.');
			return null;
		}

		return prop.input;
	}

	// Overrides
	@:noCompletion private override function __processGLData(source:String, storageType:String):Void
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

	@:noCompletion private override function set_glFragmentSource(value:String):String
	{
		if (value != null)
			value = value.replace("#pragma header", BASE_FRAGMENT_HEADER).replace("#pragma body", BASE_FRAGMENT_BODY);

		if (value != __glFragmentSource)
			__glSourceDirty = true;

		return __glFragmentSource = value;
	}

	@:noCompletion private override function set_glVertexSource(value:String):String
	{
		if (value != null)
			value = value.replace("#pragma header", BASE_VERTEX_HEADER).replace("#pragma body", BASE_VERTEX_BODY);

		if (value != __glVertexSource)
			__glSourceDirty = true;

		return __glVertexSource = value;
	}
}
#end
>>>>>>> flixel/dev
