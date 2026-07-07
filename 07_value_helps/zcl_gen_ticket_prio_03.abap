CLASS zcl_gen_ticket_prio_03 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

  interfaces if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gen_ticket_prio_03 IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    DELETE FROM zticket_prio_03.

    INSERT zticket_prio_03 FROM TABLE @( VALUE #(

    ( client = sy-mandt priority = '1' priority_text = 'niedrig' )
    ( client = sy-mandt priority = '2' priority_text = 'Mittel' )
    ( client = sy-mandt priority = '3' priority_text = 'Hoch' )
    ( client = sy-mandt priority = '4' priority_text = 'Dringend' )

     )
    ).
    COMMIT WORK.
    out->write( 'Prioritätswerte erfolgreich angelegt.' ).
  ENDMETHOD.

ENDCLASS.
