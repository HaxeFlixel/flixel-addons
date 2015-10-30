package flixel.addons.effects;
import openfl.display.BitmapData;
import openfl.geom.Point;

interface IFlxEffect
{
	public var active:Bool;
	public var offset:Point;
	public function destroy():Void;
	public function update(elapsed:Float):Void;
	public function apply(bitmapData:BitmapData):BitmapData;
}