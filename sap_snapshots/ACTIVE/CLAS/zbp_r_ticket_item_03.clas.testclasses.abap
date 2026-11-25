CLASS ltc_ticket_workflow DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    TYPES ticket_id_type TYPE zticket_item_03-ticket_id.
    CONSTANTS actions TYPE c LENGTH 4 VALUE 'SRWC'.
    CLASS-DATA cds_environment TYPE REF TO if_cds_test_environment.
    CLASS-DATA sql_environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS teardown.
    METHODS active_matrix FOR TESTING RAISING cx_static_check.
    METHODS draft_restrictions FOR TESTING RAISING cx_static_check.
    METHODS sibling_draft_restrictions FOR TESTING.
    METHODS reject_changed_draft_status FOR TESTING.
    METHODS create_ticket
      IMPORTING is_draft TYPE abp_behv_flag
      RETURNING VALUE(ticket_id) TYPE ticket_id_type.
    METHODS execute_transition
      IMPORTING ticket_id TYPE ticket_id_type is_draft TYPE abp_behv_flag
                action TYPE c expected_status TYPE zticket_item_03-status OPTIONAL.
    METHODS reject_other_actions
      IMPORTING ticket_id TYPE ticket_id_type allowed_actions TYPE string.
ENDCLASS.

CLASS ltc_ticket_workflow IMPLEMENTATION.
  METHOD class_setup.
    cds_environment = cl_cds_test_environment=>create_for_multiple_cds( VALUE #(
      ( i_for_entity = 'ZR_TICKET_ITEM_03000' )
      ( i_for_entity = 'ZR_NVD_TKT_ATT' ) ) ).
    cds_environment->enable_double_redirection( ).
    sql_environment = cl_osql_test_environment=>create( VALUE #(
      ( 'ZNVD_TKT_HIST' ) ( 'ZTCKT_ITM_0000_D' ) ( 'ZNVD_TKT_ATT_D' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_environment->destroy( ).
    cds_environment->destroy( ).
  ENDMETHOD.

  METHOD teardown.
    ROLLBACK ENTITIES.
    sql_environment->clear_doubles( ).
    cds_environment->clear_doubles( ).
  ENDMETHOD.

  METHOD create_ticket.
    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY ZrTicketItem03000 CREATE FIELDS ( TicketID Subject AssignedTo DueDate )
      WITH VALUE #( ( %cid = 'WORKFLOW_TEST' %is_draft = is_draft
                      TicketID = '99991001'
                      Subject = 'NovaDesk Workflow ABAP Unit'
                      AssignedTo = 'IT'
                      DueDate = cl_abap_context_info=>get_system_date( ) ) )
      MAPPED DATA(mapped) FAILED DATA(failed).
    cl_abap_unit_assert=>assert_initial( failed-ZrTicketItem03000 ).
    cl_abap_unit_assert=>assert_not_initial( mapped-ZrTicketItem03000 ).
    ticket_id = mapped-ZrTicketItem03000[ 1 ]-TicketID.
    cl_abap_unit_assert=>assert_not_initial( ticket_id ).
  ENDMETHOD.

  METHOD execute_transition.
    DATA failed TYPE RESPONSE FOR FAILED ZR_TICKET_ITEM_03000.
    DATA reported TYPE RESPONSE FOR REPORTED ZR_TICKET_ITEM_03000.
    DATA actual_status TYPE zticket_item_03-status.
    DATA(result_count) = 0.

    CASE action.
      WHEN 'S'.
        MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
          ENTITY ZrTicketItem03000 EXECUTE startWork
          FROM VALUE #( ( TicketID = ticket_id %is_draft = is_draft ) )
          RESULT DATA(result_s) FAILED failed REPORTED reported.
        result_count = lines( result_s ).
        IF result_count = 1.
          actual_status = result_s[ 1 ]-%param-Status.
        ENDIF.
      WHEN 'R'.
        MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
          ENTITY ZrTicketItem03000 EXECUTE markResolved
          FROM VALUE #( ( TicketID = ticket_id %is_draft = is_draft ) )
          RESULT DATA(result_r) FAILED failed REPORTED reported.
        result_count = lines( result_r ).
        IF result_count = 1.
          actual_status = result_r[ 1 ]-%param-Status.
        ENDIF.
      WHEN 'W'.
        MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
          ENTITY ZrTicketItem03000 EXECUTE reopenTicket
          FROM VALUE #( ( TicketID = ticket_id %is_draft = is_draft ) )
          RESULT DATA(result_w) FAILED failed REPORTED reported.
        result_count = lines( result_w ).
        IF result_count = 1.
          actual_status = result_w[ 1 ]-%param-Status.
        ENDIF.
      WHEN 'C'.
        MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
          ENTITY ZrTicketItem03000 EXECUTE closeTicket
          FROM VALUE #( ( TicketID = ticket_id %is_draft = is_draft ) )
          RESULT DATA(result_c) FAILED failed REPORTED reported.
        result_count = lines( result_c ).
        IF result_count = 1.
          actual_status = result_c[ 1 ]-%param-Status.
        ENDIF.
    ENDCASE.

    IF expected_status IS INITIAL.
      cl_abap_unit_assert=>assert_equals( act = lines( failed-ZrTicketItem03000 ) exp = 1 ).
      cl_abap_unit_assert=>assert_not_initial( reported-ZrTicketItem03000 ).
      cl_abap_unit_assert=>assert_equals( act = result_count exp = 0 ).
    ELSE.
      cl_abap_unit_assert=>assert_initial( failed-ZrTicketItem03000 ).
      cl_abap_unit_assert=>assert_equals( act = result_count exp = 1 ).
      cl_abap_unit_assert=>assert_equals( act = actual_status exp = expected_status ).
    ENDIF.
  ENDMETHOD.

  METHOD reject_other_actions.
    DO strlen( actions ) TIMES.
      DATA(offset) = sy-index - 1.
      DATA(action) = actions+offset(1).
      IF allowed_actions NS action OR allowed_actions IS INITIAL.
        execute_transition( ticket_id = ticket_id is_draft = if_abap_behv=>mk-off action = action ).
      ENDIF.
    ENDDO.
  ENDMETHOD.

  METHOD active_matrix.
    DATA(ticket_id) = create_ticket( if_abap_behv=>mk-off ).

    reject_other_actions( ticket_id = ticket_id allowed_actions = 'S' ).
    execute_transition( ticket_id = ticket_id is_draft = if_abap_behv=>mk-off action = 'S' expected_status = 'B' ).
    reject_other_actions( ticket_id = ticket_id allowed_actions = 'R' ).
    execute_transition( ticket_id = ticket_id is_draft = if_abap_behv=>mk-off action = 'R' expected_status = 'L' ).
    reject_other_actions( ticket_id = ticket_id allowed_actions = 'WC' ).
    execute_transition( ticket_id = ticket_id is_draft = if_abap_behv=>mk-off action = 'W' expected_status = 'B' ).
    execute_transition( ticket_id = ticket_id is_draft = if_abap_behv=>mk-off action = 'R' expected_status = 'L' ).
    execute_transition( ticket_id = ticket_id is_draft = if_abap_behv=>mk-off action = 'C' expected_status = 'G' ).
    reject_other_actions( ticket_id = ticket_id allowed_actions = '' ).

    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY ZrTicketItem03000 UPDATE FIELDS ( Status )
      WITH VALUE #( ( TicketID = ticket_id %is_draft = if_abap_behv=>mk-off Status = '?' ) )
      FAILED DATA(update_failed).
    cl_abap_unit_assert=>assert_initial( update_failed-ZrTicketItem03000 ).
    reject_other_actions( ticket_id = ticket_id allowed_actions = '' ).
  ENDMETHOD.

  METHOD draft_restrictions.
    DATA(ticket_id) = create_ticket( if_abap_behv=>mk-on ).
    DO strlen( actions ) TIMES.
      DATA(offset) = sy-index - 1.
      execute_transition( ticket_id = ticket_id is_draft = if_abap_behv=>mk-on action = actions+offset(1) ).
    ENDDO.
  ENDMETHOD.

  METHOD sibling_draft_restrictions.
    DATA(ticket_id) = create_ticket( if_abap_behv=>mk-off ).
    COMMIT ENTITIES RESPONSE OF ZR_TICKET_ITEM_03000 FAILED DATA(save_failed).
    cl_abap_unit_assert=>assert_initial( save_failed ).
    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000
      ENTITY ZrTicketItem03000 EXECUTE Edit FROM VALUE #( ( %cid = 'EDIT' TicketID = ticket_id ) )
      FAILED DATA(edit_failed).
    cl_abap_unit_assert=>assert_initial( edit_failed-ZrTicketItem03000 ).

    reject_other_actions( ticket_id = ticket_id allowed_actions = '' ).
    DO strlen( actions ) TIMES.
      DATA(offset) = sy-index - 1.
      execute_transition( ticket_id = ticket_id is_draft = if_abap_behv=>mk-on action = actions+offset(1) ).
    ENDDO.
  ENDMETHOD.

  METHOD reject_changed_draft_status.
    DATA(ticket_id) = create_ticket( if_abap_behv=>mk-on ).
    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE
      ENTITY ZrTicketItem03000 UPDATE FIELDS ( Status )
      WITH VALUE #( ( TicketID = ticket_id %is_draft = if_abap_behv=>mk-on Status = 'G' ) )
      FAILED DATA(update_failed).
    cl_abap_unit_assert=>assert_initial( update_failed-ZrTicketItem03000 ).

    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000
      ENTITY ZrTicketItem03000 EXECUTE Activate
      FROM VALUE #( ( %cid = 'ACTIVATE' TicketID = ticket_id ) )
      FAILED DATA(activate_failed) REPORTED DATA(activate_reported) MAPPED DATA(activate_mapped).
    cl_abap_unit_assert=>assert_not_initial( activate_failed-ZrTicketItem03000 ).
  ENDMETHOD.
