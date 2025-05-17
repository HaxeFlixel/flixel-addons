package flixel.addons.api.gamejolt;

/**
 * A score fetched from the GameJolt server.
 */
typedef FlxGameJoltScore =
{
	/** The display text of the Score. */
	var score:String;
	
	/** The Score numerical value. */
	var sort:Int;
	
	/** If some extra data is attached to this Score, it'll be shown here. */
	var extra_data:String;
	
	/** The username of the User who achieved this Score, if it's a registered User. */
	@:optional var user:String;
	
	/** The user ID of the User who achieved this Score, if it's a registered User. */
	@:optional var user_id:Int;
	
	/** The name of the user who achieved this Score, if it's a guest user. */
	@:optional var guest:String;
	
	/** A short description about when the Score was achieved by the User or Guest. */
	var stored:String;
	
	/** A long time stamp (in seconds) of when the Score was achieved by the User or Guest. */
	var stored_timestamp:Int;
}
