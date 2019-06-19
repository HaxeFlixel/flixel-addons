package flixel.addons.display;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

/**
 * FlxGridOverlay
 *
 * @link http://www.photonstorm.com
 * @author Richard Davey / Photon Storm
 */
class FlxGridOverlay
{
	/**
	 * Creates a FlxSprite of the given width and height filled with a checkerboard pattern.
	 * Each grid cell is the specified width and height, and alternates between two colors.
	 * If alternate is true each row of the pattern will be offset, for a proper checkerboard style.
	 * If false each row will be the same colour, creating a striped-pattern effect.
	 * So to create an 8x8 grid you'd call create(8,8)
	 *
	 * @param	CellWidth		The grid cell width
	 * @param	CellHeight		The grid cell height
	 * @param	Width			The width of the FlxSprite. If -1 it will be the size of the game (FlxG.width)
	 * @param	Height			The height of the FlxSprite. If -1 it will be the size of the game (FlxG.height)
	 * @param	Alternate		Should the pattern alternate on each new row? Default true = checkerboard effect. False = vertical stripes
	 * @param	Color1			The first fill colour in 0xAARRGGBB format
	 * @param	Color2			The second fill colour in 0xAARRGGBB format
	 * @return	FlxSprite of given width/height
	 */
	public static function create(CellWidth:Int, CellHeight:Int, Width:Int = -1, Height:Int = -1, Alternate:Bool = true, Color1:FlxColor = 0xffe7e6e6,
			Color2:FlxColor = 0xffd9d5d5):FlxSprite
	{
		if (Width == -1)
		{
			Width = FlxG.width;
		}

		if (Height == -1)
		{
			Height = FlxG.height;
		}

		if (Width < CellWidth || Height < CellHeight)
		{
			return null;
		}

		var grid:BitmapData = createGrid(CellWidth, CellHeight, Width, Height, Alternate, Color1, Color2);

		var output = new FlxSprite();

		output.pixels = grid;
		output.dirty = true;

		return output;
	}

	/**
	 * Creates a checkerboard pattern of the given width/height and overlays it onto the given FlxSprite.
	 * Each grid cell is the specified width and height, and alternates between two colors.
	 * If alternate is true each row of the pattern will be offset, for a proper checkerboard style.
	 * If false each row will be the same colour, creating a striped-pattern effect.
	 * So to create an 8x8 grid you'd call create(8,8,
	 *
	 * @param	Sprite			The FlxSprite you wish to draw the grid on-top of. This updates its pixels value, not just the current frame (don't use animated sprites!)
	 * @param	CellWidth		The grid cell width
	 * @param	CellHeight		The grid cell height
	 * @param	Width			The width of the FlxSprite. If -1 it will be the size of the game (FlxG.width)
	 * @param	Height			The height of the FlxSprite. If -1 it will be the size of the game (FlxG.height)
	 * @param	Alternate		Should the pattern alternate on each new row? Default true = checkerboard effect. False = vertical stripes
	 * @param	Color1			The first fill colour in 0xAARRGGBB format
	 * @param	Color2			The second fill colour in 0xAARRGGBB format
	 * @return	The modified source FlxSprite
	 */
	public static function overlay(Sprite:FlxSprite, CellWidth:Int, CellHeight:Int, Width:Int = -1, Height:Int = -1, Alternate:Bool = true,
			Color1:FlxColor = 0x88e7e6e6, Color2:FlxColor = 0x88d9d5d5):FlxSprite
	{
		if (Width == -1)
		{
			Width = FlxG.width;
		}

		if (Height == -1)
		{
			Height = FlxG.height;
		}

		if (Width < CellWidth || Height < CellHeight)
		{
			return null;
		}

		var grid:BitmapData = createGrid(CellWidth, CellHeight, Width, Height, Alternate, Color1, Color2);
		Sprite.pixels.copyPixels(grid, new Rectangle(0, 0, Width, Height), new Point(0, 0), null, null, true);
		return Sprite;
	}

	public static function createGrid(CellWidth:Int, CellHeight:Int, Width:Int, Height:Int, Alternate:Bool, Color1:FlxColor, Color2:FlxColor):BitmapData
	{
		// How many cells can we fit into the width/height? (round it UP if not even, then trim back)
		var rowColor:Int = Color1;
		var lastColor:Int = Color1;
		var grid:BitmapData = new BitmapData(Width, Height, true);

		// If there aren't an even number of cells in a row then we need to swap the lastColor value
		var y:Int = 0;

		while (y <= Height)
		{
			if (y > 0 && lastColor == rowColor && Alternate)
			{
				(lastColor == Color1) ? lastColor = Color2 : lastColor = Color1;
			}
			else if (y > 0 && lastColor != rowColor && Alternate == false)
			{
				(lastColor == Color2) ? lastColor = Color1 : lastColor = Color2;
			}

			var x:Int = 0;

			while (x <= Width)
			{
				if (x == 0)
				{
					rowColor = lastColor;
				}

				grid.fillRect(new Rectangle(x, y, CellWidth, CellHeight), lastColor);

				if (lastColor == Color1)
				{
					lastColor = Color2;
				}
				else
				{
					lastColor = Color1;
				}

				x += CellWidth;
			}

			y += CellHeight;
		}

		return grid;
	}
}
