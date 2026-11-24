CLASS lcl_attachment_policy DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES ticket_keys TYPE TABLE FOR READ IMPORT ZR_TICKET_ITEM_03000.
    TYPES ticket_data TYPE TABLE FOR READ RESULT ZR_TICKET_ITEM_03000.
    CLASS-METHODS editable_tickets
      IMPORTING keys TYPE ticket_keys
      RETURNING VALUE(tickets) TYPE ticket_data.
    CLASS-METHODS operation_feature
      IMPORTING editable TYPE abap_bool
      RETURNING VALUE(feature) LIKE if_abap_behv=>fc-o-enabled.
    CONSTANTS blocked_text TYPE string VALUE
      'Anhänge dürfen nur an einem vorhandenen, nicht geschlossenen Ticket geändert werden.'.
ENDCLASS.

CLASS lcl_attachment_policy IMPLEMENTATION.
  METHOD editable_tickets.
    DATA(read_keys) = keys.
    READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY ZrTicketItem03000 FIELDS ( Status ) WITH read_keys RESULT tickets.
    DELETE tickets WHERE Status = 'G'.

    DATA(active_keys) = VALUE ticket_keys(
      FOR entry IN tickets WHERE ( %is_draft = if_abap_behv=>mk-on )
      ( %key = entry-%key %is_draft = if_abap_behv=>mk-off ) ).
    IF active_keys IS INITIAL.
      RETURN.
    ENDIF.

    READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY ZrTicketItem03000 FIELDS ( Status ) WITH active_keys
      RESULT DATA(active_tickets) FAILED DATA(active_failed).
    LOOP AT tickets INTO DATA(ticket) WHERE %is_draft = if_abap_behv=>mk-on.
      DATA(ticket_index) = sy-tabix.
      READ TABLE active_tickets INTO DATA(active_ticket) WITH KEY %key = ticket-%key.
      IF sy-subrc = 0.
        IF active_ticket-Status = 'G'.
          DELETE tickets INDEX ticket_index.
        ENDIF.
      ELSEIF NOT line_exists( active_failed-ZrTicketItem03000[
          %key = ticket-%key %fail-cause = if_abap_behv=>cause-not_found ] ).
        DELETE tickets INDEX ticket_index.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD operation_feature.
    feature = COND #( WHEN editable = abap_true THEN if_abap_behv=>fc-o-enabled
                      ELSE if_abap_behv=>fc-o-disabled ).
  ENDMETHOD.

