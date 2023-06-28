package flixel.addons.editors.pex;

import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.FlxG;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import haxe.xml.Parser;
import openfl.Assets;
import openfl.display.BlendMode;
import haxe.xml.Access;

/**
 * Parser for particle files created with "Starling Particle Editor" or "Particle Designer".
 *
 * Starling Particle Editor:
 * @see http://onebyonedesign.com/flash/particleeditor/
 * @see https://github.com/devon-o/Starling-Particle-Editor
 *
 * Particle Designer:
 * @see https://71squared.com/particledesigner
 *
 * @author MrCdK
 */
class FlxPexParser
{
	/**
	 * This function will parse a *.pex file and return a new emitter.
	 * There are some incompatibilities:
	 *  - It only supports the "Gravity" emitter type.
	 *  - Tangential and radial acceleration aren't supported.
	 *  - Blend functions aren't supported. The default blend mode is ADD.
	 * @param	data			The data to be parsed. It has to be an ID to the assets file, a file embedded with @:file(), a string with the content of the file or a XML object.
	 * @param	particleGraphic	The particle graphic
	 * @param	emitter			(optional) A FlxEmitter. Most properties will be overwritten!
	 * @param	scale			(optional) Used to scale the resulting emitter. Will scale both the texture size and positions of resulting particles.
	 * @return	A new emitter
	 */
	public static function parse<T:FlxEmitter>(data:Dynamic, particleGraphic:FlxGraphicAsset, ?emitter:T, scale:Float = 1):T
	{
		if (emitter == null)
		{
			emitter = cast new FlxEmitter();
		}

		var config:Access = getAccessNode(data);

		// Need to extract the particle graphic information
		var particle:FlxParticle = new FlxParticle();
		particle.loadGraphic(particleGraphic);

		var emitterType = Std.parseInt(config.node.emitterType.att.value);
		if (emitterType != PexEmitterType.GRAVITY)
		{
			FlxG.log.warn("FlxPexParser: This emitter type isn't supported. Only the 'Gravity' emitter type is supported.");
		}

		var maxParticles:Int = Std.parseInt(config.node.maxParticles.att.value);

		var lifespan = minMax("particleLifeSpan", "particleLifespanVariance", config);
		var speed = minMax("speed", config);

		var angle = minMax("angle", config);

		var startSize = minMax("startParticleSize", config);
		var finishSize = minMax("finishParticleSize", "finishParticleSizeVariance", config);
		var rotationStart = minMax("rotationStart", config);
		var rotationEnd = minMax("rotationEnd", config);

		var sourcePositionVariance = xy("sourcePositionVariance", config);
		var gravity = xy("gravity", config);

		var startColors = color("startColor", config);
		var finishColors = color("finishColor", config);

		emitter.launchMode = FlxEmitterMode.CIRCLE;
		emitter.loadParticles(particleGraphic, maxParticles);

		emitter.width = (sourcePositionVariance.x == 0 ? 1 : sourcePositionVariance.x * 2) * scale;
		emitter.height = (sourcePositionVariance.y == 0 ? 1 : sourcePositionVariance.y * 2) * scale;

		emitter.lifespan.set(lifespan.min, lifespan.max);

		emitter.acceleration.set(gravity.x * scale, gravity.y * scale);

		emitter.launchAngle.set(angle.min, angle.max);

		emitter.speed.start.set(speed.min * scale, speed.max * scale);
		emitter.speed.end.set(speed.min * scale, speed.max * scale);

		emitter.angle.set(rotationStart.min, rotationStart.max, rotationEnd.min, rotationEnd.max);

		emitter.scale.start.min.set(startSize.min / particle.frameWidth * scale, startSize.min / particle.frameHeight * scale);
		emitter.scale.start.max.set(startSize.max / particle.frameWidth * scale, startSize.max / particle.frameHeight * scale);
		emitter.scale.end.min.set(finishSize.min / particle.frameWidth * scale, finishSize.min / particle.frameHeight * scale);
		emitter.scale.end.max.set(finishSize.max / particle.frameWidth * scale, finishSize.max / particle.frameHeight * scale);

		emitter.alpha.set(startColors.minColor.alphaFloat, startColors.maxColor.alphaFloat, finishColors.minColor.alphaFloat,
			finishColors.maxColor.alphaFloat);
		emitter.color.set(startColors.minColor, startColors.maxColor, finishColors.minColor, finishColors.maxColor);

		if (config.hasNode.blendFuncSource && config.hasNode.blendFuncDestination)
		{
			/**
			 * ParticleDesigner blend function values:
			 *
			 * 0x000: ZERO
			 * 0x001: ONE
			 * 0x300: SOURCE_COLOR
			 * 0x301: ONE_MINUS_SOURCE_COLOR
			 * 0x302: SOURCE_ALPHA
			 * 0x303: ONE_MINUS_SOURCE_ALPHA
			 * 0x304: DESTINATION_ALPHA
			 * 0x305: ONE_MINUS_DESTINATION_ALPHA
			 * 0x306: DESTINATION_COLOR
			 * 0x307: ONE_MINUS_DESTINATION_COLOR
			**/

			var src = Std.parseInt(config.node.blendFuncSource.att.value),
				dst = Std.parseInt(config.node.blendFuncDestination.att.value);

			emitter.blend = switch ((src << 12) | dst)
			{
				case 0x306303:
					BlendMode.MULTIPLY;
				case 0x001301:
					BlendMode.SCREEN;
				case 0x001303, 0x302303:
					BlendMode.NORMAL;
				default:
					BlendMode.ADD;
			}
		}
		else
		{
			emitter.blend = BlendMode.ADD;
		}
		emitter.keepScaleRatio = true;
		return emitter;
	}

