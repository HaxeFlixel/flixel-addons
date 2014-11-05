package flixel.addons.display.shapes;

/**
 * 
 * @author larsiusprime
 */

abstract FlxShapeType(String) from String to String
{
	public static inline var ARROW:String = "arrow";
	public static inline var BOX:String = "box";
	public static inline var CIRCLE:String = "circle";
	public static inline var CROSS:String = "cross";
	public static inline var DONUT:String = "donut";
	public static inline var DOUBLE_CIRCLE:String = "double_circle";
	public static inline var GRID:String = "grid";
	public static inline var LIGHTNING:String = "lightning";
	public static inline var LINE:String = "line";
	public static inline var SQUARE_DONUT:String = "square_donut";
	public static inline var UNKNOWN:String = "unknown";
	
	public function new(Value:String = "")
	{
		trace("Value = " + Value);
		if (Value == null)
		{
			Value = "";
		}
		Value = Value.toLowerCase();
		var etc = ["_", "-", " "];
		for (s in etc)
		{
			while (Value.indexOf(s) != -1)
			{
				Value = StringTools.replace(Value, s, "");
			}
		}
		this = switch(Value)
		{
			case "arrow": ARROW;
			case "box","square": BOX;
			case "circle": CIRCLE;
			case "cross": CROSS;
			case "donut": DONUT;
			case "doublecircle": DOUBLE_CIRCLE;
			case "grid": GRID;
			case "lightning": LIGHTNING;
			case "line": LINE;
			case "squaredonut": SQUARE_DONUT;
			default: UNKNOWN;
		}
		trace("this = " + this);
	}
	
	public function toUpperCase():String
	{
		return this.toUpperCase();
	}
	
	public static inline function fromString(Value:String):FlxShapeType
	{
		return new FlxShapeType(Value);
	}
}