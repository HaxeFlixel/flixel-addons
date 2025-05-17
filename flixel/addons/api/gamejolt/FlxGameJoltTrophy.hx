package flixel.addons.api.gamejolt;

/**
 * A trophy fetched from the GameJolt server.
 */
typedef FlxGameJoltTrophy =
{
	/** The ID of the Trophy. */
	var id:Int;
	
	/** The title of the Trophy- */
	var title:String;
	
	/** The description of the Trophy. */
	var description:String;
	
	/** The difficulty rank of the Trophy. */
	var difficulty:String;
	
	/** The link of the image that represents the Trophy. */
	var image_url:String;
	
	/** Whether this Trophy was achieved or not, it can be a string if it was (with info about how much time ago it was achieved) or bool if not (false). */
	var achieved:String;
}
