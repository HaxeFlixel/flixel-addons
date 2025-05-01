package flixel.addons.api.gamejolt;

/**
 * The way the scores are fetched from your game API.
 * 
 * @param score The display text of the Score.
 * @param sort The Score value.
 * @param extra_data If some extra data is attached to this Score, it'll be shown here.
 * @param user The username of the User who achieved this Score, if it's a registered User.
 * @param user_id The user ID of the User who achieved this Score, if it's a registered User.
 * @param guest The name of the user who achieved this Score, if it's a guest user.
 * @param stored A short description about when the Score was achieved by the User or Guest.
 * @param stored_timestamp A long time stamp (in seconds) of when the Score was achieved by the User or Guest.
 */
typedef FlxGameJoltScore =
{
	score:String,
	sort:Int,
	extra_data:String,
	user:String,
	user_id:Int,
	guest:String,
	stored:String,
	stored_timestamp:Int
}
