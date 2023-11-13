public class InputWrapper {
   
    public String elementName{get;set;}
	public String omniScriptId{get;set;}
	public List<AddUnitBlock> AddUnitBlock{get;set;}

	public class AddUnitBlock {
		public Integer NoOfUnits{get;set;}
		public String UnitCapacity{get;set;}
		public String UnitType{get;set;}
		public String Name{get;set;}
		public Object Status{get;set;}
		public String AccountId{get;set;}
	}

	
	public static InputWrapper parse(String json) {
		return (InputWrapper) System.JSON.deserialize(json, InputWrapper.class);
	}


}