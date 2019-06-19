package flixel.addons.util;

/**
 * Simplex noise generation.
 * A combination of algorithms for very fast noise generation: http://weber.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf, http://www.google.com/patents/US6867776, and http://www.jgallant.com/procedurally-generating-wrapping-world-maps-in-unity-csharp-part-2/#wrap2.
 * @author MSGHero
 */
class FlxSimplex
{
	static inline var SKEW:Float = 0.3660254037; // 1 / (1 + sqrt(3))
	static inline var UNSKEW:Float = 0.2113248654; // 1 / (3 + sqrt(3))

	static inline var SKEW_4D:Float = 0.309016994; // 1 / (1 + sqrt(5))
	static inline var UNSKEW_4D:Float = 0.138196601; // 1 / (5 + sqrt(5))

	static var p:Array<Int> = [
		151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120,
		234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71,
		134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161,
		1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250,
		124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44,
		154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228, 251,
		34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176,
		115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180, 151, 160, 137, 91, 90,
		15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62,
		94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166, 77,
		146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76,
		132, 187, 208, 89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202, 38, 147,
		118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153,
		101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228, 251, 34, 242, 193, 238, 210,
		144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4,
		150, 254, 138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180
	];

	static var cells4D:Array<SimplexCell> = [
		[3, 2, 1, 0], [2, 3, 1, 0], [0, 0, 0, 0], [2, 1, 3, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [2, 1, 0, 3],
		[3, 1, 2, 0], [0, 0, 0, 0], [1, 3, 2, 0], [1, 2, 3, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [1, 2, 0, 3],
		[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0],
		[3, 1, 0, 2], [0, 0, 0, 0], [1, 3, 0, 2], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [1, 0, 3, 2], [1, 0, 2, 3],
		[3, 2, 0, 1], [2, 3, 0, 1], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [2, 0, 3, 1], [0, 0, 0, 0], [2, 0, 1, 3],
		[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0],
		[3, 0, 2, 1], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 3, 2, 1], [0, 2, 3, 1], [0, 0, 0, 0], [0, 2, 1, 3],
		[3, 0, 1, 2], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 3, 1, 2], [0, 0, 0, 0], [0, 1, 3, 2], [0, 1, 2, 3]
	];

	static var i:Int;
	static var j:Int;
	static var k:Int;
	static var l:Int;

	static var x0:Float;
	static var y0:Float;
	static var z0:Float;
	static var w0:Float;

	static var A2:SimplexCell = [0, 0, 0, 0];

	/**
	 * Generates repeating simplex noise at a given frequency, which can be used for tiling.
	 * Note: simplexTiles is more expensive than simplexOctaves. Generate one tile and copy it around instead of calling this function for every pixel.
	 *
	 * @param   x 			The x coordinate at which the noise value should be obtained.
	 * @param   y 			The y coordinate at which the noise value should be obtained.
	 * @param   baseX 		How often the noise pattern repeats itself in the x direction, in pixels.
	 * @param   baseY 		How often the noise pattern repeats itself in the y direction, in pixels.
	 * @param   seed 		A random number used to vary the tiling pattern, even if all other parameters are the same.
	 * @param   scale 		A multiplier that "zooms" into or out of the noise distribution. Smaller values zoom out.
	 * @param   persistence	A multiplier that determines how much effect past octaves have. Typical values are 0 < x <= 1.
	 * @param   octaves 	The number of noise functions that get added together. Higher numbers provide more detail but take longer to run.
	 * @return  			The combined, repeating value of noise at the input coordinate, ranging from -1 to 1, inclusive.
	 */
	public static function simplexTiles(x:Float, y:Float, baseX:Float, baseY:Float, seed:Float, scale:Float = 1, persistence:Float = 1, octaves:Int = 1):Float
	{
		if (baseX <= 0 || baseY <= 0)
			throw "baseX and baseY must be greater than 0.";

		if (octaves < 1)
			throw "The number of octaves must be greater than 0.";

		var xx = x / baseX * 2 * Math.PI, yy = y / baseY * 2 * Math.PI;
		var xtile = Std.int(x / baseX) * baseX;
		var ytile = Std.int(y / baseY) * baseY;

		var nx = Math.cos(xx) * baseX / Math.PI;
		var ny = Math.cos(yy) * baseY / Math.PI;
		var nz = Math.sin(xx) * baseX / Math.PI;
		var nw = Math.sin(yy) * baseY / Math.PI;

		var max:Float = 0, amp:Float = 1, n:Float = 0;

		for (i in 0...octaves)
		{
			n += simplex4D(seed + nx * scale, seed + ny * scale, seed + nz * scale, seed + nw * scale) * amp;
			max += amp;
			amp *= persistence;
			scale *= 2;
		}

		return n / max;
	}

