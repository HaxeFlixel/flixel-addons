package flixel.addons.api.gamejolt;

/**
 * A score table fetched from the GameJolt server.
 */
typedef FlxGameJoltScoreTable =
{
	/** The ID of the Score Table. */
	var id:Int;
	
	/** The name of the Score Table. */
	var name:String;
	
	/** The description of the Score Table. */
	var description:String;
	
	/** Whether if this is the Primary Score Table in your game (1) or not (0). */
	var primary:Int;
}
