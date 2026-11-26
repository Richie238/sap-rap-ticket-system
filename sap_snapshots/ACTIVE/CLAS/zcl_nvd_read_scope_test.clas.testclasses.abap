CLASS ltc_ticket_read_scope DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    TYPES ticket_ids TYPE STANDARD TABLE OF zticket_item_03-ticket_id WITH EMPTY KEY.
    DATA environment TYPE REF TO if_cds_test_environment.
    METHODS setup.
    METHODS teardown.
    METHODS no_grant FOR TESTING.
    METHODS requester_scope FOR TESTING.
    METHODS agent_scope FOR TESTING.
    METHODS manager_scope FOR TESTING.
ENDCLASS.

CLASS ltc_ticket_read_scope IMPLEMENTATION.
  METHOD setup.
    environment = cl_cds_test_environment=>create( i_for_entity = 'ZI_NVD_TICKET_READ_SCOPE' ).
    DATA(user) = cl_abap_context_info=>get_user_technical_name( ).
    DATA tickets TYPE STANDARD TABLE OF zticket_item_03 WITH EMPTY KEY.
    DATA teams TYPE STANDARD TABLE OF znvd_team WITH EMPTY KEY.
    DATA members TYPE STANDARD TABLE OF znvd_team_member WITH EMPTY KEY.
    tickets = VALUE #(
      ( client = sy-mandt ticket_id = '00000001' migration_status = 'V'
        requester_user = user assigned_agent_user = user support_team_id = 'TEST_A' )
      ( client = sy-mandt ticket_id = '00000002' migration_status = 'V' support_team_id = 'TEST_A' )
      ( client = sy-mandt ticket_id = '00000003' requester_user = user
        assigned_agent_user = user support_team_id = 'TEST_A' )
      ( client = sy-mandt ticket_id = '00000004' migration_status = 'V'
        assigned_agent_user = user support_team_id = 'TEST_B' )
      ( client = sy-mandt ticket_id = '00000005' migration_status = 'V'
        requester_user = user )
      ( client = sy-mandt ticket_id = '00000006' migration_status = 'V'
        assigned_agent_user = user support_team_id = 'TEST_C' ) ).
    teams = VALUE #(
      ( client = sy-mandt support_team_id = 'TEST_A' is_active = abap_true )
      ( client = sy-mandt support_team_id = 'TEST_B' is_active = abap_true )
      ( client = sy-mandt support_team_id = 'TEST_C' is_active = abap_false ) ).
    members = VALUE #(
      ( client = sy-mandt support_team_id = 'TEST_A' business_user = user is_active = abap_true )
      ( client = sy-mandt support_team_id = 'TEST_B' business_user = user is_active = abap_false )
      ( client = sy-mandt support_team_id = 'TEST_C' business_user = user is_active = abap_true ) ).
    environment->insert_test_data( i_data = tickets ).
    environment->insert_test_data( i_data = teams ).
    environment->insert_test_data( i_data = members ).
  ENDMETHOD.

  METHOD teardown.
    IF environment IS BOUND.
      environment->destroy( ).
    ENDIF.
  ENDMETHOD.

  METHOD no_grant.
    environment->get_access_control_double( )->enable_access_control(
      cl_cds_test_data=>create_access_control_data( VALUE #( ) ) ).
    SELECT COUNT( * ) FROM zi_nvd_ticket_read_scope INTO @DATA(ticket_count).
    cl_abap_unit_assert=>assert_initial( ticket_count ).
  ENDMETHOD.

  METHOD requester_scope.
    environment->get_access_control_double( )->enable_access_control(
      cl_cds_test_data=>create_access_control_data(
        VALUE #( ( object = 'ZNVD_OWN' authorizations = VALUE #(
          ( VALUE #( ( fieldname = 'ACTVT' fieldvalues = VALUE #( ( lower_value = '03' ) ) ) ) ) ) ) ) ) ).
    DATA tickets TYPE ticket_ids.
    SELECT TicketID FROM zi_nvd_ticket_read_scope ORDER BY TicketID INTO TABLE @tickets.
    cl_abap_unit_assert=>assert_equals( act = tickets
      exp = VALUE ticket_ids( ( CONV #( '00000001' ) ) ( CONV #( '00000005' ) ) ) ).
  ENDMETHOD.

  METHOD agent_scope.
    environment->get_access_control_double( )->enable_access_control(
      cl_cds_test_data=>create_access_control_data(
        VALUE #( ( object = 'ZNVD_AGT' authorizations = VALUE #( ( VALUE #(
          ( fieldname = 'ACTVT' fieldvalues = VALUE #( ( lower_value = '03' ) ) )
          ( fieldname = 'ZNVD_TEAM' fieldvalues = VALUE #(
            ( lower_value = 'TEST_A' ) ( lower_value = 'TEST_B' ) ( lower_value = 'TEST_C' ) ) ) ) ) ) ) ) ) ).
    DATA tickets TYPE ticket_ids.
    SELECT TicketID FROM zi_nvd_ticket_read_scope ORDER BY TicketID INTO TABLE @tickets.
    cl_abap_unit_assert=>assert_equals( act = tickets exp = VALUE ticket_ids( ( CONV #( '00000001' ) ) ) ).
  ENDMETHOD.

  METHOD manager_scope.
    environment->get_access_control_double( )->enable_access_control(
      cl_cds_test_data=>create_access_control_data(
        VALUE #( ( object = 'ZNVD_TKT' authorizations = VALUE #( ( VALUE #(
          ( fieldname = 'ACTVT' fieldvalues = VALUE #( ( lower_value = '03' ) ) )
          ( fieldname = 'ZNVD_TEAM' fieldvalues = VALUE #(
            ( lower_value = 'TEST_A' ) ( lower_value = 'TEST_C' ) ) ) ) ) ) ) ) ) ).
    DATA tickets TYPE ticket_ids.
    SELECT TicketID FROM zi_nvd_ticket_read_scope ORDER BY TicketID INTO TABLE @tickets.
    cl_abap_unit_assert=>assert_equals( act = tickets
      exp = VALUE ticket_ids( ( CONV #( '00000001' ) ) ( CONV #( '00000002' ) ) ) ).
  ENDMETHOD.
ENDCLASS.

CLASS ltc_assignment_read_scope DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    DATA environment TYPE REF TO if_cds_test_environment.
    TYPES proposal_ids TYPE STANDARD TABLE OF sysuuid_x16 WITH EMPTY KEY.
    METHODS setup.
    METHODS teardown.
    METHODS no_grant FOR TESTING.
    METHODS target_agent_sees_own FOR TESTING.
    METHODS manager_sees_team FOR TESTING.
ENDCLASS.

CLASS ltc_assignment_read_scope IMPLEMENTATION.
  METHOD setup.
    environment = cl_cds_test_environment=>create( i_for_entity = 'ZR_NVD_ASSIGN_PROP' ).
    DATA(current_user) = cl_abap_context_info=>get_user_technical_name( ).
    DATA tickets TYPE STANDARD TABLE OF zticket_item_03 WITH EMPTY KEY.
    DATA teams TYPE STANDARD TABLE OF znvd_team WITH EMPTY KEY.
    DATA members TYPE STANDARD TABLE OF znvd_team_member WITH EMPTY KEY.
    DATA proposals TYPE STANDARD TABLE OF znvd_assign_prop WITH EMPTY KEY.
    tickets = VALUE #(
      ( client = sy-mandt ticket_id = '00000001' migration_status = 'V' support_team_id = 'TEST_A' )
      ( client = sy-mandt ticket_id = '00000002' migration_status = 'V' support_team_id = 'TEST_A' )
      ( client = sy-mandt ticket_id = '00000003' support_team_id = 'TEST_A' )
      ( client = sy-mandt ticket_id = '00000004' migration_status = 'V' support_team_id = 'TEST_B' ) ).
    teams = VALUE #( ( client = sy-mandt support_team_id = 'TEST_A' is_active = abap_true )
                     ( client = sy-mandt support_team_id = 'TEST_B' is_active = abap_true ) ).
    members = VALUE #( ( client = sy-mandt support_team_id = 'TEST_A' business_user = current_user is_active = abap_true )
                       ( client = sy-mandt support_team_id = 'TEST_B' business_user = current_user is_active = abap_false ) ).
    proposals = VALUE #(
      ( client = sy-mandt proposal_uuid = '00000000000000000000000000000001'
        ticket_id = '00000001' proposal_status = 'P' support_team_id = 'TEST_A' target_agent = current_user proposed_by = current_user )
      ( client = sy-mandt proposal_uuid = '00000000000000000000000000000002'
        ticket_id = '00000002' proposal_status = 'D' support_team_id = 'TEST_A' target_agent = current_user proposed_by = current_user )
      ( client = sy-mandt proposal_uuid = '00000000000000000000000000000003'
        ticket_id = '00000003' proposal_status = 'P' support_team_id = 'TEST_A' target_agent = current_user proposed_by = current_user )
      ( client = sy-mandt proposal_uuid = '00000000000000000000000000000004'
        ticket_id = '00000004' proposal_status = 'P' support_team_id = 'TEST_B' target_agent = current_user proposed_by = current_user )
      ( client = sy-mandt proposal_uuid = '00000000000000000000000000000005'
        ticket_id = '00000001' proposal_status = 'P' support_team_id = 'TEST_A' proposed_by = current_user ) ).
    environment->insert_test_data( i_data = tickets ).
    environment->insert_test_data( i_data = teams ).
    environment->insert_test_data( i_data = members ).
    environment->insert_test_data( i_data = proposals ).
  ENDMETHOD.

  METHOD teardown.
    IF environment IS BOUND.
      environment->destroy( ).
    ENDIF.
  ENDMETHOD.

  METHOD no_grant.
    environment->get_access_control_double( )->enable_access_control(
      cl_cds_test_data=>create_access_control_data( VALUE #( ) ) ).
    SELECT COUNT( * ) FROM zr_nvd_assign_prop INTO @DATA(visible).
    cl_abap_unit_assert=>assert_initial( visible ).
  ENDMETHOD.

  METHOD target_agent_sees_own.
    environment->get_access_control_double( )->enable_access_control(
      cl_cds_test_data=>create_access_control_data(
        VALUE #( ( object = 'ZNVD_AGT' authorizations = VALUE #( ( VALUE #(
          ( fieldname = 'ACTVT' fieldvalues = VALUE #( ( lower_value = '02' ) ) )
          ( fieldname = 'ZNVD_TEAM' fieldvalues = VALUE #(
            ( lower_value = 'TEST_A' ) ( lower_value = 'TEST_B' ) ) ) ) ) ) ) ) ) ).
    DATA ids TYPE proposal_ids.
    SELECT ProposalUUID FROM zr_nvd_assign_prop ORDER BY ProposalUUID INTO TABLE @ids.
    cl_abap_unit_assert=>assert_equals( act = ids exp = VALUE proposal_ids(
      ( CONV #( '00000000000000000000000000000001' ) ) ) ).
  ENDMETHOD.

  METHOD manager_sees_team.
    environment->get_access_control_double( )->enable_access_control(
      cl_cds_test_data=>create_access_control_data(
        VALUE #( ( object = 'ZNVD_TKT' authorizations = VALUE #( ( VALUE #(
          ( fieldname = 'ACTVT' fieldvalues = VALUE #( ( lower_value = '02' ) ) )
          ( fieldname = 'ZNVD_TEAM' fieldvalues = VALUE #( ( lower_value = 'TEST_A' ) ) ) ) ) ) ) ) ) ).
    DATA ids TYPE proposal_ids.
    SELECT ProposalUUID FROM zr_nvd_assign_prop ORDER BY ProposalUUID INTO TABLE @ids.
    cl_abap_unit_assert=>assert_equals( act = ids exp = VALUE proposal_ids(
      ( CONV #( '00000000000000000000000000000001' ) )
      ( CONV #( '00000000000000000000000000000002' ) )
      ( CONV #( '00000000000000000000000000000005' ) ) ) ).
  ENDMETHOD.
ENDCLASS.
