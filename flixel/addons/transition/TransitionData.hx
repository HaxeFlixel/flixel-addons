package flixel.addons.transition;

/**
 * ...
 * @author larsiusprime
 */
class TransitionData
{
	//public var type:TransitionType;
	public var asset:String = "";
	
	public function new(Asset:String=null) 
	{
		asset = Asset;
		if (asset == null)
		{
			asset = "assets/images/transitions/diamond.png";
		}
	}
	
}

/*enum TransitionType {
	
}*/