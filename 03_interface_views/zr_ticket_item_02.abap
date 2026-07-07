@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZTICKET_ITEM_03'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_TICKET_ITEM_03
  as select from zticket_item_03

  association [1..1] to ZI_TICKET_PRIO_VH_03 as _Priority on $projection.Priority = _Priority.Priority
  association [1..1] to ZI_TICKET_STATUS_VH_03 as _Status on $projection.Status = _Status.Status
  association [1..1] to ZI_TICKET_CATEG_VH_03 as _Category on $projection.Category = _Category.Category

{
  key ticket_id as TicketID,
  subject as Subject,
  requester_id as RequesterID,
  assigned_to as AssignedTo,
  priority as Priority,
  
  case priority
  when '1' then 3  // Grün / Positive
  when '2' then 2  // Gelb / Critical
  when '3' then 2  // Gelb / Critical
  when '4' then 1  // Rot / Negative
  else 0
end as PriorityCriticality,
  
  status as Status,
  category as Category,
  description as Description,
  due_date as DueDate,
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  last_changed_by as LastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt,

  _Priority,
  _Status,
  _Category
}
