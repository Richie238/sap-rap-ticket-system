CLASS LHC_ZR_TICKET_ITEM_03000 DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR ZrTicketItem03000
        RESULT result.

    METHODS setStatusToOpen FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ZrTicketItem03000~setStatusToOpen.
    METHODS validateAssignedTo FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZrTicketItem03000~validateAssignedTo.
    METHODS validateDueDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZrTicketItem03000~validateDueDate.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR ZrTicketItem03000 RESULT result.

    TYPES ticket_read_keys TYPE TABLE FOR READ IMPORT ZR_TICKET_ITEM_03000.
    TYPES ticket_read_result TYPE TABLE FOR READ RESULT ZR_TICKET_ITEM_03000.
    METHODS get_closable_tickets
      IMPORTING keys TYPE ticket_read_keys
      RETURNING VALUE(tickets) TYPE ticket_read_result.

    METHODS closeTicket FOR MODIFY
      IMPORTING keys FOR ACTION ZrTicketItem03000~closeTicket RESULT result.
ENDCLASS.

CLASS LHC_ZR_TICKET_ITEM_03000 IMPLEMENTATION.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
  ENDMETHOD.

  METHOD setStatusToOpen.
    CONSTANTS status_open TYPE zticket_item_03-status VALUE 'O'.

    READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY ZrTicketItem03000
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(tickets).

    DELETE tickets WHERE Status IS NOT INITIAL.
    IF tickets IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY ZrTicketItem03000
        UPDATE FIELDS ( Status )
        WITH VALUE #( FOR ticket IN tickets
          ( %tky = ticket-%tky Status = status_open ) ).
  ENDMETHOD.

  METHOD validateAssignedTo.
    READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY ZrTicketItem03000
        FIELDS ( AssignedTo )
        WITH CORRESPONDING #( keys )
      RESULT DATA(tickets).

    LOOP AT tickets INTO DATA(ticket).
      IF ticket-AssignedTo IS INITIAL.
        APPEND VALUE #( %tky = ticket-%tky ) TO failed-ZrTicketItem03000.
        APPEND VALUE #(
          %tky = ticket-%tky
          %element-AssignedTo = if_abap_behv=>mk-on
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Geben Sie einen Bearbeiter an.' )
        ) TO reported-ZrTicketItem03000.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateDueDate.
    DATA(today) = cl_abap_context_info=>get_system_date( ).
    READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY ZrTicketItem03000
        FIELDS ( DueDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(tickets).

    LOOP AT tickets INTO DATA(ticket).
      IF ticket-DueDate IS INITIAL OR ticket-DueDate < today.
        APPEND VALUE #( %tky = ticket-%tky ) TO failed-ZrTicketItem03000.
        APPEND VALUE #(
          %tky = ticket-%tky
          %element-DueDate = if_abap_behv=>mk-on
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Geben Sie ein Fälligkeitsdatum ab heute an.' )
        ) TO reported-ZrTicketItem03000.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_closable_tickets.
    DATA(active_keys) = keys.
    DELETE active_keys WHERE %is_draft <> if_abap_behv=>mk-off.
    IF active_keys IS INITIAL.
      RETURN.
    ENDIF.

    READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY ZrTicketItem03000
        FIELDS ( Status ) WITH active_keys
      RESULT DATA(active_tickets).

    DELETE active_tickets WHERE Status <> 'O' AND Status <> 'B' AND Status <> 'L'.
    IF active_tickets IS INITIAL.
      RETURN.
    ENDIF.

    READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY ZrTicketItem03000
        FIELDS ( TicketID )
        WITH VALUE #( FOR ticket IN active_tickets
          ( %key = ticket-%key %is_draft = if_abap_behv=>mk-on ) )
      RESULT DATA(drafts)
      FAILED DATA(draft_failed).

    " Nur ein eindeutig fehlender Entwurf gibt die aktive Instanz frei.
    tickets = active_tickets.
    LOOP AT active_tickets INTO DATA(active_ticket).
      IF line_exists( drafts[ %key = active_ticket-%key ] )
          OR NOT line_exists( draft_failed-ZrTicketItem03000[
            %key = active_ticket-%key %fail-cause = if_abap_behv=>cause-not_found ] ).
        DELETE tickets WHERE TicketID = active_ticket-TicketID.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_features.
    IF requested_features-%action-closeTicket = if_abap_behv=>mk-off.
      RETURN.
    ENDIF.

    DATA(closable_tickets) = get_closable_tickets( CORRESPONDING #( keys ) ).
    result = VALUE #( FOR key IN keys
      ( %tky = key-%tky
        %features-%action-closeTicket = COND #(
          WHEN line_exists( closable_tickets[ %tky = key-%tky ] )
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled ) ) ).
  ENDMETHOD.

  METHOD closeTicket.
    CONSTANTS status_closed TYPE zticket_item_03-status VALUE 'G'.
    DATA(closable_tickets) = get_closable_tickets( CORRESPONDING #( keys ) ).

    LOOP AT keys INTO DATA(key).
      IF NOT line_exists( closable_tickets[ %tky = key-%tky ] ).
        APPEND VALUE #( %tky = key-%tky %fail-cause = if_abap_behv=>cause-unspecific
                        %action-closeTicket = if_abap_behv=>mk-on )
          TO failed-ZrTicketItem03000.
        APPEND VALUE #(
          %tky = key-%tky
          %action-closeTicket = if_abap_behv=>mk-on
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Ticket kann mit diesem Status oder bei vorhandenem Entwurf nicht geschlossen werden.' ) )
          TO reported-ZrTicketItem03000.
      ENDIF.
    ENDLOOP.

    IF closable_tickets IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY ZrTicketItem03000
        UPDATE FIELDS ( Status )
        WITH VALUE #( FOR ticket IN closable_tickets
          ( %tky = ticket-%tky Status = status_closed ) )
      FAILED DATA(update_failed)
      REPORTED DATA(update_reported).

    APPEND LINES OF update_failed-ZrTicketItem03000 TO failed-ZrTicketItem03000.
    APPEND LINES OF update_reported-ZrTicketItem03000 TO reported-ZrTicketItem03000.

    READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY ZrTicketItem03000
        ALL FIELDS WITH CORRESPONDING #( closable_tickets )
      RESULT DATA(tickets).

    LOOP AT tickets INTO DATA(closed_ticket) WHERE Status = status_closed.
      IF NOT line_exists( update_failed-ZrTicketItem03000[ %tky = closed_ticket-%tky ] ).
        APPEND VALUE #( %tky = closed_ticket-%tky %param = closed_ticket ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.