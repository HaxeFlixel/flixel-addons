package flixel.addons.tile;

import flixel.math.FlxRandom;

/**
 * This class uses the cellular automata algorithm
 * to generate very sexy caves.
 * (Coded by Eddie Lee, October 16, 2010)
 */
class FlxCaveGenerator
{
	/**
	 * Convert a matrix generated via generateCaveMatrix() into data
	 * that is usable by FlxTilemap.
	 *
	 * @param 	Matrix		A matrix of data
	 * @return 	A string that is usuable for FlxTilemap.loadMap()
	 */
	public static function convertMatrixToString(Matrix:Array<Array<Int>>):String
	{
		var mapString:String = "";

		for (y in 0...Matrix.length)
		{
			for (x in 0...Matrix[y].length)
			{
				mapString += Std.string(Matrix[y][x]) + ",";
			}

			mapString += "\n";
		}

		return mapString;
	}

	/**
	 * Generate the matrix (2-dimensional array of Ints) for a cave.
	 *
	 * @param	Columns 				Number of columns for the matrix
	 * @param	Rows					Number of rows for the matrix
	 * @param	SmoothingIterations 	How many times do you want to "smooth" the caev - the higher the smoother, but slower
	 * @param	WallRatio 				Chance for a tile to become a wall - the closer the value is to 1.0, the more walls there are
	 * @return	Returns a matrix of a cave!
	 */
	public static function generateCaveMatrix(Columns:Int, Rows:Int, SmoothingIterations:Int = 6, WallRatio:Float = 0.5):Array<Array<Int>>
	{
		// Initialize random array
		var matrix:Array<Array<Int>> = generateInitialMatrix(Columns, Rows);

		for (y in 0...Rows)
		{
			for (x in 0...Columns)
			{
				matrix[y][x] = (FlxG.random.float() < WallRatio ? 1 : 0);
			}
		}

		// Secondary buffer
		var matrix2:Array<Array<Int>> = generateInitialMatrix(Columns, Rows);

		// Run automata
		for (i in 0...SmoothingIterations)
		{
			runCelluarAutomata(matrix, matrix2);

			// Swap
			var temp:Array<Array<Int>> = matrix;
			matrix = matrix2;
			matrix2 = temp;
		}

		return matrix;
	}

	/**
	 * Generates a new cave matrix via generateCaveMatrix() and returns it in a format
	 * usable by FlxTilemap.load() via convertMatrixToString().
	 *
	 * @param	Columns 				Number of columns for the matrix
	 * @param	Rows					Number of rows for the matrix
	 * @param	SmoothingIterations 	How many times do you want to "smooth" the caev - the higher the smoother, but slower
	 * @param	WallRatio 				Chance for a tile to become a wall - the closer the value is to 1.0, the more walls there are
	 * @return	A cave string that is usable by FlxTilemap.loadMap()
	 */
	public static inline function generateCaveString(Columns:Int, Rows:Int, SmoothingIterations:Int = 6, WallRatio:Float = 0.5):String
	{
		return convertMatrixToString(generateCaveMatrix(Columns, Rows, SmoothingIterations, WallRatio));
	}

	/**
	 * Creates a matrix (2-dimensional array of Ints) of an empty cave consisting of zeros only.
	 *
	 * @param	Columns 	Number of columns for the matrix
	 * @param	Rows		Number of rows for the matrix
	 * @return 	Spits out a matrix that is columns * rows big, initiated with zeros
	 */
	static function generateInitialMatrix(Columns:Int, Rows:Int):Array<Array<Int>>
	{
		var matrix:Array<Array<Int>> = new Array<Array<Int>>();

		for (y in 0...Rows)
		{
			matrix.push(new Array<Int>());

			for (x in 0...Columns)
			{
				matrix[y].push(0);
			}
		}

		return matrix;
	}

	/**
	 * @param	Matrix		Matrix of data (0 = empty, 1 = wall)
	 * @param	PosX		Column we are examining
	 * @param	PosY		Row we are exampining
	 * @param	Distance	Radius of how far to check for neighbors
	 * @return	Number of walls around the target, including itself
	 */
	static function countNumWallsNeighbors(Matrix:Array<Array<Int>>, PosX:Int, PosY:Int, Distance:Int = 1):Int
	{
		var count:Int = 0;
		var rows:Int = Matrix.length;
		var columns:Int = Matrix[0].length;

		for (y in (-Distance)...(Distance + 1))
		{
			for (x in (-Distance)...(Distance + 1))
			{
				// Boundary
				if ((PosX + x < 0) || (PosX + x > columns - 1) || (PosY + y < 0) || (PosY + y > rows - 1))
				{
					continue;
				}

				// Neighbor is non-wall
				if (Matrix[PosY + y][PosX + x] != 0)
				{
					count++;
				}
			}
		}

		return count;
	}

	/**
	 * Use the 4-5 rule to smooth cells
	 */
	static function runCelluarAutomata(InMatrix:Array<Array<Int>>, OutMatrix:Array<Array<Int>>):Void
	{
		var rows:Int = InMatrix.length;
		var columns:Int = InMatrix[0].length;

		for (y in 0...rows)
		{
			for (x in 0...columns)
			{
				var numWalls:Int = countNumWallsNeighbors(InMatrix, x, y, 1);

				if (numWalls >= 5)
				{
					OutMatrix[y][x] = 1;
				}
				else
				{
					OutMatrix[y][x] = 0;
				}
			}
		}
	}
}