ENDCLASS.

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

    METHODS validateClosedAttachments FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZrTicketItem03000~validateClosedAttachments.
    METHODS precheck_create_attachments FOR PRECHECK
      IMPORTING keys FOR CREATE ZrTicketItem03000\_Attachments.

    TYPES ticket_read_keys TYPE TABLE FOR READ IMPORT ZR_TICKET_ITEM_03000.
    TYPES ticket_read_result TYPE TABLE FOR READ RESULT ZR_TICKET_ITEM_03000.
    METHODS get_workflow_tickets
      IMPORTING keys TYPE ticket_read_keys
      RETURNING VALUE(tickets) TYPE ticket_read_result.

    TYPES status_code TYPE zticket_item_03-status.
    TYPES workflow_action TYPE c LENGTH 12.

    CONSTANTS:
      startwork_action TYPE workflow_action VALUE 'STARTWORK',
      markresolved_action TYPE workflow_action VALUE 'MARKRESOLVED',
      reopenticket_action TYPE workflow_action VALUE 'REOPENTICKET',
      closeticket_action TYPE workflow_action VALUE 'CLOSETICKET'.

    METHODS target_status
      IMPORTING action TYPE workflow_action current_status TYPE status_code
      RETURNING VALUE(status) TYPE status_code.
    TYPES failed_response TYPE RESPONSE FOR FAILED ZR_TICKET_ITEM_03000.
    TYPES reported_response TYPE RESPONSE FOR REPORTED ZR_TICKET_ITEM_03000.

    METHODS apply_transition
      IMPORTING action TYPE workflow_action keys TYPE ticket_read_keys
      EXPORTING action_failed TYPE failed_response
                action_reported TYPE reported_response
                updated_tickets TYPE ticket_read_result.
    METHODS validateDraftStatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZrTicketItem03000~validateDraftStatus.

    METHODS startWork FOR MODIFY
      IMPORTING keys FOR ACTION ZrTicketItem03000~startWork RESULT result.
    METHODS markResolved FOR MODIFY
      IMPORTING keys FOR ACTION ZrTicketItem03000~markResolved RESULT result.
    METHODS reopenTicket FOR MODIFY
      IMPORTING keys FOR ACTION ZrTicketItem03000~reopenTicket RESULT result.
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

  METHOD get_workflow_tickets.
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

  METHOD target_status.
    CASE action.
      WHEN startwork_action.
        IF current_status = 'O'.
          status = 'B'.
        ENDIF.
      WHEN markresolved_action.
        IF current_status = 'B'.
          status = 'L'.
        ENDIF.
      WHEN reopenticket_action.
        IF current_status = 'L'.
          status = 'B'.
        ENDIF.
      WHEN closeticket_action.
        IF current_status = 'L'.
          status = 'G'.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD validateDraftStatus.
    DATA draft_keys TYPE ticket_read_keys.
    draft_keys = CORRESPONDING #( keys ).
    DELETE draft_keys WHERE %is_draft <> if_abap_behv=>mk-on.
    IF draft_keys IS INITIAL.
      RETURN.
    ENDIF.

    READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY ZrTicketItem03000 FIELDS ( Status ) WITH draft_keys
      RESULT DATA(drafts)
      FAILED DATA(draft_failed).
    LOOP AT draft_failed-ZrTicketItem03000 INTO DATA(unreadable_draft).
      APPEND VALUE #( %tky = unreadable_draft-%tky ) TO failed-ZrTicketItem03000.
    ENDLOOP.

    READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY ZrTicketItem03000 FIELDS ( Status )
      WITH VALUE #( FOR draft_entry IN drafts
        ( %key = draft_entry-%key %is_draft = if_abap_behv=>mk-off ) )
      RESULT DATA(active_tickets)
      FAILED DATA(active_failed).

    LOOP AT drafts INTO DATA(draft).
      APPEND VALUE #( %tky = draft-%tky %state_area = 'WORKFLOW_STATUS' )
        TO reported-ZrTicketItem03000.
      READ TABLE active_tickets INTO DATA(active_ticket) WITH KEY %key = draft-%key.
      IF sy-subrc = 0 AND draft-Status = active_ticket-Status.
        CONTINUE.
      ENDIF.
      IF sy-subrc <> 0 AND draft-Status = 'O'
          AND line_exists( active_failed-ZrTicketItem03000[
            %key = draft-%key %fail-cause = if_abap_behv=>cause-not_found ] ).
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky = draft-%tky ) TO failed-ZrTicketItem03000.
      APPEND VALUE #(
        %tky = draft-%tky
        %state_area = 'WORKFLOW_STATUS'
        %element-Status = if_abap_behv=>mk-on
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'Der Entwurf enthält eine Statusänderung. Verwerfen Sie ihn und öffnen Sie das Ticket erneut.' ) )
        TO reported-ZrTicketItem03000.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_features.
    DATA editable_tickets TYPE lcl_attachment_policy=>ticket_data.
    IF requested_features-%assoc-_Attachments = if_abap_behv=>mk-on.
      editable_tickets = lcl_attachment_policy=>editable_tickets( CORRESPONDING #( keys ) ).
    ENDIF.

    IF requested_features-%action-startWork = if_abap_behv=>mk-off
        AND requested_features-%action-markResolved = if_abap_behv=>mk-off
        AND requested_features-%action-reopenTicket = if_abap_behv=>mk-off
        AND requested_features-%action-closeTicket = if_abap_behv=>mk-off.
      LOOP AT keys INTO DATA(association_key).
        APPEND VALUE #( %tky = association_key-%tky
          %assoc-_Attachments = lcl_attachment_policy=>operation_feature(
            xsdbool( line_exists( editable_tickets[ %tky = association_key-%tky ] ) ) ) ) TO result.
      ENDLOOP.
      RETURN.
    ENDIF.

    DATA(tickets) = get_workflow_tickets( CORRESPONDING #( keys ) ).
    LOOP AT keys INTO DATA(key).
      DATA(current_status) = VALUE status_code( tickets[ %tky = key-%tky ]-Status OPTIONAL ).
      APPEND VALUE #( %tky = key-%tky
        %assoc-_Attachments = lcl_attachment_policy=>operation_feature(
          xsdbool( line_exists( editable_tickets[ %tky = key-%tky ] ) ) )
        %features-%action-startWork = COND #(
          WHEN target_status( action = startwork_action current_status = current_status ) IS NOT INITIAL
          THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %features-%action-markResolved = COND #(
          WHEN target_status( action = markresolved_action current_status = current_status ) IS NOT INITIAL
          THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %features-%action-reopenTicket = COND #(
          WHEN target_status( action = reopenticket_action current_status = current_status ) IS NOT INITIAL
          THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %features-%action-closeTicket = COND #(
          WHEN target_status( action = closeticket_action current_status = current_status ) IS NOT INITIAL
          THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateClosedAttachments.
    DATA active_keys TYPE ticket_read_keys.
    active_keys = VALUE #( FOR draft_key IN keys WHERE ( %is_draft = if_abap_behv=>mk-on )
      ( %key = draft_key-%key %is_draft = if_abap_behv=>mk-off ) ).
    IF active_keys IS INITIAL.
      RETURN.
    ENDIF.

    READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY ZrTicketItem03000 FIELDS ( Status ) WITH active_keys
      RESULT DATA(active_tickets).

    LOOP AT active_tickets INTO DATA(closed_ticket) WHERE Status = 'G'.
      READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
        ENTITY ZrTicketItem03000 BY \_Attachments FIELDS ( FileName MimeType FileContent )
        WITH VALUE #( ( %key = closed_ticket-%key %is_draft = if_abap_behv=>mk-on ) )
        RESULT DATA(draft_files) FAILED DATA(draft_read_failed).
      READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
        ENTITY ZrTicketItem03000 BY \_Attachments FIELDS ( FileName MimeType FileContent )
        WITH VALUE #( ( %tky = closed_ticket-%tky ) )
        RESULT DATA(active_files) FAILED DATA(active_read_failed).

      DATA(unchanged) = xsdbool( draft_read_failed IS INITIAL AND active_read_failed IS INITIAL
                                   AND lines( draft_files ) = lines( active_files ) ).
      IF unchanged = abap_true.
        LOOP AT draft_files INTO DATA(draft_file).
          READ TABLE active_files INTO DATA(active_file) WITH KEY %key = draft_file-%key.
          IF sy-subrc <> 0 OR draft_file-FileName <> active_file-FileName
              OR draft_file-MimeType <> active_file-MimeType
              OR draft_file-FileContent <> active_file-FileContent.
            unchanged = abap_false.
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDIF.

      APPEND VALUE #( %key = closed_ticket-%key %is_draft = if_abap_behv=>mk-on
                      %state_area = 'CLOSED_ATTACHMENTS' ) TO reported-ZrTicketItem03000.
      IF unchanged = abap_false.
        APPEND VALUE #( %key = closed_ticket-%key %is_draft = if_abap_behv=>mk-on )
          TO failed-ZrTicketItem03000.
        APPEND VALUE #( %key = closed_ticket-%key %is_draft = if_abap_behv=>mk-on
          %state_area = 'CLOSED_ATTACHMENTS'
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Der Entwurf enthält unzulässige Anhangsänderungen an einem geschlossenen Ticket.' ) )
          TO reported-ZrTicketItem03000.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD precheck_create_attachments.
    DATA(editable_tickets) = lcl_attachment_policy=>editable_tickets( CORRESPONDING #( keys ) ).
    LOOP AT keys INTO DATA(key).
      IF line_exists( editable_tickets[ %tky = key-%tky ] ).
        CONTINUE.
      ENDIF.
      APPEND VALUE #( %tky = key-%tky
                      %fail-cause = if_abap_behv=>cause-unspecific %assoc-_Attachments = if_abap_behv=>mk-on )
        TO failed-ZrTicketItem03000.
      APPEND VALUE #( %tky = key-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = lcl_attachment_policy=>blocked_text ) )
        TO reported-ZrTicketItem03000.
    ENDLOOP.
  ENDMETHOD.

  METHOD apply_transition.
    DATA tickets_to_update TYPE TABLE FOR UPDATE ZR_TICKET_ITEM_03000.
    DATA(tickets) = get_workflow_tickets( keys ).

    LOOP AT keys INTO DATA(key).
      DATA(current_status) = VALUE status_code( tickets[ %tky = key-%tky ]-Status OPTIONAL ).
      DATA(next_status) = target_status( action = action current_status = current_status ).
      IF next_status IS NOT INITIAL.
        APPEND VALUE #( %tky = key-%tky Status = next_status ) TO tickets_to_update.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky = key-%tky %fail-cause = if_abap_behv=>cause-unspecific )
        TO action_failed-ZrTicketItem03000.
      APPEND VALUE #(
        %tky = key-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'Diese Aktion ist für den aktuellen Status oder bei vorhandenem Entwurf nicht zulässig.' ) )
        TO action_reported-ZrTicketItem03000.
    ENDLOOP.

    IF tickets_to_update IS NOT INITIAL.
      MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
        ENTITY ZrTicketItem03000 UPDATE FIELDS ( Status ) WITH tickets_to_update
        FAILED DATA(update_failed)
        REPORTED DATA(update_reported).

      APPEND LINES OF update_failed-ZrTicketItem03000 TO action_failed-ZrTicketItem03000.
      APPEND LINES OF update_reported-ZrTicketItem03000 TO action_reported-ZrTicketItem03000.

      DATA successful_keys TYPE ticket_read_keys.
      LOOP AT tickets_to_update INTO DATA(update_key).
        IF NOT line_exists( update_failed-ZrTicketItem03000[ %tky = update_key-%tky ] ).
          APPEND CORRESPONDING #( update_key ) TO successful_keys.
        ENDIF.
      ENDLOOP.

      IF successful_keys IS NOT INITIAL.
        READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
          ENTITY ZrTicketItem03000 ALL FIELDS WITH successful_keys
          RESULT updated_tickets
          FAILED DATA(read_failed)
          REPORTED DATA(read_reported).
        APPEND LINES OF read_failed-ZrTicketItem03000 TO action_failed-ZrTicketItem03000.
        APPEND LINES OF read_reported-ZrTicketItem03000 TO action_reported-ZrTicketItem03000.
      ENDIF.
    ENDIF.

    LOOP AT action_failed-ZrTicketItem03000 ASSIGNING FIELD-SYMBOL(<failure>).
      CASE action.
        WHEN startwork_action.
          <failure>-%action-startWork = if_abap_behv=>mk-on.
        WHEN markresolved_action.
          <failure>-%action-markResolved = if_abap_behv=>mk-on.
        WHEN reopenticket_action.
          <failure>-%action-reopenTicket = if_abap_behv=>mk-on.
        WHEN closeticket_action.
          <failure>-%action-closeTicket = if_abap_behv=>mk-on.
      ENDCASE.
    ENDLOOP.
    LOOP AT action_reported-ZrTicketItem03000 ASSIGNING FIELD-SYMBOL(<message>).
      CASE action.
        WHEN startwork_action.
          <message>-%action-startWork = if_abap_behv=>mk-on.
        WHEN markresolved_action.
          <message>-%action-markResolved = if_abap_behv=>mk-on.
        WHEN reopenticket_action.
          <message>-%action-reopenTicket = if_abap_behv=>mk-on.
        WHEN closeticket_action.
          <message>-%action-closeTicket = if_abap_behv=>mk-on.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD startWork.
    apply_transition( EXPORTING action = startwork_action keys = CORRESPONDING #( keys )
                      IMPORTING action_failed = failed action_reported = reported
                                updated_tickets = DATA(tickets) ).
    result = VALUE #( FOR ticket IN tickets ( %tky = ticket-%tky %param = ticket ) ).
  ENDMETHOD.

  METHOD markResolved.
    apply_transition( EXPORTING action = markresolved_action keys = CORRESPONDING #( keys )
                      IMPORTING action_failed = failed action_reported = reported
                                updated_tickets = DATA(tickets) ).
    result = VALUE #( FOR ticket IN tickets ( %tky = ticket-%tky %param = ticket ) ).
  ENDMETHOD.

  METHOD reopenTicket.
    apply_transition( EXPORTING action = reopenticket_action keys = CORRESPONDING #( keys )
                      IMPORTING action_failed = failed action_reported = reported
                                updated_tickets = DATA(tickets) ).
    result = VALUE #( FOR ticket IN tickets ( %tky = ticket-%tky %param = ticket ) ).
  ENDMETHOD.

  METHOD closeTicket.
    apply_transition( EXPORTING action = closeticket_action keys = CORRESPONDING #( keys )
                      IMPORTING action_failed = failed action_reported = reported
                                updated_tickets = DATA(tickets) ).
    result = VALUE #( FOR ticket IN tickets ( %tky = ticket-%tky %param = ticket ) ).
  ENDMETHOD.

