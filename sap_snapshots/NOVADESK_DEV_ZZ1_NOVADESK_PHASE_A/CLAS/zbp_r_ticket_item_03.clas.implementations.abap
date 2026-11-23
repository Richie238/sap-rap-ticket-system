CLASS LHC_ZR_TICKET_ITEM_03000 DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR ZrTicketItem03000
        RESULT result.

    METHODS early_numbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE ZrTicketItem03000.

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

  METHOD early_numbering_create.
    CONSTANTS range_object TYPE cl_numberrange_runtime=>nr_object VALUE 'ZNOVATKT'.
    CONSTANTS range_interval TYPE cl_numberrange_runtime=>nr_interval VALUE '01'.

    LOOP AT entities INTO DATA(entity).
      " RAP can pass the already numbered key again during draft activation.
      IF entity-TicketID IS NOT INITIAL.
        APPEND VALUE #( %cid = entity-%cid %key = entity-%key %is_draft = entity-%is_draft )
          TO mapped-ZrTicketItem03000.
        CONTINUE.
      ENDIF.

      DATA(ticket_id) = VALUE zticket_item_03-ticket_id( ).
      TRY.
          cl_numberrange_runtime=>number_get(
            EXPORTING object = range_object nr_range_nr = range_interval
            IMPORTING number = DATA(number) returncode = DATA(return_code)
                      returned_quantity = DATA(quantity) ).
          DATA(number_value) = CONV int8( number ).
          IF quantity = 1 AND ( return_code IS INITIAL OR return_code = '1' OR return_code = '2' )
              AND number_value BETWEEN 10000 AND 99999.
            ticket_id = CONV #( number_value ).
          ENDIF.
        CATCH cx_nr_object_not_found cx_number_ranges cx_sy_conversion_error.
          CLEAR ticket_id.
      ENDTRY.

      IF ticket_id IS NOT INITIAL.
        READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
          ENTITY ZrTicketItem03000 FIELDS ( TicketID )
          WITH VALUE #( ( TicketID = ticket_id %is_draft = if_abap_behv=>mk-off )
                        ( TicketID = ticket_id %is_draft = if_abap_behv=>mk-on ) )
          RESULT DATA(occupied)
          FAILED DATA(availability_failed).
        IF occupied IS NOT INITIAL
            OR NOT line_exists( availability_failed-ZrTicketItem03000[
              TicketID = ticket_id %is_draft = if_abap_behv=>mk-off %fail-cause = if_abap_behv=>cause-not_found ] )
            OR NOT line_exists( availability_failed-ZrTicketItem03000[
              TicketID = ticket_id %is_draft = if_abap_behv=>mk-on %fail-cause = if_abap_behv=>cause-not_found ] ).
          CLEAR ticket_id.
        ENDIF.
      ENDIF.

      IF ticket_id IS INITIAL.
        APPEND VALUE #( %cid = entity-%cid %is_draft = entity-%is_draft
                        %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-ZrTicketItem03000.
        APPEND VALUE #( %cid = entity-%cid %is_draft = entity-%is_draft
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text = 'Es konnte keine eindeutige Ticketnummer vergeben werden.' ) )
          TO reported-ZrTicketItem03000.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %cid = entity-%cid TicketID = ticket_id %is_draft = entity-%is_draft )
        TO mapped-ZrTicketItem03000.
    ENDLOOP.
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