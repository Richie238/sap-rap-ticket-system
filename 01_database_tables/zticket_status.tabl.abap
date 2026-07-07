@EndUserText.label : 'Ticket Status Texts'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zticket_status {

  key client  : abap.clnt not null;
  key status  : abap.char(1) not null;
  status_text : abap.char(30);

}
