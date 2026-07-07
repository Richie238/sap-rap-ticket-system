@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true

@EndUserText: {
  label: 'Ticket Management'
}
@ObjectModel: {
  sapObjectNodeType.name: 'ZTICKET_ITEM_03'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_TICKET_ITEM_03
  provider contract transactional_query
  as projection on ZR_TICKET_ITEM_03
{
@Search.defaultSearchElement: true
@EndUserText.label: 'Ticket ID'
  key TicketID,
  
  @Search.defaultSearchElement: true
  @EndUserText.label: 'Subject'
  Subject,
  
@Search.defaultSearchElement: true
@EndUserText.label: 'Requester'
  RequesterID,
  
  AssignedTo,

@ObjectModel.text.element: [ 'PriorityText' ]
@Consumption.valueHelpDefinition: [{
  entity: { name: 'ZI_TICKET_PRIO_VH_03', element: 'Priority' },
  useForValidation: true
}]
Priority,
_Priority.PriorityText as PriorityText,

@ObjectModel.text.element: [ 'StatusText' ]
@Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_TICKET_STATUS_VH_03', element: 'Status' }, useForValidation: true }]
Status,
_Status.StatusText as StatusText,

@ObjectModel.text.element: [ 'CategoryText' ]
@Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_TICKET_CATEG_VH_03', element: 'Category' }, useForValidation: true }]
Category,
_Category.CategoryText as CategoryText,

  Description,
  DueDate,
  @Semantics: { user.createdBy: true }
  CreatedBy,
  @Semantics: { systemDateTime.createdAt: true }
  CreatedAt,
  @Semantics: { user.localInstanceLastChangedBy: true }
  LastChangedBy,
  @Semantics: { systemDateTime.localInstanceLastChangedAt: true }
  LocalLastChangedAt,
  @Semantics: { systemDateTime.lastChangedAt: true }
  LastChangedAt
}
