CLASS lhc_ZI_BILLING_EWB_ST DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

*    METHODS get_instance_features FOR INSTANCE FEATURES
*      IMPORTING keys REQUEST requested_features FOR zi_billing_ewb_st RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_billing_ewb_st RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zi_billing_ewb_st RESULT result.

    METHODS createewb FOR MODIFY
      IMPORTING keys FOR ACTION zi_billing_ewb_st~createewb RESULT result.
    METHODS cirn FOR MODIFY
      IMPORTING keys FOR ACTION zi_billing_ewb_st~cirn RESULT result.

*    METHODS cirn FOR MODIFY
*      IMPORTING keys FOR ACTION zi_billing_ewb_st~cirn RESULT result.
*
*    METHODS CreateEWB FOR MODIFY
*      IMPORTING keys FOR ACTION zi_billing_ewb_st~CreateEWB RESULT result.

ENDCLASS.

CLASS lhc_ZI_BILLING_EWB_ST IMPLEMENTATION.

*  METHOD get_instance_features.
*  ENDMETHOD.

  METHOD get_instance_authorizations.

  ENDMETHOD.

  METHOD get_instance_features.

  " Read the active flag of the existing members
    READ ENTITIES OF zi_billing_ewb_st IN LOCAL MODE
        ENTITY zi_billing_ewb_st
          FIELDS ( irn IrnStatus EbillNo Status ) WITH CORRESPONDING #( keys )
        RESULT DATA(members)
        FAILED failed.

    result = VALUE #(
     FOR member IN members ( %key  = member-%key


      %features-%action-CreateEWB  = COND #( WHEN member-EbillNo IS NOT INITIAL
                             THEN if_abap_behv=>fc-o-disabled
                             ELSE if_abap_behv=>fc-o-enabled )

      %features-%action-cirn  = COND #( WHEN ( member-EbillNo IS INITIAL )
                                THEN if_abap_behv=>fc-o-disabled
                                ELSE if_abap_behv=>fc-o-enabled )


     ) ).

  ENDMETHOD.

  METHOD createewb.

    DATA: lt_data TYPE TABLE FOR UPDATE zi_billing_ewb_st.

    TYPES: BEGIN OF ty_msg,
             typ(1)   TYPE c,
             vbeln    TYPE zchar,
             msg(100) TYPE c,
           END OF ty_msg.

    DATA : lt_msg TYPE STANDARD TABLE OF ty_msg,
           ls_msg TYPE ty_msg.

    READ ENTITIES OF zi_billing_ewb_st IN LOCAL MODE
    ENTITY zi_billing_ewb_st
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(header).

    DATA(lt_keys) = keys.

    DATA : obj_data  TYPE REF TO zcl_expoundtax_einvvoice_st,
           ls_res    TYPE string,
           lv_status TYPE c.

    LOOP AT header ASSIGNING FIELD-SYMBOL(<fs>).

      CREATE OBJECT obj_data.

      obj_data->generate_eway1(
        EXPORTING im_vbeln        = <fs>-billingdocument
        IMPORTING ex_response     = ls_res
                  ex_status       = lv_status
                  es_error_log    = zbp_i_billing_ewb=>wa_error_log
                  es_ew_ewaybill  = zbp_i_billing_ewb=>wa_ew_ewaybill ).

      IF lv_status   = 'E'.
        ls_msg-typ   = 'E'.
        ls_msg-vbeln = <fs>-billingdocument.
        ls_msg-msg = 'Error while generating E-Waybill'.
        APPEND ls_msg TO lt_msg.
        CLEAR ls_msg.

      ELSE.

        lt_data = VALUE #( (  billingdocument = <fs>-billingdocument
                              ebillno = zbp_i_billing_ewb=>wa_ew_ewaybill-ebillno
                              status  = zbp_i_billing_ewb=>wa_ew_ewaybill-status
                              %control = VALUE #( billingdocument = if_abap_behv=>mk-on
                                                  irn = if_abap_behv=>mk-on  ) ) ).

        MODIFY ENTITIES OF zi_billing_ewb_st IN LOCAL MODE
        ENTITY zi_billing_ewb_st UPDATE FROM lt_data
        MAPPED DATA(it_mapped)
        FAILED DATA(it_failed)
        REPORTED DATA(it_reported).

        ls_msg-typ   = 'S'.
        ls_msg-vbeln = <fs>-billingdocument.
        ls_msg-msg = 'E-Waybill Generated Succesfully'.
        APPEND ls_msg TO lt_msg.
        CLEAR ls_msg.

      ENDIF.

    ENDLOOP.

    LOOP AT lt_msg INTO ls_msg.
      IF ls_msg-typ = 'S'.
        APPEND VALUE #(   %cid = ls_msg-vbeln
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                             text = 'E-Waybill Generated Succesfully' )
                                %element = VALUE #(  irn  = if_abap_behv=>mk-on  ) )
                                TO reported-zi_billing_ewb_st.
      ELSEIF ls_msg-typ = 'E'.
        APPEND VALUE #(   %cid = ls_msg-vbeln
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                             text = 'Error while generating E-Waybill' )
                                %element = VALUE #(  irn  = if_abap_behv=>mk-off  ) )
                                TO reported-zi_billing_ewb_st.
      ENDIF.

    ENDLOOP.


  ENDMETHOD.

  METHOD CIRN.

  DATA: lt_data TYPE TABLE FOR UPDATE zi_billing_ewb_st.

    TYPES: BEGIN OF ty_msg,
             typ(1)   TYPE c,
             vbeln    TYPE zchar,
             msg(100) TYPE c,
           END OF ty_msg.

    DATA : lt_msg TYPE STANDARD TABLE OF ty_msg,
           ls_msg TYPE ty_msg.

    READ ENTITIES OF zi_billing_ewb_st IN LOCAL MODE
    ENTITY zi_billing_ewb_st
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(header).

    DATA(lt_keys) = keys.

    DATA : obj_data  TYPE REF TO zcl_expoundtax_ewaybill,
           ls_res    TYPE string,
           lv_status TYPE c.

    LOOP AT header ASSIGNING FIELD-SYMBOL(<fs>).

      CREATE OBJECT obj_data.

      obj_data->cancel_eway(
        EXPORTING im_vbeln        = <fs>-billingdocument
        IMPORTING ex_response     = ls_res
                  ex_status       = lv_status
                  es_error_log    = zbp_i_billing_ewb=>wa_error_log
                  es_ew_ewaybill  = zbp_i_billing_ewb=>wa_ew_ewaybill ).

      IF lv_status   = 'E'.
        ls_msg-typ   = 'E'.
        ls_msg-vbeln = <fs>-billingdocument.
        ls_msg-msg = 'Error while cancelling E-Waybill'.
        APPEND ls_msg TO lt_msg.
        CLEAR ls_msg.

      ELSE.

        lt_data = VALUE #( (  billingdocument = <fs>-billingdocument
                              ebillno = zbp_i_billing_ewb=>wa_ew_ewaybill-ebillno
                              status  = zbp_i_billing_ewb=>wa_ew_ewaybill-status
                              %control = VALUE #( billingdocument = if_abap_behv=>mk-on
                                                  irn = if_abap_behv=>mk-on  ) ) ).

        MODIFY ENTITIES OF zi_billing_ewb_st IN LOCAL MODE
        ENTITY zi_billing_ewb_st UPDATE FROM lt_data
        MAPPED DATA(it_mapped)
        FAILED DATA(it_failed)
        REPORTED DATA(it_reported).

        ls_msg-typ   = 'S'.
        ls_msg-vbeln = <fs>-billingdocument.
        ls_msg-msg = 'E-Waybill Cancelled Succesfully'.
        APPEND ls_msg TO lt_msg.
        CLEAR ls_msg.

      ENDIF.

    ENDLOOP.

    LOOP AT lt_msg INTO ls_msg.
      IF ls_msg-typ = 'S'.
        APPEND VALUE #(   %cid = ls_msg-vbeln
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                             text = 'E-Waybill Cancelled Succesfully' )
                                %element = VALUE #(  irn  = if_abap_behv=>mk-on  ) )
                                TO reported-zi_billing_ewb_st.
      ELSEIF ls_msg-typ = 'E'.
        APPEND VALUE #(   %cid = ls_msg-vbeln
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                             text = 'Error while Cancelling E-Waybill' )
                                %element = VALUE #(  irn  = if_abap_behv=>mk-off  ) )
                                TO reported-zi_billing_ewb_st.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

*  METHOD cirn.
*  ENDMETHOD.
*
*  METHOD CreateEWB.
*  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_BILLING_EWB_ST DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.


    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_BILLING_EWB_ST IMPLEMENTATION.

  METHOD save_modified.

    IF zbp_i_billing_ewb=>wa_error_log IS NOT INITIAL.
      MODIFY ztsd_ew_log FROM @zbp_i_billing_ewb=>wa_error_log.
    ENDIF.

    IF zbp_i_billing_ewb=>wa_ew_ewaybill IS NOT INITIAL.
      MODIFY zew_ewaybill FROM @zbp_i_billing_ewb=>wa_ew_ewaybill.
    ENDIF.

    IF zbp_i_billing_ewb=>wa_einv_json IS NOT INITIAL.
      MODIFY ztsd_einv_json FROM @zbp_i_billing_ewb=>wa_einv_json.
    ENDIF.


  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.


*  METHOD save_modified.
*  ENDMETHOD.
*
*  METHOD cleanup_finalize.
*  ENDMETHOD.

ENDCLASS.
