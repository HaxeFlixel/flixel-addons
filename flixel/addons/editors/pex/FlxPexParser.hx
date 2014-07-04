package flixel.addons.editors.pex;

import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.FlxG;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import haxe.xml.Fast;
import openfl.Assets;
import openfl.display.BlendMode;

/**
 * Parser for Starling/Sparrow particle files created with http://onebyonedesign.com/flash/particleeditor/ 
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
	 * @param	pexFile			The pex file
	 * @param	particleGraphic	The particle graphic
	 * @return	A new emitter	
	 */
	public static function parse(pexFile:String, particleGraphic:FlxGraphicAsset):FlxEmitter
	{
		var emitter:FlxEmitter = new FlxEmitter();

		// Need to extract the particle graphic information
		var particle:FlxParticle = new FlxParticle();
		particle.loadGraphic(particleGraphic);
		
		var config:Fast = new Fast(Xml.parse(Assets.getText(pexFile)).firstElement());
		
		var emitterType = Std.parseInt(config.node.emitterType.att.value);
		if (emitterType != PexEmitterType.GRAVITY)
		{
			FlxG.log.warn("FlxPexParser: This emitter type isn't supported. Only 'Gravity' emitter type is supported.");
		}
		
		var maxParticles:Int = Std.parseInt(config.node.maxParticles.att.value);
		
		var lifespan = minMax("particleLifeSpan", "particleLifespanVariance", config);
		var speed = minMax("speed", config);
		
		var angle = minMax("angle", config);
		
		var startSize = minMax("startParticleSize", config);
		var finishSize = minMax("finishParticleSize", "FinishParticleSizeVariance", config);
		var rotationStart = minMax("rotationStart", config);
		var rotationEnd = minMax("rotationEnd", config);
		
		var radialAccel = minMax("radialAcceleration", "radialAccelVariance", config);
		var tangentialAccel = minMax("tangentialAcceleration", "tangentialAccelVariance", config);
		
		var sourcePositionVariance = xy("sourcePositionVariance", config);
		var gravity = xy("gravity", config);
		
		var startColors = color("startColor", config);
		var finishColors = color("finishColor", config);
		
		emitter.launchMode = FlxEmitterMode.CIRCLE;
		emitter.loadParticles(particleGraphic, maxParticles);
		
		emitter.width = sourcePositionVariance.x == 0 ? 1 : sourcePositionVariance.x * 2;
		emitter.height = sourcePositionVariance.y == 0 ? 1 : sourcePositionVariance.y * 2;
		
		emitter.lifespan.set(lifespan.min, lifespan.max);
		
		emitter.acceleration.set(gravity.x, gravity.y);		
		
		emitter.launchAngle.set(angle.min, angle.max);
		
		emitter.speed.start.set(speed.min, speed.max);
		emitter.speed.end.set(speed.min, speed.max);
		
		emitter.angle.set(rotationStart.min, rotationStart.max, rotationEnd.min, rotationEnd.max);
		
		emitter.scale.start.min.set(startSize.min / particle.frameWidth, startSize.min / particle.frameHeight);
		emitter.scale.start.max.set(startSize.max / particle.frameWidth, startSize.max / particle.frameHeight);
		emitter.scale.end.min.set(finishSize.min / particle.frameWidth, finishSize.min / particle.frameHeight);
		emitter.scale.end.max.set(finishSize.max / particle.frameWidth, finishSize.max / particle.frameHeight);
		
		emitter.alpha.set(startColors.minColor.alphaFloat, startColors.maxColor.alphaFloat, finishColors.minColor.alphaFloat, finishColors.maxColor.alphaFloat);
		emitter.color.set(startColors.minColor, startColors.maxColor, finishColors.minColor, finishColors.maxColor);
		
		emitter.blend = BlendMode.ADD;
		emitter.keepScaleRatio = true;
		return emitter;
	}
	
	private static function minMax(property:String, ?propertyVariance:String, config:Fast): { min:Float, max:Float } 
	{
		if (propertyVariance == null) 
		{
			propertyVariance = property + "Variance";
		}
		
		var node = config.node.resolve(property);
		var varianceNode = config.node.resolve(propertyVariance);
		
		var min = Std.parseFloat(node.att.value);
		var variance = Std.parseFloat(varianceNode.att.value);
		
		return 
		{ 
			min: min - variance, 
			max: min + variance 
		};
	}
	
	private static function xy(property:String, config:Fast): { x:Float, y:Float }
	{
		var node = config.node.resolve(property);
		
		return 
		{
			x: Std.parseFloat(node.att.x),
			y: Std.parseFloat(node.att.y)
		};
	}
	
	private static function color(property:String, config:Fast): { minColor:FlxColor, maxColor:FlxColor }
	{
		var node = config.node.resolve(property);
		var varianceNode = config.node.resolve(property + "Variance");
		
		var minR = Std.parseFloat(node.att.red);
		var minG = Std.parseFloat(node.att.green);
		var minB = Std.parseFloat(node.att.blue);
		var minA = Std.parseFloat(node.att.alpha);
		
		var varR = Std.parseFloat(varianceNode.att.red);
		var varG = Std.parseFloat(varianceNode.att.green);
		var varB = Std.parseFloat(varianceNode.att.blue);
		var varA = Std.parseFloat(varianceNode.att.alpha);
		
		return 
		{
			minColor: FlxColor.fromRGBFloat(minR - varR, minG - varG, minB - varB, minA - varA),
			maxColor: FlxColor.fromRGBFloat(minR + varR, minG + varG, minB + varB, minA + varA)
		};
	}
}

@:enum
abstract PexEmitterType(Int) from Int
{
	var GRAVITY = 0;
	var RADIAL = 1;
}