/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is for 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
                           ALR-33              ACN-ALR        View and Modify Residence Services details within Residence Class Record            
***********************************************************************************************/
public class InputWrapper {
   
    public String elementName{get;set;}
	public String omniScriptId{get;set;}
	public List<AddUnitBlock> AddUnitBlock{get;set;}

	public class AddUnitBlock {
		public Integer NoOfUnits{get;set;}
		public String UnitCapacity{get;set;}
		public String UnitType{get;set;}
		public String Name{get;set;}
		public string Status{get;set;}
		public String AccountId{get;set;}
        public String AmountValue{get;set;}
		public String Description{get;set;}
        public Boolean GenerateInvoiceValue{get;set;}
	}
}