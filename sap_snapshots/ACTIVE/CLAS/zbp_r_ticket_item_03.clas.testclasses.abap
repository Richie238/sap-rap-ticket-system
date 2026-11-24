CLASS ltc_ticket_workflow DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    TYPES ticket_id_type TYPE zticket_item_03-ticket_id.
    CONSTANTS actions TYPE c LENGTH 4 VALUE 'SRWC'.
    CLASS-DATA cds_environment TYPE REF TO if_cds_test_environment.
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
    cds_environment = cl_cds_test_environment=>create( i_for_entity = 'ZR_TICKET_ITEM_03000' ).
    cds_environment->enable_double_redirection( ).
  ENDMETHOD.

  METHOD class_teardown.
    cds_environment->destroy( ).
  ENDMETHOD.

  METHOD teardown.
    ROLLBACK ENTITIES.
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
    MODIFY ENTITIES OF ZR_TICKET_ITEM_03000
      ENTITY ZrTicketItem03000 EXECUTE Edit FROM VALUE #( ( TicketID = ticket_id ) )
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
      FROM VALUE #( ( TicketID = ticket_id ) )
      FAILED DATA(activate_failed) REPORTED DATA(activate_reported) MAPPED DATA(activate_mapped).
    cl_abap_unit_assert=>assert_not_initial( activate_failed-ZrTicketItem03000 ).
  ENDMETHOD.
ENDCLASS.