	static function minMax(property:String, ?propertyVariance:String, config:Access):{min:Float, max:Float}
	{
		if (propertyVariance == null)
		{
			propertyVariance = property + "Variance";
		}

		var node = config.node.resolve(getNodeName(property, config));
		var varianceNode = config.node.resolve(getNodeName(propertyVariance, config));

		var min = Std.parseFloat(node.att.value);
		var variance = Std.parseFloat(varianceNode.att.value);

		return {
			min: min - variance,
			max: min + variance
		};
	}

	static function xy(property:String, config:Access):{x:Float, y:Float}
	{
		var node = config.node.resolve(getNodeName(property, config));

		return {
			x: Std.parseFloat(node.att.x),
			y: Std.parseFloat(node.att.y)
		};
	}

	static function color(property:String, config:Access):{minColor:FlxColor, maxColor:FlxColor}
	{
		var node = config.node.resolve(getNodeName(property, config));
		var varianceNode = config.node.resolve(getNodeName(property + "Variance", config));

		var minR = Std.parseFloat(node.att.red);
		var minG = Std.parseFloat(node.att.green);
		var minB = Std.parseFloat(node.att.blue);
		var minA = Std.parseFloat(node.att.alpha);

		var varR = Std.parseFloat(varianceNode.att.red);
		var varG = Std.parseFloat(varianceNode.att.green);
		var varB = Std.parseFloat(varianceNode.att.blue);
		var varA = Std.parseFloat(varianceNode.att.alpha);

		return {
			minColor: FlxColor.fromRGBFloat(minR - varR, minG - varG, minB - varB, minA - varA),
			maxColor: FlxColor.fromRGBFloat(minR + varR, minG + varG, minB + varB, minA + varA)
		};
	}

	static inline function getNodeName(property:String, config:Access):String
	{
		// for backwards compatibility, check for versions of properties that
		// start with either lower or upper case
		return config.hasNode.resolve(property) ? property : (property.substr(0, 1).toUpperCase() + property.substr(1));
	}

	static function getAccessNode(data:Dynamic):Access
	{
		var str:String = "";
		var firstElement:Xml = null;

		// data embedded with @:file
		if ((data is Class))
		{
			str = Type.createInstance(data, []);
		}
		// data is a XML object
		else if ((data is Xml))
		{
			firstElement = data.firstElement();
		}
		// data is an ID or the content
		else if ((data is String))
		{
			// is the pexFile an ID to an asset or the content of the file?
			if (Assets.exists(data))
			{
				str = Assets.getText(data);
			}
			else
			{
				str = data;
			}
		}
		else
		{
			throw 'Unknown input data format. It has to be an ID to the assets file, a file embedded with @:file(), a string with the content of the file or a XML object.';
		}

		// the data wasn't a XML object.
		if (firstElement == null)
		{
			firstElement = Parser.parse(str).firstElement();
		}

		if (firstElement == null || firstElement.nodeName != "particleEmitterConfig")
		{
			throw 'The input data is incorrect.';
		}

		return new Access(firstElement);
	}
}

enum abstract PexEmitterType(Int) from Int
{
	var GRAVITY = 0;
	var RADIAL = 1;
}
