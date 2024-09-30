package flixel.addons.display;

import flixel.FlxSprite;
import flixel.addons.display.FlxPieDial;
import flixel.util.FlxColor;

#if !flash
/**
 * A dynamic shape that fills up radially (like a pie chart). Useful for timers and other things.
 * `FlxRadialGauge` uses `FlxRadialWipeShader` to fill the gauge portion, where `FlxPieDial`
 *  creates an animation. This also works with any graphic, unlike `FlxPieDial`
 * @since 5.9.0
 */
class FlxRadialGauge extends FlxSprite
{
	/** A value between 0.0 (empty) and 1.0 (full) */
	public var amount(get, set):Float;
	inline function get_amount():Float
	{
		return _sweepShader.amount;
	}
	inline function set_amount(value:Float):Float
	{
		return _sweepShader.amount = value;
	}
	
	/** The angle in degrees to start the dial fill */
	public var start(get, set):Float;
	inline function get_start():Float
	{
		return _sweepShader.start;
	}
	inline function set_start(value:Float):Float
	{
		return _sweepShader.start = value;
	}
	
	/** The angle in degrees to end the dial fill */
	public var end(get, set):Float;
	inline function get_end():Float
	{
		return _sweepShader.end;
	}
	inline function set_end(value:Float):Float
	{
		return _sweepShader.end = value;
	}
	
	var _sweepShader(get, never):FlxRadialWipeShader;
	inline function get__sweepShader() return cast shader;
	
	public function new(x = 0.0, y = 0.0, ?simpleGraphic)
	{
		super(x, y, simpleGraphic);
		
		shader = new FlxRadialWipeShader();
		this.amount = 1;
	}
	
	public function makeShapeGraphic(shape:FlxRadialGaugeShape, radius:Int, innerRadius = 0, color = FlxColor.WHITE)
	{
		final graphic = FlxPieDialUtils.getRadialGaugeGraphic(shape, radius, innerRadius, color);
		loadGraphic(graphic, true, radius * 2, radius * 2);
	}
	
	public function setOrientation(start = -90.0, end = 270.0)
	{
		this.start = start;
		this.end = end;
	}
}

typedef FlxRadialGaugeShape = FlxPieDialShape;

/**
 * A shader that masks a static sprite radially, based on the `start` and `end` angles
 */
class FlxRadialWipeShader extends flixel.system.FlxAssets.FlxShader
{
	/** The current fill amount, where `0.0` is empty and `1.0` is full */
	public var amount(get, set):Float;
	inline function get_amount():Float return _amount.value[0];
	inline function set_amount(value:Float):Float
	{
		_amount.value = [value];
		return value;
	}
	
	/** The angle in degrees to start the dial fill */
	public var start(get, set):Float;
	inline function get_start():Float return _start.value[0];
	inline function set_start(value:Float):Float
	{
		_start.value = [value];
		return value;
	}
	
	/** The angle in degrees to end the dial fill */
	public var end(get, set):Float;
	inline function get_end():Float return _end.value[0];
	inline function set_end(value:Float):Float
	{
		_end.value = [value];
		return value;
	}
	
	@:glFragmentSource('
		#pragma header
		
		const float TAU = 6.2831853072;
		
		uniform float _amount;
		uniform float _start;
		uniform float _end;
		
		float getGradiant(in vec2 dist)
		{
			float start = _start / 360.0;
			float delta = (_end - _start) / 360.0;
			float angle = atan(dist.y, dist.x) / TAU;
			if (_end > _start)
				return mod(angle - start, 1.0) / delta;
			else
				return mod(start - angle, 1.0) / -delta;
		}
		
		float wedge(in vec2 uv, in float ratio)
		{
			vec2 dist = uv - vec2(0.5);
			float grad = getGradiant(dist);
			return step(ratio, grad < 0.0 ? 1.0 : grad);
		}
		
		void main()
		{
			if (_amount > 0.0)
			{
				float amount = min(1.0, max(0.0, _amount));
				vec4 bitmap = flixel_texture2D(bitmap, openfl_TextureCoordv);
				gl_FragColor = mix(bitmap, vec4(0.0), wedge(openfl_TextureCoordv, amount));
			}
			else
				gl_FragColor = vec4(0.0);
		}')
	public function new()
	{
		super();
		amount = 1.0;
		start = -90;
		end = 270;
	}
}
#elseif FLX_NO_COVERAGE_TEST
#error "FlxRadialGauge is not supported on flash targets"
#end