	/**
	 * Generates noise by combining multiple octaves of simplex noise at a given 2D coordinate.
	 *
	 * @param   x 			The x coordinate at which the noise value should be obtained.
	 * @param   y 			The y coordinate at which the noise value should be obtained.
	 * @param   scale 		A multiplier that "zooms" into or out of the noise distribution. Smaller values zoom out.
	 * @param   persistence 	A multiplier that determines how much effect past octaves have. Typical values are 0 < x <= 1.
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
	 * @param   x	The x coordinate at which the noise value should be obtained.
	 * @param   y 	The y coordinate at which the noise value should be obtained.
	 * @return  	The value of noise at the input coordinate, ranging from -1 to 1, inclusive.
	 */
	public static inline function simplex(x:Float, y:Float):Float
	{
		var t = (x + y) * SKEW;

		i = Math.floor(x + t);
		j = Math.floor(y + t);

		t = (i + j) * UNSKEW;

		x0 = x - i + t;
		y0 = y - j + t;

		var hi, lo;
		if (x0 > y0)
		{
			hi = 1;
			lo = 0;
		}
		else
		{
			hi = 0;
			lo = 1;
		}

		A2.x = A2.y = 0;

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
	 * @param   a 	Which corner to use.
	 * @return	The noise value of the corner.
	 */
	static inline function getCornerNoise(a:Int):Float
	{
		var s = (A2.x + A2.y) * UNSKEW;
		var x = x0 - A2.x + s;
		var y = y0 - A2.y + s;
		var t = .5 - x * x - y * y;

		var a2x = A2.x, a2y = A2.y;

		A2[a]++;

		if (t < 0)
			return 0;

		t *= t;

		var h = p[i + a2x + p[j + a2y]] % 12;

		var b3 = (h >> 3 & 0x01) == 1;
		var b2 = (h >> 2 & 0x01) == 1;
		var b1 = (h >> 1 & 0x01) == 1;
		var b0 = (h & 0x01) == 1;

		x = !b3 ? b0 ? -x : x : 0;
		y = !b3 ? !b2 ? !b1 ? y : -y : 0 : !b0 ? y : -y;

		return t * t * (x + y);
	}

	/**
	 * Calculates the simplex noise at a given 4D coordinate.
	 * Used internally to generate tileable 2D noise, but it might as well be public.
	 *
	 * @param   x	The x coordinate at which the noise value should be obtained.
	 * @param   y 	The y coordinate at which the noise value should be obtained.
	 * @param   z	The z coordinate at which the noise value should be obtained.
	 * @param   w 	The w coordinate at which the noise value should be obtained.
	 * @return  	The value of noise at the input coordinate, ranging from -1 to 1, inclusive.
	 */
	public static inline function simplex4D(x:Float, y:Float, z:Float, w:Float):Float
	{
		var t = (x + y + z + w) * SKEW_4D;

		i = Math.floor(x + t);
		j = Math.floor(y + t);
		k = Math.floor(z + t);
		l = Math.floor(w + t);

		t = (i + j + k + l) * UNSKEW_4D;

		x0 = x - i + t;
		y0 = y - j + t;
		z0 = z - k + t;
		w0 = w - l + t;

		var c0 = x0 > y0 ? 32 : 0;
		var c1 = x0 > z0 ? 16 : 0;
		var c2 = y0 > z0 ? 8 : 0;
		var c3 = x0 > w0 ? 4 : 0;
		var c4 = y0 > w0 ? 2 : 0;
		var c5 = z0 > w0 ? 1 : 0;

		var cell = cells4D[c0 + c1 + c2 + c3 + c4 + c5];

		A2.x = A2.y = A2.z = A2.w = 0;

		i = i & 0xff;
		j = j & 0xff;
		k = k & 0xff;
		l = l & 0xff;

		var out = 27 * (getCornerNoise4D(cell[0])
			+ getCornerNoise4D(cell[1])
			+ getCornerNoise4D(cell[2])
			+ getCornerNoise4D(cell[3])
			+ getCornerNoise4D(0));

		if (out < -1)
			return -1;
		if (out > 1)
			return 1;
		return out;
	}

	/**
	 * Private helper that finds the noise contribution of a single corner of a 4D simplex cell.
	 *
	 * @param   a 	Which corner to use next.
	 * @return	The noise value of the corner.
	 */
	static inline function getCornerNoise4D(a:Int):Float
	{
		var s = (A2.x + A2.y + A2.z + A2.w) * UNSKEW_4D;
		var x = x0 - A2.x + s;
		var y = y0 - A2.y + s;
		var z = z0 - A2.z + s;
		var w = w0 - A2.w + s;
		var t = .6 - x * x - y * y - z * z - w * w;

		var a2x = A2.x, a2y = A2.y, a2z = A2.z, a2w = A2.w;

		A2[a]++;

		if (t < 0)
			return 0;

		t *= t;

		var h = p[i + a2x + p[j + a2y + p[k + a2z + p[l + a2w]]]] % 32;

		var b4 = (h >> 4 & 0x01) == 1;
		var b3 = (h >> 3 & 0x01) == 1;
		var b2 = (h >> 2 & 0x01) == 1;
		var b1 = (h >> 1 & 0x01) == 1;
		var b0 = (h & 0x01) == 1;

		x = !b3 ? 0 : !b2 ? x : -x;
		y = !b4 ? b3 ? 0 : !b2 ? y : -y : !b1 ? y : -y;
		z = b4 ? !b3 ? 0 : !b0 ? z : -z : !b1 ? z : -z;
		w = b4 && b3 ? 0 : !b0 ? w : -w;

		return t * t * (x + y + z + w);
	}
}

@:arrayAccess
private abstract SimplexCell(Array<Int>) from Array<Int>
{
	public var x(get, set):Int;

	inline function get_x():Int
	{
		return this[0];
	}

	inline function set_x(i:Int):Int
	{
		return this[0] = i;
	}

	public var y(get, set):Int;

	inline function get_y():Int
	{
		return this[1];
	}

	inline function set_y(i:Int):Int
	{
		return this[1] = i;
	}

	public var z(get, set):Int;

	inline function get_z():Int
	{
		return this[2];
	}

	inline function set_z(i:Int):Int
	{
		return this[2] = i;
	}

	public var w(get, set):Int;

	inline function get_w():Int
	{
		return this[3];
	}

	inline function set_w(i:Int):Int
	{
		return this[3] = i;
	}

	public function new(ab:Array<Int>)
	{
		this = ab;
	}
}
