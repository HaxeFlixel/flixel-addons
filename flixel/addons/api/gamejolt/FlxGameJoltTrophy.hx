package flixel.addons.api.gamejolt;

/**
 * The way the trophies are fetched from your game API.
 * 
 * @param id The ID of the Trophy.
 * @param title The title of the Trophy.
 * @param description The description of the Trophy.
 * @param difficulty The difficulty rank of the Trophy.
 * @param image_url The link of the image that represents the Trophy.
 * @param achieved Whether this Trophy was achieved or not, it can be a string if it was (with info about how much time ago it was achieved) or bool if not (false).
 */
typedef FlxGameJoltTrophy =
{
	id:Int,
	title:String,
	description:String,
	difficulty:String,
	image_url:String,
	achieved:String
}
