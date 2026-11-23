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
ENDCLASS.