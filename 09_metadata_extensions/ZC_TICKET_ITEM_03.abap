@Metadata.layer: #CORE
@UI.headerInfo: {
  typeName: 'Ticket',
  typeNamePlural: 'Tickets',
  title: {
    type: #STANDARD,
    value: 'Subject'
  },
  description: {
    value: 'TicketID'
  }
}
annotate view ZC_TICKET_ITEM_03 with
{
  @EndUserText.label: 'Ticketnummer'
  @UI.facet: [ {
    id: 'GeneralInfo',
    purpose: #STANDARD,
    type: #IDENTIFICATION_REFERENCE,
    label: 'Allgemeine Informationen',
    position: 10
  } ]
  @UI.identification: [ { position: 10, label: 'Ticketnummer' } ]
  @UI.lineItem: [ { position: 10, label: 'Ticketnummer' } ]
  @UI.selectionField: [ { position: 10 } ]
  TicketID;

  @EndUserText.label: 'Betreff'
  @UI.identification: [ { position: 20, label: 'Betreff' } ]
  @UI.lineItem: [ { position: 20, label: 'Betreff' } ]
  @UI.selectionField: [ { position: 20 } ]
  Subject;

  @EndUserText.label: 'Anforderer'
  @UI.identification: [ { position: 30, label: 'Anforderer' } ]
  @UI.lineItem: [ { position: 30, label: 'Anforderer' } ]
  @UI.selectionField: [ { position: 30 } ]
  RequesterID;

  @EndUserText.label: 'Bearbeiter'
  @UI.identification: [ { position: 40, label: 'Bearbeiter' } ]
  @UI.lineItem: [ { position: 40, label: 'Bearbeiter' } ]
  @UI.selectionField: [ { position: 40 } ]
  AssignedTo;

  @EndUserText.label: 'Priorität'
  @UI.identification: [ { position: 50, label: 'Priorität' } ]
  @UI.lineItem: [ { position: 50, label: 'Priorität' } ]
  @UI.selectionField: [ { position: 50 } ]
  Priority;

  @EndUserText.label: 'Status'
  @UI.identification: [ { position: 60, label: 'Status' } ]
  @UI.lineItem: [ { position: 60, label: 'Status' } ]
  @UI.selectionField: [ { position: 60 } ]
  Status;

  @EndUserText.label: 'Kategorie'
  @UI.identification: [ { position: 70, label: 'Kategorie' } ]
  @UI.lineItem: [ { position: 70, label: 'Kategorie' } ]
  @UI.selectionField: [ { position: 70 } ]
  Category;

  @EndUserText.label: 'Beschreibung'
  @UI.identification: [ { position: 80, label: 'Beschreibung' } ]
  @UI.lineItem: [ { position: 80, label: 'Beschreibung' } ]
  Description;

  @EndUserText.label: 'Fälligkeitsdatum'
  @UI.identification: [ { position: 90, label: 'Fälligkeitsdatum' } ]
  @UI.lineItem: [ { position: 90, label: 'Fälligkeitsdatum' } ]
  @UI.selectionField: [ { position: 90 } ]
  DueDate;

  @EndUserText.label: 'Erstellt von'
  @UI.identification: [ { position: 100, label: 'Erstellt von' } ]
  CreatedBy;

  @EndUserText.label: 'Erstellt am'
  @UI.identification: [ { position: 110, label: 'Erstellt am' } ]
  CreatedAt;

  @EndUserText.label: 'Geändert von'
  @UI.identification: [ { position: 120, label: 'Geändert von' } ]
  LastChangedBy;

  @EndUserText.label: 'Lokal geändert am'
  @UI.identification: [ { position: 130, label: 'Lokal geändert am' } ]
  LocalLastChangedAt;

  @EndUserText.label: 'Zuletzt geändert am'
  @UI.identification: [ { position: 140, label: 'Zuletzt geändert am' } ]
  LastChangedAt;
}
