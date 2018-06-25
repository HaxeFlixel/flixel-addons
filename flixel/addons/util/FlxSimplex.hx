package flixel.addons.util;

/**
 * Simplex noise generation.
 * A combination of algorithms for very fast noise generation: http://weber.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf and http://www.google.com/patents/US6867776
 * @author MSGHero
 */
class FlxSimplex
{
	static inline var SKEW:Float = 0.3660254037; // 1 / (1 + sqrt(3))
	static inline var UNSKEW:Float = 0.2113248654; // 1 / (3 + sqrt(3))
	
	static var p:Array<Int> = [
		151,160,137,91,90,15,
		131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
		190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
		88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
		77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
		102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
		135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
		5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
		223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
		129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
		251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
		49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
		138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
		151,160,137,91,90,15,
		131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
		190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
		88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
		77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
		102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
		135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
		5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
		223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
		129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
		251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
		49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
		138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
	];
	
	static var i:Int;
	static var j:Int;
	
	static var u:Float;
	static var v:Float;
	
	static var A2_0:Int;
	static var A2_1:Int;
	
	/**
	 * Generates repeating simplex noise at a given frequency, which can be used for tiling.
	 * 
	 * @param   x 		The x coordinate at which the noise value should be obtained.
	 * @param   y 		The y coordinate at which the noise value should be obtained.
	 * @param   baseX 		How often the noise pattern repeats itself in the x direction, in pixels.
	 * @param   baseY 		How often the noise pattern repeats itself in the y direction, in pixels.
	 * @param   scale 		A multiplier that "zooms" into or out of the noise distribution. Smaller values zoom out.
	 * @param   persistence A multiplier that determines how much effect past octaves have. Typical values are 0 < x <= 1.
	 * @param   octaves 	The number of noise functions that get added together. Higher numbers provide more detail but take longer to run.
	 * @return  			The combined, repeating value of noise at the input coordinate, ranging from -1 to 1, inclusive.
	 */
	public static function simplexTiles(x:Float, y:Float, baseX:Float, baseY:Float, scale:Float = 1, persistence:Float = 1, octaves:Int = 1):Float
	{
		if (baseX <= 0 || baseY <= 0)
			throw "baseX and baseY must be greater than 0.";
		return Math.cos(simplexOctaves(x % Std.int(baseX), y % Std.int(baseY), scale, persistence, octaves));
	}
	
	/**
	 * Generates noise by combining multiple octaves of simplex noise at a given 2D coordinate.
	 * 
	 * @param   x 		The x coordinate at which the noise value should be obtained.
	 * @param   y 		The y coordinate at which the noise value should be obtained.
	 * @param   scale 		A multiplier that "zooms" into or out of the noise distribution. Smaller values zoom out.
	 * @param   persistence A multiplier that determines how much effect past octaves have. Typical values are 0 < x <= 1.
	 * @param   octaves 	The number of noise functions that get added together. Higher numbers provide more detail but take longer to run.
	 * @return  			The combined value of noise at the input coordinate, ranging from -1 to 1, inclusive.
	 */
	public static function simplexOctaves(x:Float, y:Float, scale:Float = 1, persistence:Float = 1, octaves:Int = 1):Float
	{
		if (octaves < 1)
			throw "The number of octaves must be greater than 0.";
		
		var max:Float = 0, amp:Float = 1, n:Float = 0;
		
		for (i in 0...octaves)
		{
			n += simplex(x * scale, y * scale) * amp;
			max += amp;
			amp *= persistence;
			scale *= 2;
		}
		
		return n / max;
	}
	
	/**
	 * Calculates the simplex noise at a given 2D coordinate.
	 * 
	 * @param   x The x coordinate at which the noise value should be obtained.
	 * @param   y The y coordinate at which the noise value should be obtained.
	 * @return  	The value of noise at the input coordinate, ranging from -1 to 1, inclusive.
	 */
	public static inline function simplex(x:Float, y:Float):Float
	{
		var t = (x + y) * SKEW;
		
		i = Math.floor(x + t);
		j = Math.floor(y + t);
		
		t = (i + j) * UNSKEW;
		
		u = x - i + t;
		v = y - j + t;
		
		var hi, lo;
		if (u > v)
		{
			hi = 1;
			lo = 0;
		}
		else
		{
			hi = 0;
			lo = 1;
		}
		
		A2_0 = A2_1 = 0;
		
		i = i & 0xff;
		j = j & 0xff;
		
		var out = 70 * (getCornerNoise(lo) + getCornerNoise(hi) + getCornerNoise(0));
		if (out < -1)
			return -1;
		if (out > 1)
			return 1;
		return out;
	}
	
	/**
	 * Private helper that finds the noise contribution of a single corner of a simplex cell.
	 *  
	 * @param   a Which corner to use
	 * @return	The noise value of the corner.
	 */
	static inline function getCornerNoise(a:Int):Float
	{
		var s = (A2_0 + A2_1) * UNSKEW;
		var x = u - A2_0 + s;
		var y = v - A2_1 + s;
		var t = .5 - x * x - y * y;
		
		var oA2_0 = A2_0;
		var oA2_1 = A2_1;
		
		if (a == 0)
			A2_0++;
		else
			A2_1++;
		
		if (t < 0)
			return 0;
		t *= t;
		
		var h = p[i + oA2_0 + p[j + oA2_1]] % 12;
		
		var b3 = h >> 3 & 0x01;
		var b2 = h >> 2 & 0x01;
		var b1 = h >> 1 & 0x01;
		var b0 = h & 0x01;
		
		x = b3 == 0 ? 0 : b0 == 1 ? -x : x;
		y = b3 == 1 ? b0 == 1 ? -y : y : b2 == 0 ? b1 == 1 ? -y : y : 0;
		
		return t * t * (x + y);
	}
}
