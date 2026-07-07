@EndUserText.label : 'Draft Database Table for ZTCKET_ITEM_03_D'
@AbapCatalog.enhancement.category : #EXTENSIBLE_ANY
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table ztcket_item_03_d {

  key mandt          : mandt not null;
  key ticketid       : abap.numc(8) not null;
  subject            : abap.char(60);
  requesterid        : abap.char(10);
  assignedto         : abap.char(10);
  priority           : abap.char(1);
  status             : abap.char(1);
  category           : abap.char(2);
  description        : abap.char(255);
  duedate            : abap.dats;
  createdby          : abp_creation_user;
  createdat          : abp_creation_tstmpl;
  lastchangedby      : abp_locinst_lastchange_user;
  locallastchangedat : abp_locinst_lastchange_tstmpl;
  lastchangedat      : abp_lastchange_tstmpl;
  "%admin"           : include sych_bdl_draft_admin_inc;

}