ENDCLASS.

CLASS ltc_attachment_history DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    CONSTANTS ticket TYPE zticket_item_03-ticket_id VALUE '99991742'.
    CONSTANTS subject TYPE zticket_item_03-subject VALUE 'NovaDesk Attachment History Integration 91742'.
    CLASS-DATA cds_environment TYPE REF TO if_cds_test_environment.
    CLASS-DATA sql_environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    DATA attachment TYPE znvd_tkt_att-attachment_uuid.
    METHODS teardown.
    METHODS draft_lifecycle FOR TESTING.
    METHODS contributions_fail_closed FOR TESTING.
    METHODS save_changes.
    METHODS add_file.
    METHODS edit_draft.
    METHODS activate_draft.
    METHODS change_file IMPORTING filename TYPE znvd_tkt_att-file_name
                                   content TYPE xstring.
    METHODS assert_history IMPORTING event TYPE znvd_tkt_hist-event_type
                                     old_name TYPE znvd_tkt_hist-old_value OPTIONAL
                                     new_name TYPE znvd_tkt_hist-new_value OPTIONAL.
    METHODS assert_count IMPORTING expected TYPE i.
ENDCLASS.

CLASS ltc_attachment_history IMPLEMENTATION.
  METHOD save_changes.
    COMMIT ENTITIES RESPONSE OF ZR_TICKET_ITEM_03000 FAILED DATA(failed) REPORTED DATA(reported).
    DATA(rc) = sy-subrc.
    cl_abap_unit_assert=>assert_initial( failed ).
    cl_abap_unit_assert=>assert_equals( act = rc exp = 0 ).
  ENDMETHOD.

  METHOD class_setup.
    cds_environment = cl_cds_test_environment=>create_for_multiple_cds( VALUE #(
      ( i_for_entity = 'ZR_TICKET_ITEM_03000' )
      ( i_for_entity = 'ZR_NVD_TKT_ATT' )
      ( i_for_entity = 'ZR_NVD_COMMENT' )
      ( i_for_entity = 'ZR_NVD_INTERNAL_NOTE' ) ) ).
    cds_environment->enable_double_redirection( ).
    sql_environment = cl_osql_test_environment=>create( VALUE #(
      ( 'ZNVD_TKT_HIST' ) ( 'ZTCKT_ITM_0000_D' ) ( 'ZNVD_TKT_ATT_D' )
      ( 'ZNVD_TKT_CMT_D' ) ( 'ZNVD_TKT_NOTE_D' ) ( 'ZNVD_NOTE_AUDIT' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_environment->destroy( ).
    cds_environment->destroy( ).
  ENDMETHOD.

  METHOD teardown.
    ROLLBACK ENTITIES.
  ENDMETHOD.

  METHOD add_file.
    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000
      ENTITY ZrTicketItem03000 CREATE BY \_Attachments FIELDS ( FileName MimeType FileContent )
      WITH VALUE #( ( TicketID = ticket %is_draft = if_abap_behv=>mk-on
        %target = VALUE #( ( %cid = 'ATT' %is_draft = if_abap_behv=>mk-on
          FileName = 'probe.pdf' MimeType = 'application/pdf' FileContent = '255044462D41' ) ) ) )
      MAPPED DATA(mapped) FAILED DATA(failed).
    cl_abap_unit_assert=>assert_initial( failed ).
    attachment = mapped-Attachment[ 1 ]-AttachmentUUID.
    save_changes( ).
  ENDMETHOD.

  METHOD edit_draft.
    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 ENTITY ZrTicketItem03000
      EXECUTE Edit FROM VALUE #( ( %cid = 'EDIT' TicketID = ticket ) )
      MAPPED DATA(mapped) FAILED DATA(failed).
    cl_abap_unit_assert=>assert_initial( failed ).
    save_changes( ).
  ENDMETHOD.

  METHOD activate_draft.
    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 ENTITY ZrTicketItem03000
      EXECUTE Activate FROM VALUE #( ( %cid = 'ACTIVATE' TicketID = ticket ) )
      MAPPED DATA(mapped) FAILED DATA(failed).
    cl_abap_unit_assert=>assert_initial( failed ).
    save_changes( ).
  ENDMETHOD.

  METHOD change_file.
    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 ENTITY Attachment
      UPDATE FIELDS ( FileName FileContent )
      WITH VALUE #( ( AttachmentUUID = attachment %is_draft = if_abap_behv=>mk-on
                      FileName = filename FileContent = content ) ) FAILED DATA(failed).
    cl_abap_unit_assert=>assert_initial( failed ).
    save_changes( ).
  ENDMETHOD.

  METHOD assert_history.
    SELECT FROM znvd_tkt_hist FIELDS COUNT( * )
      WHERE ticket_id = @ticket AND attachment_uuid = @attachment AND event_type = @event
        AND old_value = @old_name AND new_value = @new_name
      INTO @DATA(actual).
    cl_abap_unit_assert=>assert_equals( act = actual exp = 1 msg = event ).
  ENDMETHOD.

  METHOD assert_count.
    SELECT FROM znvd_tkt_hist FIELDS COUNT( * ) WHERE ticket_id = @ticket
      AND event_type LIKE 'ATTACHMENT%' INTO @DATA(actual).
    cl_abap_unit_assert=>assert_equals( act = actual exp = expected ).
  ENDMETHOD.

  METHOD draft_lifecycle.
    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE ENTITY ZrTicketItem03000
      CREATE FIELDS ( TicketID Subject AssignedTo DueDate )
      WITH VALUE #( ( %cid = 'HIST' %is_draft = if_abap_behv=>mk-on TicketID = ticket
                      Subject = subject AssignedTo = 'IT'
                      DueDate = cl_abap_context_info=>get_system_date( ) ) ) FAILED DATA(failed).
    cl_abap_unit_assert=>assert_initial( failed ).
    save_changes( ).
    add_file( ).
    assert_count( 0 ).
    activate_draft( ).
    assert_history( event = 'ATTACHMENT_ADDED' new_name = 'probe.pdf' ).

    edit_draft( ).
    change_file( filename = 'renamed.pdf' content = '255044462D41' ).
    activate_draft( ).
    assert_history( event = 'ATTACHMENT_CHANGED' old_name = 'probe.pdf' new_name = 'renamed.pdf' ).

    edit_draft( ).
    change_file( filename = 'renamed.pdf' content = '255044462D42' ).
    activate_draft( ).
    assert_history( event = 'ATTACHMENT_REPLACED' old_name = 'renamed.pdf' new_name = 'renamed.pdf' ).

    edit_draft( ).
    change_file( filename = 'renamed.pdf' content = '255044462D42' ).
    activate_draft( ).
    assert_count( 3 ).

    edit_draft( ).
    change_file( filename = 'discard.pdf' content = '255044462D43' ).
    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 ENTITY ZrTicketItem03000
      EXECUTE Discard FROM VALUE #( ( TicketID = ticket ) ) FAILED failed.
    cl_abap_unit_assert=>assert_initial( failed ).
    save_changes( ).
    assert_count( 3 ).

    edit_draft( ).
    change_file( filename = 'invalid.pdf' content = '00' ).
    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 ENTITY ZrTicketItem03000
      EXECUTE Activate FROM VALUE #( ( %cid = 'INVALID' TicketID = ticket ) )
      MAPPED DATA(invalid_mapped) FAILED DATA(invalid_failed).
    cl_abap_unit_assert=>assert_not_initial( invalid_failed ).
    ROLLBACK ENTITIES.
    assert_count( 3 ).
    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 ENTITY ZrTicketItem03000
      EXECUTE Discard FROM VALUE #( ( TicketID = ticket ) ) FAILED failed.
    cl_abap_unit_assert=>assert_initial( failed ).
    save_changes( ).

    edit_draft( ).
    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 ENTITY Attachment
      DELETE FROM VALUE #( ( AttachmentUUID = attachment %is_draft = if_abap_behv=>mk-on ) ) FAILED failed.
    cl_abap_unit_assert=>assert_initial( failed ).
    save_changes( ).
    activate_draft( ).
    assert_history( event = 'ATTACHMENT_DELETED' old_name = 'renamed.pdf' ).
    assert_count( 4 ).

    edit_draft( ).
    add_file( ).
    activate_draft( ).
    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 ENTITY ZrTicketItem03000
      DELETE FROM VALUE #( ( TicketID = ticket ) ) FAILED failed.
    cl_abap_unit_assert=>assert_initial( failed ).
    save_changes( ).
    SELECT SINGLE FROM znvd_tkt_att FIELDS ticket_id WHERE attachment_uuid = @attachment INTO @DATA(existing).
    cl_abap_unit_assert=>assert_initial( existing ).
    assert_history( event = 'ATTACHMENT_DELETED' old_name = 'probe.pdf' ).
    assert_count( 6 ).
  ENDMETHOD.
  METHOD contributions_fail_closed.
    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE ENTITY ZrTicketItem03000
      CREATE FIELDS ( TicketID Subject AssignedTo DueDate )
      WITH VALUE #( ( %cid = 'TICKET' TicketID = ticket Subject = subject AssignedTo = 'IT'
                      DueDate = cl_abap_context_info=>get_system_date( ) ) ) FAILED DATA(failed).
    cl_abap_unit_assert=>assert_initial( failed ).
    save_changes( ).

    DATA comment_uuid TYPE znvd_tkt_cmt-contribution_uuid VALUE '00000000000000000000000000000001'.
    DATA note_uuid TYPE znvd_tkt_note-contribution_uuid VALUE '00000000000000000000000000000002'.
    INSERT znvd_tkt_cmt FROM @( VALUE #( contribution_uuid = comment_uuid ticket_id = ticket body = 'Test' ) ).
    INSERT znvd_tkt_note FROM @( VALUE #( contribution_uuid = note_uuid ticket_id = ticket body = 'Test' ) ).
    INSERT znvd_note_audit FROM @( VALUE #( event_uuid = note_uuid note_uuid = note_uuid
      ticket_id = ticket event_type = 'NOTE_ADDED' ) ).
    edit_draft( ).
    activate_draft( ).
    edit_draft( ).

    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000
      ENTITY ZrTicketItem03000
      CREATE BY \_Comments FIELDS ( Body )
      WITH VALUE #( ( TicketID = ticket %is_draft = if_abap_behv=>mk-on
        %target = VALUE #( ( %cid = 'CMT' %is_draft = if_abap_behv=>mk-on Body = 'Test' ) ) ) )
      CREATE BY \_InternalNotes FIELDS ( Body )
      WITH VALUE #( ( TicketID = ticket %is_draft = if_abap_behv=>mk-on
        %target = VALUE #( ( %cid = 'NOTE' %is_draft = if_abap_behv=>mk-on Body = 'Test' ) ) ) )
      MAPPED DATA(blocked_mapped) FAILED DATA(blocked).
    cl_abap_unit_assert=>assert_initial( blocked_mapped ).
    cl_abap_unit_assert=>assert_not_initial( blocked-Comment ).
    cl_abap_unit_assert=>assert_not_initial( blocked-InternalNote ).

    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000
      ENTITY Comment UPDATE FIELDS ( Body )
        WITH VALUE #( ( ContributionUUID = comment_uuid %is_draft = if_abap_behv=>mk-on Body = 'Änderung' ) )
      ENTITY InternalNote DELETE FROM VALUE #( ( ContributionUUID = note_uuid %is_draft = if_abap_behv=>mk-on ) )
      FAILED DATA(blocked_changes).
    cl_abap_unit_assert=>assert_not_initial( blocked_changes-Comment ).
    cl_abap_unit_assert=>assert_not_initial( blocked_changes-InternalNote ).

    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 IN LOCAL MODE ENTITY ZrTicketItem03000
      CREATE BY \_Comments FIELDS ( Body )
      WITH VALUE #( ( TicketID = ticket %is_draft = if_abap_behv=>mk-on
        %target = VALUE #( ( %cid = 'LOCAL_CMT' %is_draft = if_abap_behv=>mk-on Body = 'Test' ) ) ) )
      CREATE BY \_InternalNotes FIELDS ( Body )
      WITH VALUE #( ( TicketID = ticket %is_draft = if_abap_behv=>mk-on
        %target = VALUE #( ( %cid = 'LOCAL_NOTE' %is_draft = if_abap_behv=>mk-on Body = 'Test' ) ) ) )
      MAPPED DATA(local_mapped) FAILED DATA(local_failed).
    cl_abap_unit_assert=>assert_initial( local_failed ).
    cl_abap_unit_assert=>assert_not_initial( local_mapped-Comment[ 1 ]-ContributionUUID ).
    cl_abap_unit_assert=>assert_not_initial( local_mapped-InternalNote[ 1 ]-ContributionUUID ).
    save_changes( ).

    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 ENTITY ZrTicketItem03000
      EXECUTE Activate FROM VALUE #( ( %cid = 'BLOCKED_ACTIVATE' TicketID = ticket ) )
      MAPPED DATA(activate_mapped) FAILED DATA(activate_failed).
    IF activate_failed IS INITIAL.
      COMMIT ENTITIES RESPONSE OF ZR_TICKET_ITEM_03000 FAILED DATA(commit_failed).
      cl_abap_unit_assert=>assert_not_initial( commit_failed ).
    ENDIF.
    ROLLBACK ENTITIES.
    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 ENTITY ZrTicketItem03000
      EXECUTE Discard FROM VALUE #( ( TicketID = ticket ) ) FAILED failed.
    cl_abap_unit_assert=>assert_initial( failed ).
    save_changes( ).

    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000 ENTITY ZrTicketItem03000
      DELETE FROM VALUE #( ( TicketID = ticket ) ) FAILED failed.
    cl_abap_unit_assert=>assert_initial( failed ).
    save_changes( ).
    SELECT COUNT( * ) FROM znvd_tkt_cmt WHERE ticket_id = @ticket INTO @DATA(comments).
    SELECT COUNT( * ) FROM znvd_tkt_note WHERE ticket_id = @ticket INTO @DATA(notes).
    SELECT COUNT( * ) FROM znvd_note_audit WHERE ticket_id = @ticket INTO @DATA(private_audit).
    SELECT COUNT( * ) FROM znvd_tkt_hist WHERE ticket_id = @ticket
      AND ( event_type = 'COMMENT_ADDED' OR event_type = 'NOTE_ADDED' ) INTO @DATA(public_events).
    cl_abap_unit_assert=>assert_equals( act = comments exp = 0 msg = 'Kommentar-Kaskade' ).
    cl_abap_unit_assert=>assert_equals( act = notes exp = 0 msg = 'Notiz-Kaskade' ).
    cl_abap_unit_assert=>assert_equals( act = private_audit exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = public_events exp = 0 ).
  ENDMETHOD.
ENDCLASS.
