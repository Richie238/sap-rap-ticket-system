CLASS zcl_novadesk_nr_setup DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_novadesk_nr_setup IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    CONSTANTS object TYPE cl_numberrange_objects=>nr_object VALUE 'ZNOVATKT'.
    IF sy-mandt <> '100'.
      out->write( 'Einrichtung ist für NOVADESK_DEV, Mandant 100 vorgesehen.' ).
      RETURN.
    ENDIF.

    TRY.
        TRY.
            cl_numberrange_objects=>read(
              EXPORTING object = object
              IMPORTING attributes = DATA(attributes) ).
          CATCH cx_nr_object_not_found.
            cl_numberrange_objects=>create(
              EXPORTING
                attributes = VALUE #( object = object domlen = 'NUMC5'
                                     devclass = 'ZZ1_NOVADESK' nonrswap = abap_true
                                     buffer = 'X' noivbuffer = 10 percentage = '10' )
                obj_text = VALUE #( object = object langu = sy-langu
                                   txt = 'NovaDesk ticket numbers' txtshort = 'NovaDesk' )
              IMPORTING errors = DATA(object_errors) returncode = DATA(object_rc) ).
            IF object_rc = 'E'.
              out->write( object_errors ).
              RETURN.
            ENDIF.
            cl_numberrange_objects=>read(
              EXPORTING object = object
              IMPORTING attributes = attributes ).
        ENDTRY.

        IF attributes-domlen <> 'NUMC5'
            OR attributes-nonrswap <> abap_true OR attributes-buffer <> 'X'
            OR attributes-yearind IS NOT INITIAL OR attributes-dtelsobj IS NOT INITIAL.
          out->write( 'Unerwartete Nummernkreiseinstellungen. Einrichtung abgebrochen.' ).
          RETURN.
        ENDIF.

        cl_numberrange_intervals=>read(
          EXPORTING object = object
          IMPORTING interval = DATA(intervals) ).
        IF intervals IS INITIAL.
          SELECT SINGLE FROM zticket_item_03 FIELDS ticket_id
            WHERE ticket_id BETWEEN '00010000' AND '00099999' INTO @DATA(used_id).
          IF sy-subrc = 0.
            out->write( |Einrichtung abgebrochen: { used_id } liegt bereits im Intervall.| ).
            RETURN.
          ENDIF.

          cl_numberrange_intervals=>create(
            EXPORTING object = object
                      interval = VALUE #( ( nrrangenr = '01' toyear = '0000'
                                            fromnumber = '10000' tonumber = '99999' ) )
            IMPORTING error = DATA(interval_error) error_inf = DATA(error_info) ).
          IF interval_error IS NOT INITIAL.
            out->write( error_info ).
            RETURN.
          ENDIF.
          COMMIT WORK.
          cl_numberrange_intervals=>read(
            EXPORTING object = object
            IMPORTING interval = intervals ).
        ENDIF.

        IF lines( intervals ) <> 1.
          out->write( 'Intervall 01 konnte nicht eindeutig gelesen werden.' ).
          RETURN.
        ENDIF.
        DATA(interval) = intervals[ 1 ].
        IF interval-nrrangenr <> '01' OR CONV int8( interval-fromnumber ) <> 10000 OR CONV int8( interval-tonumber ) <> 99999
            OR interval-externind IS NOT INITIAL OR interval-toyear <> '0000'.
          out->write( 'Intervall 01 hat unerwartete Grenzen oder Eigenschaften.' ).
          RETURN.
        ENDIF.
        out->write( |{ object }/01: 10000–99999, intern, ohne Wiederanlauf.| ).
      CATCH cx_nr_object_not_found cx_number_ranges cx_sy_conversion_error INTO DATA(problem).
        out->write( problem->get_text( ) ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.