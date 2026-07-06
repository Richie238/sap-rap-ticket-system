@EndUserText.label : 'Ticket Table'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zticket_item_03 {

  key client            : abap.clnt not null;
  key ticket_id         : abap.numc(8) not null;
  subject               : abap.char(60);
  requester_id          : abap.char(10);
  assigned_to           : abap.char(10);
  priority              : abap.char(1);
  status                : abap.char(1);
  category              : abap.char(2);
  description           : abap.char(255);
  due_date              : abap.dats;
  created_by            : abp_creation_user;
  created_at            : abp_creation_tstmpl;
  last_changed_by       : abp_locinst_lastchange_user;
  local_last_changed_at : abp_locinst_lastchange_tstmpl;
  last_changed_at       : abp_lastchange_tstmpl;

}
