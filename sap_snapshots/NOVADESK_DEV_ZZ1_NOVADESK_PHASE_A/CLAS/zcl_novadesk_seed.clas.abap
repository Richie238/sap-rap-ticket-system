CLASS zcl_novadesk_seed DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_novadesk_seed IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    IF sy-mandt <> '100'.
      out->write( 'NovaDesk-Initialisierung ist nur in Mandant 100 vorgesehen.' ).
      RETURN.
    ENDIF.

    DATA inserted TYPE i.

    DATA seed_zticket_cat_03 TYPE STANDARD TABLE OF zticket_cat_03 WITH EMPTY KEY.
    seed_zticket_cat_03 = VALUE #(
      ( client = sy-mandt category = 'C' category_text = 'Change Request' )
      ( client = sy-mandt category = 'I' category_text = 'Incident' )
      ( client = sy-mandt category = 'H' category_text = 'Hardware' )
      ( client = sy-mandt category = 'S' category_text = 'Software' )
      ( client = sy-mandt category = 'A' category_text = 'Access Request' )
    ).
    INSERT zticket_cat_03 FROM TABLE @seed_zticket_cat_03 ACCEPTING DUPLICATE KEYS.
    inserted += sy-dbcnt.

    DATA seed_zticket_prio_03 TYPE STANDARD TABLE OF zticket_prio_03 WITH EMPTY KEY.
    seed_zticket_prio_03 = VALUE #(
      ( client = sy-mandt priority = '1' priority_text = 'Niedrig' )
      ( client = sy-mandt priority = '2' priority_text = 'Mittel' )
      ( client = sy-mandt priority = '3' priority_text = 'Hoch' )
      ( client = sy-mandt priority = '4' priority_text = 'Dringend' )
    ).
    INSERT zticket_prio_03 FROM TABLE @seed_zticket_prio_03 ACCEPTING DUPLICATE KEYS.
    inserted += sy-dbcnt.

    DATA seed_zticket_status TYPE STANDARD TABLE OF zticket_status WITH EMPTY KEY.
    seed_zticket_status = VALUE #(
      ( client = sy-mandt status = 'O' status_text = 'Offen' )
      ( client = sy-mandt status = 'B' status_text = 'In Bearbeitung' )
      ( client = sy-mandt status = 'G' status_text = 'Geschlossen' )
      ( client = sy-mandt status = 'L' status_text = 'Gelöst' )
    ).
    INSERT zticket_status FROM TABLE @seed_zticket_status ACCEPTING DUPLICATE KEYS.
    inserted += sy-dbcnt.

    COMMIT WORK.
    out->write( |Neue Referenzwerte: { inserted }| ).
  ENDMETHOD.
ENDCLASS.
