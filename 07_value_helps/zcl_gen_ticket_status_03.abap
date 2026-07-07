CLASS zcl_gen_ticket_status_03 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

  INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gen_ticket_status_03 IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    DELETE FROM zticket_status.

    INSERT zticket_status FROM TABLE @( VALUE #(

    ( client = sy-mandt status = 'O' status_text = 'Offen' )
    ( client = Sy-mandt status = 'B' status_text = 'In Bearbeitung' )
    ( client = sy-mandt  status = 'G'  status_text = 'Geschlossen' )
          ( client = sy-mandt  status = 'L'  status_text = 'Gelöst' )
     ) ).

    COMMIT WORK.
    out->write( 'Status-Werte erfolgreich angelegt.' ).

  ENDMETHOD.

ENDCLASS.
