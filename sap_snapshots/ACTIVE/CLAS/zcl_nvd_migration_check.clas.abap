CLASS zcl_nvd_migration_check DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
    TYPES: BEGIN OF ty_assignment,
             ticket_id           TYPE zticket_item_03-ticket_id,
             requester_user      TYPE znvd_team_member-business_user,
             assigned_agent_user TYPE znvd_team_member-business_user,
             support_team_id     TYPE znvd_team-support_team_id,
           END OF ty_assignment,
           tt_assignments TYPE SORTED TABLE OF ty_assignment WITH NON-UNIQUE KEY ticket_id,
           BEGIN OF ty_summary,
             total           TYPE i,
             unique          TYPE i,
             ambiguous       TYPE i,
             missing         TYPE i,
             invalid         TYPE i,
             open_drafts     TYPE i,
             unknown_tickets TYPE i,
           END OF ty_summary.
    CLASS-METHODS check_assignments
      IMPORTING assignments   TYPE tt_assignments
      RETURNING VALUE(result) TYPE ty_summary.
ENDCLASS.

CLASS zcl_nvd_migration_check IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( 'Read-only inventory. No confirmed mappings supplied.' ).
    out->write( check_assignments( VALUE #( ) ) ).
  ENDMETHOD.

  METHOD check_assignments.
    SELECT ticket_id FROM zticket_item_03
      INTO TABLE @DATA(tickets).
    DATA ticket_keys TYPE HASHED TABLE OF zticket_item_03-ticket_id WITH UNIQUE KEY table_line.
    ticket_keys = tickets.
    result-total = lines( ticket_keys ).

    SELECT COUNT( * ) FROM ztckt_itm_0000_d INTO @result-open_drafts.
    SELECT support_team_id FROM znvd_team
      WHERE is_active = @abap_true
      INTO TABLE @DATA(active_teams).
    SELECT support_team_id, business_user FROM znvd_team_member
      WHERE is_active = @abap_true
      INTO TABLE @DATA(active_members).

    LOOP AT assignments INTO DATA(assignment) GROUP BY assignment-ticket_id.
      IF NOT line_exists( ticket_keys[ table_line = assignment-ticket_id ] ).
        result-unknown_tickets += 1.
      ENDIF.
    ENDLOOP.

    LOOP AT ticket_keys INTO DATA(current_ticket_id).
      DATA(matches) = 0.
      DATA(candidate) = VALUE ty_assignment( ).
      LOOP AT assignments INTO assignment WHERE ticket_id = current_ticket_id.
        matches += 1.
        candidate = assignment.
      ENDLOOP.

      IF matches = 0.
        result-missing += 1.
      ELSEIF matches > 1.
        result-ambiguous += 1.
      ELSEIF candidate-requester_user IS INITIAL OR
             NOT line_exists( active_teams[ support_team_id = candidate-support_team_id ] ) OR
             ( candidate-assigned_agent_user IS NOT INITIAL AND
               NOT line_exists( active_members[ support_team_id = candidate-support_team_id
                                                business_user = candidate-assigned_agent_user ] ) ).
        result-invalid += 1.
      ELSE.
        result-unique += 1.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
