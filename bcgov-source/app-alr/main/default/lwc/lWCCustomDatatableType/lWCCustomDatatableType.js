/*
  @description       : created to use as a child LWC in showRegulatoryViolationRecords LWC to
                       use as a custom picklist datatype
  @author            : Komal Gupta
  @user story        : ALR-860
*/

import LightningDatatable from 'lightning/datatable';
import picklistColumn from './picklistColumn.html';
import pickliststatic from './pickliststatic.html'
 
export default class LWCCustomDatatableType extends LightningDatatable {
    static customTypes = {
        picklistColumn: {
            template: pickliststatic,
            editTemplate: picklistColumn,
            standardCellLayout: true,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'context', 'variant','name']
        }
    };
}