ENDCLASS.

CLASS lhc_attachment DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    TYPES attachment_keys TYPE TABLE FOR READ IMPORT ZR_NVD_TKT_ATT.
    TYPES attachment_data TYPE TABLE FOR READ RESULT ZR_NVD_TKT_ATT.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Attachment RESULT result.
    METHODS precheck_update FOR PRECHECK
      IMPORTING keys FOR UPDATE Attachment.
    METHODS precheck_delete FOR PRECHECK
      IMPORTING keys FOR DELETE Attachment.
    METHODS validateFile FOR VALIDATE ON SAVE
      IMPORTING keys FOR Attachment~validateFile.
    METHODS editable_attachments
      IMPORTING keys TYPE attachment_keys
      RETURNING VALUE(attachments) TYPE attachment_data.
    METHODS file_error
      IMPORTING attachment TYPE LINE OF attachment_data
      RETURNING VALUE(error) TYPE string.
ENDCLASS.

CLASS lhc_attachment IMPLEMENTATION.
  METHOD editable_attachments.
    DATA(read_keys) = keys.
    READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY Attachment FIELDS ( TicketID ) WITH read_keys RESULT DATA(attachment_rows).
    DATA(tickets) = lcl_attachment_policy=>editable_tickets(
      VALUE #( FOR attachment_row IN attachment_rows
        ( TicketID = attachment_row-TicketID %is_draft = attachment_row-%is_draft ) ) ).

    LOOP AT attachment_rows INTO DATA(entry).
      IF line_exists( tickets[ TicketID = entry-TicketID %is_draft = entry-%is_draft ] ).
        APPEND entry TO attachments.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_features.
    DATA(editable) = editable_attachments( CORRESPONDING #( keys ) ).
    LOOP AT keys INTO DATA(key).
      DATA(feature) = lcl_attachment_policy=>operation_feature(
        xsdbool( line_exists( editable[ %tky = key-%tky ] ) ) ).
      DATA field_feature LIKE if_abap_behv=>fc-f-read_only.
      field_feature = COND #(
        WHEN feature = if_abap_behv=>fc-o-enabled THEN if_abap_behv=>fc-f-unrestricted
        ELSE if_abap_behv=>fc-f-read_only ).
      APPEND VALUE #( %tky = key-%tky %update = feature %delete = feature
                      %field-FileContent = field_feature %field-FileName = field_feature ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD precheck_update.
    DATA(editable) = editable_attachments( CORRESPONDING #( keys ) ).
    LOOP AT keys INTO DATA(key).
      IF NOT line_exists( editable[ %tky = key-%tky ] ).
        APPEND VALUE #( %tky = key-%tky
                        %fail-cause = if_abap_behv=>cause-unspecific %update = if_abap_behv=>mk-on ) TO failed-Attachment.
        APPEND VALUE #( %tky = key-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = lcl_attachment_policy=>blocked_text ) )
          TO reported-Attachment.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD precheck_delete.
    DATA(editable) = editable_attachments( CORRESPONDING #( keys ) ).
    LOOP AT keys INTO DATA(key).
      IF NOT line_exists( editable[ %tky = key-%tky ] ).
        APPEND VALUE #( %tky = key-%tky
                        %fail-cause = if_abap_behv=>cause-unspecific %delete = if_abap_behv=>mk-on ) TO failed-Attachment.
        APPEND VALUE #( %tky = key-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = lcl_attachment_policy=>blocked_text ) )
          TO reported-Attachment.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateFile.
    READ ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY Attachment FIELDS ( TicketID FileName MimeType FileContent )
      WITH CORRESPONDING #( keys ) RESULT DATA(attachments) FAILED DATA(read_failed).
    LOOP AT read_failed-Attachment INTO DATA(unreadable).
      APPEND VALUE #( %tky = unreadable-%tky ) TO failed-Attachment.
    ENDLOOP.
    LOOP AT attachments INTO DATA(attachment).
      APPEND VALUE #( %tky = attachment-%tky %state_area = 'ATTACHMENT_FILE'
          %path-ZrTicketItem03000-TicketID = attachment-TicketID
          %path-ZrTicketItem03000-%is_draft = attachment-%is_draft )
        TO reported-Attachment.
      DATA(error) = file_error( attachment ).
      IF error IS NOT INITIAL.
        APPEND VALUE #( %tky = attachment-%tky ) TO failed-Attachment.
        APPEND VALUE #( %tky = attachment-%tky %state_area = 'ATTACHMENT_FILE'
          %path-ZrTicketItem03000-TicketID = attachment-TicketID
          %path-ZrTicketItem03000-%is_draft = attachment-%is_draft
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text = error ) ) TO reported-Attachment.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD file_error.
    CONSTANTS max_size TYPE i VALUE 10485760.
    CONSTANTS pdf_signature TYPE x LENGTH 5 VALUE '255044462D'.
    CONSTANTS png_signature TYPE x LENGTH 8 VALUE '89504E470D0A1A0A'.
    CONSTANTS jpeg_signature TYPE x LENGTH 3 VALUE 'FFD8FF'.

    IF attachment-FileName IS INITIAL OR attachment-MimeType IS INITIAL
        OR attachment-FileContent IS INITIAL.
      error = 'Für jeden Anhang sind Dateiname, MIME-Typ und Dateiinhalt erforderlich.'.
      RETURN.
    ENDIF.
    DATA(file_size) = xstrlen( attachment-FileContent ).
    IF file_size > max_size.
      error = 'Die Datei darf höchstens 10 MiB groß sein.'.
      RETURN.
    ENDIF.

    DATA(signature_matches) = abap_false.
    CASE to_lower( attachment-MimeType ).
      WHEN 'application/pdf'.
        IF file_size >= 5.
          signature_matches = xsdbool( attachment-FileContent(5) = pdf_signature ).
        ENDIF.
      WHEN 'image/png'.
        IF file_size >= 8.
          signature_matches = xsdbool( attachment-FileContent(8) = png_signature ).
        ENDIF.
      WHEN 'image/jpeg'.
        IF file_size >= 3.
          signature_matches = xsdbool( attachment-FileContent(3) = jpeg_signature ).
        ENDIF.
      WHEN OTHERS.
        error = 'Erlaubt sind ausschließlich PDF-, PNG- und JPEG-Dateien.'.
        RETURN.
    ENDCASE.
    IF signature_matches = abap_false.
      error = 'Die Dateisignatur stimmt nicht mit dem angegebenen Dateityp überein.'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
