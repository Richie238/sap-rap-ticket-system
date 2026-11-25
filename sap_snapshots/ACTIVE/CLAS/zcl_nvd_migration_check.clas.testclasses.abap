CLASS ltc_migration_inventory DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS empty_mapping FOR TESTING.
    METHODS unknown_mapping FOR TESTING.
ENDCLASS.

CLASS ltc_migration_inventory IMPLEMENTATION.
  METHOD empty_mapping.
    SELECT COUNT( * ) FROM zticket_item_03 INTO @DATA(tickets).
    SELECT COUNT( * ) FROM ztckt_itm_0000_d INTO @DATA(drafts).
    DATA(summary) = zcl_nvd_migration_check=>check_assignments( VALUE #( ) ).
    cl_abap_unit_assert=>assert_equals( act = summary-total exp = tickets ).
    cl_abap_unit_assert=>assert_equals( act = summary-missing exp = tickets ).
    cl_abap_unit_assert=>assert_equals( act = summary-open_drafts exp = drafts ).
    cl_abap_unit_assert=>assert_initial( summary-unique ).
  ENDMETHOD.

  METHOD unknown_mapping.
    DATA(candidate) = CONV zticket_item_03-ticket_id( '00000000' ).
    SELECT SINGLE ticket_id FROM zticket_item_03 WHERE ticket_id = @candidate INTO @DATA(found).
    IF sy-subrc = 0.
      cl_abap_unit_assert=>fail( 'Test requires an unused ticket key.' ).
    ENDIF.
    DATA(summary) = zcl_nvd_migration_check=>check_assignments(
      VALUE #( ( ticket_id = candidate ) ) ).
    cl_abap_unit_assert=>assert_equals( act = summary-unknown_tickets exp = 1 ).
    cl_abap_unit_assert=>assert_initial( summary-unique ).
  ENDMETHOD.
ENDCLASS.

CLASS ltc_migration_classification DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    CLASS-DATA environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS classifies_all_outcomes FOR TESTING.
ENDCLASS.

CLASS ltc_migration_classification IMPLEMENTATION.
  METHOD class_setup.
    environment = cl_osql_test_environment=>create(
      VALUE #( ( 'ZTICKET_ITEM_03' ) ( 'ZTCKT_ITM_0000_D' )
               ( 'ZNVD_TEAM' ) ( 'ZNVD_TEAM_MEMBER' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    environment->destroy( ).
  ENDMETHOD.

  METHOD classifies_all_outcomes.
    DATA tickets TYPE STANDARD TABLE OF zticket_item_03 WITH EMPTY KEY.
    DATA teams TYPE STANDARD TABLE OF znvd_team WITH EMPTY KEY.
    DATA members TYPE STANDARD TABLE OF znvd_team_member WITH EMPTY KEY.
    DATA(test_user) = cl_abap_context_info=>get_user_technical_name( ).

    tickets = VALUE #( ( client = sy-mandt ticket_id = '00000001' )
                       ( client = sy-mandt ticket_id = '00000002' )
                       ( client = sy-mandt ticket_id = '00000003' )
                       ( client = sy-mandt ticket_id = '00000004' )
                       ( client = sy-mandt ticket_id = '00000005' ) ).
    teams = VALUE #( ( client = sy-mandt support_team_id = 'UT_TEAM' is_active = abap_true ) ).
    members = VALUE #( ( client = sy-mandt support_team_id = 'UT_TEAM'
                         business_user = test_user is_active = abap_false ) ).
    environment->insert_test_data( tickets ).
    environment->insert_test_data( teams ).
    environment->insert_test_data( members ).

    DATA(summary) = zcl_nvd_migration_check=>check_assignments(
      VALUE #( ( ticket_id = '00000001' requester_user = test_user support_team_id = 'UT_TEAM' )
               ( ticket_id = '00000002' requester_user = test_user support_team_id = 'UT_TEAM' )
               ( ticket_id = '00000002' requester_user = test_user support_team_id = 'UT_TEAM' )
               ( ticket_id = '00000004' support_team_id = 'UT_TEAM' )
               ( ticket_id = '00000005' requester_user = test_user support_team_id = 'UT_TEAM'
                 assigned_agent_user = test_user ) ) ).

    cl_abap_unit_assert=>assert_equals( act = summary-total exp = 5 ).
    cl_abap_unit_assert=>assert_equals( act = summary-unique exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = summary-ambiguous exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = summary-missing exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = summary-invalid exp = 2 ).
    cl_abap_unit_assert=>assert_initial( summary-unknown_tickets ).
  ENDMETHOD.
ENDCLASS.

CLASS ltc_draft_read_gate DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS normal_cds_select_is_empty FOR TESTING.
ENDCLASS.

CLASS ltc_draft_read_gate IMPLEMENTATION.
  METHOD normal_cds_select_is_empty.
    SELECT COUNT( * ) FROM zr_nvd_ticket_dq INTO @DATA(tickets).
    SELECT COUNT( * ) FROM zr_nvd_attachment_dq INTO @DATA(attachments).
    cl_abap_unit_assert=>assert_initial( tickets ).
    cl_abap_unit_assert=>assert_initial( attachments ).
  ENDMETHOD.
ENDCLASS.
