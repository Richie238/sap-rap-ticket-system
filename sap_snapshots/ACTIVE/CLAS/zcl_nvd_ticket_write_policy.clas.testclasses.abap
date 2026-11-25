CLASS ltc_write_policy DEFINITION DEFERRED.
CLASS zcl_nvd_ticket_write_policy DEFINITION LOCAL FRIENDS ltc_write_policy.

CLASS ltc_write_policy DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    DATA user_id TYPE zticket_item_03-requester_user.
    DATA ticket TYPE zticket_item_03.
    DATA rights TYPE zcl_nvd_ticket_write_policy=>grants.
    METHODS setup.
    METHODS requester_fields_and_uploads FOR TESTING.
    METHODS agent_workflow_and_assignment FOR TESTING.
    METHODS manager_workflow_and_assign FOR TESTING.
    METHODS admin_delete_is_independent FOR TESTING.
    METHODS unverified_ticket_denies_all FOR TESTING.
    METHODS closed_ticket_rejects_changes FOR TESTING.
    METHODS policy RETURNING VALUE(result) TYPE zcl_nvd_ticket_write_policy=>permissions.
ENDCLASS.

CLASS ltc_write_policy IMPLEMENTATION.
  METHOD setup.
    user_id = cl_abap_context_info=>get_user_technical_name( ).
    ticket = VALUE #( migration_status = 'V' status = 'O' support_team_id = 'TEST_A' ).
  ENDMETHOD.

  METHOD policy.
    result = zcl_nvd_ticket_write_policy=>evaluate(
      ticket = ticket rights = rights user_id = user_id
      active_team = abap_true active_assignment = abap_true attachment_owner = user_id ).
  ENDMETHOD.

  METHOD requester_fields_and_uploads.
    rights = VALUE #( own_change = abap_true attach_create = abap_true
      attach_change = abap_true attach_delete = abap_true ).
    ticket-requester_user = user_id.
    DATA(own) = policy( ).
    cl_abap_unit_assert=>assert_true( own-edit_subject ).
    cl_abap_unit_assert=>assert_true( own-edit_description ).
    cl_abap_unit_assert=>assert_false( own-edit_operations ).
    cl_abap_unit_assert=>assert_false( own-start_work ).
    cl_abap_unit_assert=>assert_true( own-change_attachment ).
    DATA(foreign_attachment) = zcl_nvd_ticket_write_policy=>evaluate(
      ticket = ticket rights = rights user_id = user_id
      active_team = abap_true active_assignment = abap_true attachment_owner = space ).
    cl_abap_unit_assert=>assert_false( foreign_attachment-change_attachment ).
    cl_abap_unit_assert=>assert_false( foreign_attachment-delete_attachment ).
    CLEAR ticket-requester_user.
    DATA(other) = policy( ).
    cl_abap_unit_assert=>assert_initial( other ).
  ENDMETHOD.

  METHOD agent_workflow_and_assignment.
    rights = VALUE #( agent_change = abap_true workflow = abap_true assignment = abap_true ).
    ticket-assigned_agent_user = user_id.
    DATA(result) = policy( ).
    cl_abap_unit_assert=>assert_true( result-start_work ).
    cl_abap_unit_assert=>assert_false( result-assign_ticket ).
    ticket-status = 'B'.
    result = policy( ).
    cl_abap_unit_assert=>assert_true( result-mark_resolved ).
    ticket-status = 'L'.
    result = policy( ).
    cl_abap_unit_assert=>assert_true( result-reopen_ticket ).
    cl_abap_unit_assert=>assert_false( result-close_ticket ).
    DATA(revoked) = zcl_nvd_ticket_write_policy=>evaluate(
      ticket = ticket rights = rights user_id = user_id
      active_team = abap_true active_assignment = abap_false attachment_owner = space ).
    cl_abap_unit_assert=>assert_initial( revoked ).
  ENDMETHOD.

  METHOD manager_workflow_and_assign.
    rights = VALUE #( team_change = abap_true workflow = abap_true assignment = abap_true ).
    DATA(result) = policy( ).
    cl_abap_unit_assert=>assert_true( result-assign_ticket ).
    cl_abap_unit_assert=>assert_false( result-start_work ).
    ticket-status = 'L'.
    result = policy( ).
    cl_abap_unit_assert=>assert_true( result-close_ticket ).
    DATA(outside_team) = zcl_nvd_ticket_write_policy=>evaluate(
      ticket = ticket rights = rights user_id = user_id
      active_team = abap_false active_assignment = abap_false attachment_owner = space ).
    cl_abap_unit_assert=>assert_initial( outside_team ).
  ENDMETHOD.

  METHOD admin_delete_is_independent.
    rights-deletion = abap_true.
    DATA(result) = policy( ).
    cl_abap_unit_assert=>assert_true( result-delete_ticket ).
    cl_abap_unit_assert=>assert_false( result-edit_ticket ).
    cl_abap_unit_assert=>assert_false( result-assign_ticket ).
  ENDMETHOD.

  METHOD unverified_ticket_denies_all.
    CLEAR ticket-migration_status.
    ticket-assigned_agent_user = user_id.
    ticket-requester_user = user_id.
    rights = VALUE #( own_change = abap_true agent_change = abap_true team_change = abap_true
      workflow = abap_true assignment = abap_true deletion = abap_true attach_create = abap_true
      attach_change = abap_true attach_delete = abap_true ).
    cl_abap_unit_assert=>assert_initial( policy( ) ).
  ENDMETHOD.

  METHOD closed_ticket_rejects_changes.
    ticket-status = 'G'.
    rights = VALUE #( team_change = abap_true workflow = abap_true assignment = abap_true
      attach_create = abap_true attach_change = abap_true attach_delete = abap_true ).
    cl_abap_unit_assert=>assert_initial( policy( ) ).
  ENDMETHOD.
ENDCLASS.
