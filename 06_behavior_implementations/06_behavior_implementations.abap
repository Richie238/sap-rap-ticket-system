CLASS LHC_ZR_TICKET_ITEM_03 DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.

  CONSTANTS:
      BEGIN OF ticket_status,
      Offen TYPE c LENGTH 1 VALUE 'O',
      in_bearbeitung TYPE c LENGTH 1 VALUE 'B',
      GESCHLOSSEN TYPE C LENGTH 1 VALUE 'G',
      geloest TYPE c LENGTH 1 VALUE 'L',
      END OF ticket_status.

    METHODS:
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR ZrTicketItem03
        RESULT result,
      earlynumbering_create FOR NUMBERING
            IMPORTING entities FOR CREATE ZrTicketItem03,
      setStatusToOpen FOR DETERMINE ON MODIFY
            IMPORTING keys FOR ZrTicketItem03~setStatusToOpen.

          METHODS validateDueDate FOR VALIDATE ON SAVE
            IMPORTING keys FOR ZrTicketItem03~validateDueDate.

          METHODS validationAssigneTo FOR VALIDATE ON SAVE
            IMPORTING keys FOR ZrTicketItem03~validationAssigneTo.
ENDCLASS.

CLASS LHC_ZR_TICKET_ITEM_03 IMPLEMENTATION.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
  ENDMETHOD.
 METHOD earlynumbering_create.

  DATA max_ticket_id TYPE zticket_item_03-ticket_id.

  " Aktuell höchste Ticketnummer aus der Datenbank lesen
  SELECT SINGLE FROM zticket_item_03
    FIELDS MAX( ticket_id )
    INTO @max_ticket_id.

  " Entitäten übernehmen, bei denen bereits eine Ticket-ID vorhanden ist
 LOOP AT entities INTO DATA(entity) WHERE TicketID IS NOT INITIAL.
  APPEND CORRESPONDING #( entity ) TO mapped-ZrTicketItem03.
ENDLOOP.

  " Nur Entitäten ohne Ticket-ID weiterverarbeiten
  DATA(entities_wo_ticketid) = entities.
  DELETE entities_wo_ticketid WHERE TicketID IS NOT INITIAL.

  " Keine weitere Verarbeitung notwendig
  IF entities_wo_ticketid IS INITIAL.
    RETURN.
  ENDIF.

  " Neue Ticket-IDs vergeben
  LOOP AT entities_wo_ticketid INTO entity.

    " Aktuell höchste Ticketnummer um 1 erhöhen
    max_ticket_id += 1.

    " mapped-ZrTicketItem03 teilt RAP mit: "Für diese neu anzulegende Entität verwende diese TicketID."
    APPEND VALUE #(
      %cid     = entity-%cid
       %key      = entity-%key
       %is_draft = entity-%is_draft
      TicketID = max_ticket_id
    ) TO mapped-ZrTicketItem03.

  ENDLOOP.

ENDMETHOD.
  METHOD setStatusToOpen.

  MODIFY ENTITIES OF zr_ticket_item_03 IN LOCAL MODE
  ENTITY ZrTicketItem03
  UPDATE FIELDS ( Status )
  WITH VALUE #(

   FOR key IN keys (
   %tky = key-%tky
   Status = ticket_status-offen

    )

  ).


  ENDMETHOD.

  METHOD validateDueDate.

    READ ENTITIES OF zr_ticket_item_03 IN LOCAL MODE
    ENTITY ZrTicketItem03
    FIELDS ( AssignedTo )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_ticket).

    LOOP AT lt_ticket INTO DATA(ls_ticket).
      IF ls_ticket-AssignedTo IS INITIAL.

        APPEND VALUE #(
            " %tky ist der technische Schlüssel der aktuell geprüften RAP-Instanz.
            %tky = ls_ticket-%tky
            " failed verhindert das Speichern der Instanz.
        ) TO failed-zrticketitem03.

        APPEND VALUE #(
            %tky = ls_ticket-%tky
            %msg = new_message(
              id       = '00'
              number   = '001'
              severity = if_abap_behv_message=>severity-error
              v1       = 'Ticketsbearbeiter muss angegeben werden'
    )
  ) TO reported-ZrTicketItem03.

      ENDIF.

    ENDLOOP.


  ENDMETHOD.

  METHOD validationAssigneTo.

    READ ENTITIES OF zr_ticket_item_03 IN LOCAL MODE
    ENTITY ZrTicketItem03
    FIELDS ( DueDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_ticket).

    LOOP AT lt_ticket INTO DATA(ls_ticket).

      IF ls_ticket-DueDate IS INITIAL.
        APPEND VALUE #(
          %tky = ls_ticket-%tky
         ) TO failed-zrticketitem03.

        APPEND VALUE #(
        %tky = ls_ticket-%tky
        %msg = new_message(
        id = '00'
        number = '001'
        severity = if_abap_behv_message=>severity-error
        v1 = 'Bitte ein gültiges Fälligkeitsdatum eingeben.'

        )
        ) TO reported-zrticketitem03.

      ENDIF.

    ENDLOOP.


  ENDMETHOD.

ENDCLASS.
