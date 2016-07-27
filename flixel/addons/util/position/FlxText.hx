package flixel.addons.util.position;

/**
 * A FlxPostion-compatible FlxText
 */

class FlxText extends flixel.text.FlxText {

	public function new(X:Float=0, Y:Float=0, FieldWidth:Float=0, ?Text:String, Size:Int=8, EmbeddedFont:Bool=true) {
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}
	
	override function get_width():Float {
		return fieldWidth;
	}
	
	override function get_height():Float {
		return textField.height;
	}
	
}