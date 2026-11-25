CLASS zcl_nvd_ticket_write_policy DEFINITION
  PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    TYPES: BEGIN OF permissions,
             edit_ticket       TYPE abap_bool,
             edit_subject      TYPE abap_bool,
             edit_description  TYPE abap_bool,
             edit_operations   TYPE abap_bool,
             assign_ticket     TYPE abap_bool,
             delete_ticket     TYPE abap_bool,
             start_work        TYPE abap_bool,
             mark_resolved     TYPE abap_bool,
             reopen_ticket     TYPE abap_bool,
             close_ticket      TYPE abap_bool,
             create_attachment TYPE abap_bool,
             change_attachment TYPE abap_bool,
             delete_attachment TYPE abap_bool,
           END OF permissions.
    CLASS-METHODS may_create RETURNING VALUE(allowed) TYPE abap_bool.
    CLASS-METHODS for_active_ticket
      IMPORTING ticket_id    TYPE zticket_item_03-ticket_id
                attachment_owner TYPE zticket_item_03-created_by OPTIONAL
      RETURNING VALUE(result) TYPE permissions.
  PRIVATE SECTION.
    TYPES: BEGIN OF grants,
             own_change   TYPE abap_bool,
             agent_change TYPE abap_bool,
             team_change  TYPE abap_bool,
             workflow     TYPE abap_bool,
             assignment   TYPE abap_bool,
             deletion     TYPE abap_bool,
             attach_create TYPE abap_bool,
             attach_change TYPE abap_bool,
             attach_delete TYPE abap_bool,
           END OF grants.
    CLASS-METHODS evaluate
      IMPORTING ticket TYPE zticket_item_03
                rights TYPE grants
                user_id TYPE zticket_item_03-requester_user
                active_team TYPE abap_bool
                active_assignment TYPE abap_bool
                attachment_owner TYPE zticket_item_03-created_by
      RETURNING VALUE(result) TYPE permissions.
ENDCLASS.

CLASS zcl_nvd_ticket_write_policy IMPLEMENTATION.
  METHOD may_create.
    AUTHORITY-CHECK OBJECT 'ZNVD_OWN' ID 'ACTVT' FIELD '01'.
    allowed = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD for_active_ticket.
    SELECT SINGLE * FROM zticket_item_03 WHERE ticket_id = @ticket_id INTO @DATA(ticket).
    IF sy-subrc <> 0 OR ticket-migration_status <> 'V'.
      RETURN.
    ENDIF.

    DATA user_id TYPE zticket_item_03-requester_user.
    user_id = cl_abap_context_info=>get_user_technical_name( ).
    IF user_id IS INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE @abap_true FROM znvd_team
      WHERE support_team_id = @ticket-support_team_id AND is_active = @abap_true
      INTO @DATA(active_team).
    SELECT SINGLE @abap_true FROM znvd_team_member
      WHERE support_team_id = @ticket-support_team_id
        AND business_user = @user_id AND is_active = @abap_true
      INTO @DATA(active_assignment).

    DATA rights TYPE grants.
    AUTHORITY-CHECK OBJECT 'ZNVD_OWN' ID 'ACTVT' FIELD '02'.
    rights-own_change = xsdbool( sy-subrc = 0 ).
    AUTHORITY-CHECK OBJECT 'ZNVD_AGT'
      ID 'ACTVT' FIELD '02' ID 'ZNVD_TEAM' FIELD ticket-support_team_id.
    rights-agent_change = xsdbool( sy-subrc = 0 ).
    AUTHORITY-CHECK OBJECT 'ZNVD_TKT'
      ID 'ACTVT' FIELD '02' ID 'ZNVD_TEAM' FIELD ticket-support_team_id.
    rights-team_change = xsdbool( sy-subrc = 0 ).

    " Rights with unfinished IAM configuration stay denied.
    result = evaluate( ticket = ticket rights = rights user_id = user_id
      active_team = active_team active_assignment = active_assignment
      attachment_owner = attachment_owner ).
  ENDMETHOD.

  METHOD evaluate.
    IF ticket-migration_status <> 'V' OR user_id IS INITIAL.
      RETURN.
    ENDIF.

    DATA(team_scope) = xsdbool( active_team = abap_true AND ticket-support_team_id IS NOT INITIAL ).
    DATA(own) = xsdbool( ticket-requester_user = user_id AND rights-own_change = abap_true ).
    DATA(agent) = xsdbool( team_scope = abap_true AND active_assignment = abap_true
      AND ticket-assigned_agent_user = user_id AND rights-agent_change = abap_true ).
    DATA(manager) = xsdbool( team_scope = abap_true AND rights-team_change = abap_true ).
    result-delete_ticket = xsdbool( team_scope = abap_true AND rights-deletion = abap_true ).

    IF ticket-status <> 'O' AND ticket-status <> 'B' AND ticket-status <> 'L'.
      RETURN.
    ENDIF.

    DATA(staff) = xsdbool( agent = abap_true OR manager = abap_true ).
    result-edit_subject = xsdbool( staff = abap_true OR ( own = abap_true AND ticket-status = 'O' ) ).
    result-edit_description = result-edit_subject.
    result-edit_operations = staff.
    result-edit_ticket = result-edit_subject.
    result-assign_ticket = xsdbool( manager = abap_true AND rights-assignment = abap_true ).
    result-start_work = xsdbool( staff = abap_true AND rights-workflow = abap_true
      AND ticket-status = 'O' AND ticket-assigned_agent_user IS NOT INITIAL ).
    result-mark_resolved = xsdbool( staff = abap_true AND rights-workflow = abap_true AND ticket-status = 'B' ).
    result-reopen_ticket = xsdbool( staff = abap_true AND rights-workflow = abap_true AND ticket-status = 'L' ).
    result-close_ticket = xsdbool( manager = abap_true AND rights-workflow = abap_true AND ticket-status = 'L' ).

    DATA(existing_attachment_scope) = xsdbool( staff = abap_true OR
      ( own = abap_true AND attachment_owner IS NOT INITIAL AND attachment_owner = user_id ) ).
    result-create_attachment = xsdbool( ( own = abap_true OR staff = abap_true ) AND rights-attach_create = abap_true ).
    result-change_attachment = xsdbool( existing_attachment_scope = abap_true AND rights-attach_change = abap_true ).
    result-delete_attachment = xsdbool( existing_attachment_scope = abap_true AND rights-attach_delete = abap_true ).
  ENDMETHOD.
ENDCLASS.
