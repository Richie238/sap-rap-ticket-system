CLASS zcl_gen_ticket_categ_03 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

  INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_gen_ticket_categ_03 IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    DELETE FROM zticket_cat_03.

    INSERT zticket_cat_03 FROM TABLE @( VALUE #(
    ( client = sy-mandt category = 'C' category_text = 'Change Request' )
    ( client = sy-mandt category = 'I' category_text = 'Incident' )
     ( client = sy-mandt  category = 'H'  category_text = 'Hardware' )
          ( client = sy-mandt  category = 'S'  category_text = 'Software' )
          ( client = sy-mandt  category = 'A'  category_text = 'Access Request' )
        ) ).

    COMMIT WORK.
    out->write( 'Category-Werte erfolgreich angelegt.' ).

  ENDMETHOD.

ENDCLASS.
