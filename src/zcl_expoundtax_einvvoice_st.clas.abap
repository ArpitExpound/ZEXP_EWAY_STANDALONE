CLASS zcl_expoundtax_einvvoice_st DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA : gv_exp TYPE c.

    DATA : lv_str TYPE string.

    DATA : it_data      TYPE TABLE OF zsdst_eway_bill,
           wa_data      TYPE zsdst_eway_bill,
           it_data1     TYPE TABLE OF zei_eway_st1,
           wa_data1     TYPE zei_eway_st1,
           itemlist     TYPE ZEWAY_ST_tt1,
           wa_itemlist  TYPE zei_eway_st1_itm,
           it_ewb       TYPE TABLE OF zew_ewaybill,
           wa_ewb       TYPE zew_ewaybill,
           it_error_log TYPE TABLE OF ztsd_ew_log,
           wa_error_log TYPE ztsd_ew_log.

    DATA : json TYPE string.

    DATA : lv_buyer       TYPE i_customer-customer,
           lv_soldtoparty TYPE i_customer-customer,
           wa_vbrk        TYPE i_billingdocument.

    DATA : gv_gstin       TYPE string,
           gv_contenttype TYPE string VALUE 'application/json',
           gv_username    TYPE string,
           gv_token       TYPE string.

    DATA:
      it_zei_api_url  TYPE STANDARD TABLE OF zei_api_url,
      wa_zei_api_url  TYPE zei_api_url,
      lv_access_token TYPE string,
      lv_url_post     TYPE string,
      lv_access       TYPE string,
      lv_compid       TYPE string.

    DATA : lv_billto_shipto TYPE c,
           lv_billfr_dispfr TYPE c.
    DATA : lv_owner_id TYPE string.

    DATA : lv_token       TYPE string,
           lv_monthyear   TYPE string,
           lv_gstin       TYPE string,
           iv_gstin_tr    TYPE string,
           iv_name_tr     TYPE string,
           iv_distance    TYPE string,
           lv_mvapikey    TYPE string,
           lv_mvsecretkey TYPE string,
           lv_username    TYPE string,
           lv_password    TYPE string.

    DATA: lv_url_get               TYPE string,
          lv_auth_body             TYPE string,
          lv_content_length_value  TYPE i,
          lv_http_return_code      TYPE i,
          lv_http_error_descr      TYPE string,
          lv_http_error_descr_long TYPE xstring,
          lv_xml_result_str        TYPE string,
          lv_response              TYPE string,
          lv_stat                  TYPE c,
          lv_doc_status            TYPE string,
          lv_error_response        TYPE string,
          lv_govt_response         TYPE string,
          lv_success               TYPE c,
          lv_ackno                 TYPE string,
          lv_ackdt(19)             TYPE c,
          lv_irn                   TYPE string,
          lv_ewaybill_irn          TYPE string,
          lv_ewbdt                 TYPE string,
          lv_ewbdt1                TYPE string,
          lv_status                TYPE string,
          lv_cancldt               TYPE string,
          lv_valid_till            TYPE string,
          lv_signedinvoice         TYPE string,
          lv_signedqrcode          TYPE string.

    DATA: wa_zsdt_invrefnum TYPE zei_invrefnum,
          lt_irn            TYPE STANDARD TABLE OF zei_invrefnum,
          ls_irn            TYPE zei_invrefnum,
          wa_zsdt_ewaybill  TYPE zew_ewaybill,
          wa_ztsd_ew_log    TYPE ztsd_ew_log.

    DATA : lv_no(16) TYPE c.

    DATA : v1(20)       TYPE c,
           v2(20)       TYPE c,
           lv_date      TYPE d,
           lv_time      TYPE t,
           lv_date1(10) TYPE c,
           lv_cancel    TYPE c.

    DATA: lv_vbeln(10) TYPE c.

    METHODS:
      create_eway_with_irn IMPORTING im_vbeln TYPE zchar10,
      create_eway_without_irn IMPORTING im_vbeln TYPE zchar10.

    METHODS: generate_eway1
      IMPORTING im_vbeln       TYPE zchar10
      EXPORTING ex_response    TYPE string
                ex_status      TYPE c
                es_error_log   TYPE ztsd_ew_log
                es_ew_ewaybill TYPE zew_ewaybill.

    METHODS: cancel_eway
      IMPORTING im_vbeln       TYPE zchar10
      EXPORTING ex_response    TYPE string
                ex_status      TYPE c
                es_error_log   TYPE ztsd_ew_log
                es_ew_ewaybill TYPE zew_ewaybill..

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_EXPOUNDTAX_EINVVOICE_ST IMPLEMENTATION.


  METHOD cancel_eway.
    DATA : cancelrsncode TYPE string  VALUE '1',
           cancelrmrk    TYPE string  VALUE 'DATA_ENTRY_MISTAKE',
           ewbno(12)     TYPE c,
           lv_ewbnumber  TYPE string.

    lv_vbeln = im_vbeln.

    CLEAR : lv_date.
    SELECT SINGLE *
    FROM zr_ewb_trans_dtls
    WHERE billingdocument = @im_vbeln
    INTO @DATA(wa_trans_dtls).

    READ ENTITY i_billingdocumenttp
       ALL FIELDS WITH VALUE #( ( billingdocument = lv_vbeln ) )
       RESULT FINAL(billingheader)
       FAILED FINAL(failed_data1).

    READ ENTITY i_billingdocumenttp
    BY \_item
    ALL FIELDS WITH VALUE #( ( billingdocument = lv_vbeln ) )
    RESULT FINAL(billingdata)
    FAILED FINAL(failed_data).

    DATA : lv_werks TYPE i_plant-plant.
    READ TABLE billingdata INTO DATA(wa_data_n) INDEX 1.
    IF sy-subrc = 0.
      lv_werks = wa_data_n-plant.

      READ TABLE billingheader INTO DATA(wa_head) WITH KEY billingdocument =  wa_data_n-billingdocument.
      IF sy-subrc = 0.

        SELECT SINGLE businessplace
        FROM i_in_plantbusinessplacedetail
        WHERE companycode = @wa_head-companycode AND
              plant       = @lv_werks
        INTO @DATA(lv_businessplace).

        SELECT SINGLE in_gstidentificationnumber
        FROM i_in_businessplacetaxdetail
        WHERE businessplace = @lv_businessplace AND
              companycode   = @wa_head-companycode
        INTO @DATA(lv_sellergstin).

        lv_gstin = lv_sellergstin.

        CLEAR : gv_gstin, gv_username, gv_token.
        SELECT SINGLE * FROM zei_api_url_1 WHERE method = 'CAN_EWB' AND param1 = @lv_gstin INTO @DATA(ls_api_url).
        IF sy-subrc = 0.
          gv_gstin    = ls_api_url-param1.
          gv_username = ls_api_url-param2.
          gv_token    = |Token { ls_api_url-param3 }|.

        ENDIF.

      ENDIF..
    ENDIF.

    SELECT * FROM zew_ewaybill
      WHERE docno = @lv_vbeln
      AND   status IN ('A', 'P')
      INTO TABLE @DATA(it_zsdt_ewaybill).
    IF it_zsdt_ewaybill[] IS NOT INITIAL.
      SORT it_zsdt_ewaybill BY egen_dat DESCENDING egen_time DESCENDING.
      READ TABLE it_zsdt_ewaybill INTO DATA(wa_zsdt_ewaybill) INDEX 1.

      CONCATENATE '{"ewbNo":"' wa_zsdt_ewaybill-ebillno '",'
                   '"cancelRsnCode":"' cancelrsncode '",'
                   '"cancelRmrk":"' cancelrmrk '"}'
                   INTO json.


**      " Create HTTP client
      TRY.
          DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
                                   comm_scenario  = 'ZCOMM_TO_CANCEL_EWAY'
                                       service_id     = 'ZEXPTAX_EWAY_CANCEL1_REST'
                                 ).

          DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( i_destination = lo_destination ).
          DATA(lo_request) = lo_http_client->get_http_request( ).

          lo_request->set_header_field( i_name  = 'Content-Type'
                                        i_value = gv_contenttype ).

          lo_request->set_header_field( i_name  = 'Authorization'
                                        i_value = gv_token ).

          lo_request->set_header_field( i_name  = 'username'
                                        i_value = gv_username ).

          lo_request->set_header_field( i_name  = 'gstin'
                                        i_value = gv_gstin ).

          lv_content_length_value = strlen( json ).
          lo_request->set_text( i_text = json
                                i_length = lv_content_length_value ).

          DATA(lo_response) = lo_http_client->execute( i_method = if_web_http_client=>post ).
*        DATA(lv_xml) = lo_response->get_text( ).
          lv_xml_result_str = lo_response->get_text( ).
          lv_response = lv_xml_result_str.

          "capture response
          SELECT SINGLE FROM i_billingdocument
          FIELDS companycode, billingdocumentdate, billingdocumenttype
          WHERE billingdocument = @lv_vbeln
          INTO @DATA(ls_billdoc).

          CLEAR: wa_ztsd_ew_log.
          wa_ztsd_ew_log-bukrs    = ls_billdoc-companycode.
          wa_ztsd_ew_log-docno    = lv_vbeln.
          wa_ztsd_ew_log-doc_year = ls_billdoc-billingdocumentdate+0(4).
          wa_ztsd_ew_log-doc_type = ls_billdoc-billingdocumenttype.
          wa_ztsd_ew_log-method   = 'CANCEL_EWAY'.
          wa_ztsd_ew_log-erdat    = sy-datlo.
          wa_ztsd_ew_log-uzeit    = sy-timlo.
          wa_ztsd_ew_log-message  = lv_xml_result_str.

          DATA : str TYPE string.
          SPLIT lv_xml_result_str AT '"ewbStatus":"'           INTO str lv_status.
          SPLIT lv_xml_result_str AT '"ewayBillNo":'           INTO str lv_ewbnumber.
          SPLIT lv_ewbnumber      AT '"'                       INTO lv_ewbnumber str.
          SPLIT lv_xml_result_str AT 'cancelDate":"'           INTO str lv_cancldt.
          SPLIT lv_cancldt        AT '"'                       INTO lv_cancldt str. .

          IF  lv_cancldt IS NOT INITIAL.
            lv_status = 'Y'.
          ENDIF.

          IF lv_status = 'Y'.
            wa_zsdt_ewaybill-bukrs    = ls_billdoc-companycode.
            wa_zsdt_ewaybill-docno    = lv_vbeln.
            wa_zsdt_ewaybill-gjahr    = ls_billdoc-billingdocumentdate+0(4).
            wa_zsdt_ewaybill-ecan_dat    = sy-datum.
            wa_zsdt_ewaybill-ecan_time = sy-uzeit.
            wa_ztsd_ew_log-status  = 'E-Waybill Cancelled Successfully'.
            lv_response            = 'E-Waybill Cancelled Successfully'.
            lv_stat                = 'S'.
            wa_zsdt_ewaybill-status   = 'C'.
          ELSE.
            lv_stat = 'E'.
            wa_ztsd_ew_log-status  = 'Error While Generating IRN. Please Check Response inside record'.
          ENDIF.

        CATCH cx_root INTO DATA(lx_exception).
*        out->write( lx_exception->get_text( ) ).
          DATA(lvtxt) = lx_exception->get_text( ).
          lv_response = lvtxt.
      ENDTRY.
    ENDIF.

    es_ew_ewaybill = wa_zsdt_ewaybill.
    ex_response    = lv_response.
    ex_status      = lv_stat.
    es_error_log   = wa_ztsd_ew_log.

  ENDMETHOD.


  METHOD create_eway_without_irn.

    lv_vbeln = im_vbeln.

    SELECT *
      FROM ZC_BILLING_data
      WHERE BillingDocument = @lv_vbeln
      INTO TABLE @DATA(it_irn).

    READ TABLE it_irn INTO DATA(w_irn1) INDEX 1.
    IF sy-subrc = 0.

      SELECT SINGLE  plant,
                          plantname,
                          plantcustomer,
                          addressid
                         FROM i_plant
                         WHERE plant = @w_irn1-Plant
                         INTO @DATA(w_p).

      SELECT SINGLE * FROM i_address_2
               WITH PRIVILEGED ACCESS
               WHERE addressid = @w_p-addressid
               INTO @DATA(wa_address_1).

      SELECT SINGLE * FROM i_regiontext WHERE country = @wa_address_1-country
      AND region = @wa_address_1-region
      AND language = @sy-langu
     INTO @DATA(wa_region_1).



      SELECT SINGLE * FROM i_countrytext WHERE country = @wa_address_1-country
      AND language = @sy-langu
      INTO @DATA(wa_country_1).

      SELECT SINGLE *
              FROM I_BillingDocumentPartner
              WHERE BillingDocument = @w_irn1-BillingDocument
              AND PartnerFunction = 'RE'
              INTO @DATA(w_part).

      SELECT SINGLE *
            FROM I_BusinessPartner
            WHERE BusinessPartner = @w_part-Customer
              INTO @DATA(w_name1).

      SELECT SINGLE * FROM i_address_2
              WITH PRIVILEGED ACCESS
              WHERE addressid = @w_part-addressid
              INTO @DATA(wa_address_11).

      SELECT SINGLE * FROM i_regiontext WHERE country = @wa_address_11-country
      AND region = @wa_address_11-region
      AND language = @sy-langu
     INTO @DATA(wa_region_11).

      SELECT SINGLE * FROM i_countrytext WHERE country = @wa_address_11-country
      AND language = @sy-langu
      INTO @DATA(wa_country_11).

      SELECT SINGLE *
    FROM zr_ewb_trans_dtls
    WHERE billingdocument = @im_vbeln
    INTO @DATA(wa_trans_dtls).

      SELECT *
     FROM zei_state
     INTO TABLE @DATA(it_state).

      DATA : lv_state_cd(2) TYPE c.

      wa_data1-supplytype       = 'O'.
      wa_data1-subsupplydesc    = 'GODOWN TRANSFER'.
      wa_data1-doctype          = 'CHL'.
      wa_data1-docno            = w_irn1-BillingDocument.
      IF w_irn1-ReferenceSDDocumentCategory = 'J'.
        wa_data1-docno            = w_irn1-ReferenceSDDocument.
      ENDIF.
*      wa_data1-docdate          = w_irn1-BillingDocumentDate.
      CLEAR lv_date1.
      IF  w_irn1-BillingDocumentDate IS NOT INITIAL.
        lv_date1 = w_irn1-BillingDocumentDate+6(2) && '/' &&
                  w_irn1-BillingDocumentDate+4(2) && '/' &&
                  w_irn1-BillingDocumentDate+0(4).
        wa_data1-docdate = lv_date1.
      ELSE.
        CLEAR :  wa_data1-docdate.
      ENDIF.
      wa_data1-subsupplytype    = '8'.
      wa_data1-fromgstin        = w_irn1-bupla_gstin.
      wa_data1-fromtrdname      = w_irn1-PlantName.
      wa_data1-fromaddr1        =  |{ wa_address_1-streetname } | .
      wa_data1-fromaddr2        = |{ wa_address_1-streetprefixname2 }| .
      wa_data1-fromplace        = wa_region_1-regionname .
      wa_data1-frompincode      = wa_address_1-postalcode.

      CLEAR lv_state_cd.

      lv_state_cd = VALUE #( it_state[ regio = wa_address_1-region ]-statecode OPTIONAL ).

      wa_data1-actfromstatecode  = lv_state_cd .
      wa_data1-fromstatecode    = lv_state_cd .

      CLEAR lv_state_cd.

      wa_data1-togstin           = w_irn1-gstin.
      wa_data1-totrdname         = w_name1-BusinessPartnerFullName.
      wa_data1-toaddr1           = |{ wa_address_11-streetprefixname1 } | .
      wa_data1-toaddr2           = |{ wa_address_11-streetname }| .
      wa_data1-toplace           = wa_region_11-regionname .
      wa_data1-topincode         = wa_address_11-postalcode.

      lv_state_cd = VALUE #( it_state[ regio = wa_address_11-region ]-statecode OPTIONAL ).

      wa_data1-acttostatecode    = lv_state_cd .
      wa_data1-tostatecode      = lv_state_cd .
      wa_data1-transactiontype   = '1'.
      wa_data1-othervalue        = '0'.
*      wa_data1-totalvalue        = w_irn1-NetAmount.
*      taxamount.
      wa_data1-cessvalue         = ''.
      wa_data1-cessnonadvolvalue = ''.
*      wa_data1-totinvvalue       = wa_data1-totalvalue + w_irn1-igst_value + w_irn1-cgst_value + wa_data1-sgstvalue.
      wa_data1-transporterid     = wa_trans_dtls-transid.
      wa_data1-transportername   = wa_trans_dtls-transnm.
      wa_data1-transdocno        = wa_trans_dtls-lrno.
      wa_data1-transdistance     = 0.

      IF wa_address_11-postalcode = wa_address_1-postalcode.
        wa_data1-transdistance = '10'.
      ENDIF.

      CLEAR lv_date1.
      IF  wa_trans_dtls-lrdate IS NOT INITIAL.
        lv_date1 = wa_trans_dtls-lrdate+6(2) && '/' &&
                  wa_trans_dtls-lrdate+4(2) && '/' &&
                  wa_trans_dtls-lrdate+0(4).
        wa_data1-transdocdate = lv_date1.
      ELSE.
        CLEAR :  wa_data1-transdocdate.
      ENDIF.
      wa_data1-vehicleno         = w_irn1-YY1_VehicleNo2_BDH.
      wa_data1-vehicletype       = w_irn1-YY1_VehicleType_BDH.
      IF wa_data1-vehicletype+0(1) = 'R'.
        wa_data1-transmode = '1'.
      ELSE.
        wa_data1-transmode = '2'.
      ENDIF.

    ENDIF.
    DATA : lv_num(5) TYPE n,
           lv_sum    TYPE string,
           igst      TYPE dmbtr,
           cgst      TYPE dmbtr,
           sgst      TYPE dmbtr.

    CLEAR : igst,sgst,cgst,lv_num.
    CLEAR wa_data1-totinvvalue.
    LOOP AT it_irn INTO DATA(w_irn).
      lv_num = lv_num + 1.
      wa_itemlist-lineitemid = lv_num.
      wa_itemlist-productname =  w_irn-Product.
      wa_itemlist-productdesc = w_irn-BillingDocumentItemText.
      wa_itemlist-hsncode = w_irn-hsncode.
      wa_itemlist-quantity = w_irn-BillingQuantity.
      wa_itemlist-qtyunit = w_irn-BillingQuantityUnit.
      IF wa_itemlist-qtyunit = 'KG'.
        wa_itemlist-qtyunit = 'KGS'.
      ENDIF.
      wa_itemlist-cgstrate = w_irn-cgst_perc.
      wa_itemlist-sgstrate = w_irn-sgst_perc.
      wa_itemlist-igstrate = w_irn-igst_perc.
      IF w_irn-ugst_perc IS NOT INITIAL.
        wa_itemlist-sgstrate = w_irn-ugst_perc.
      ENDIF.
      wa_itemlist-cessrate = ''.
      wa_itemlist-cessnonadvol = ''.
      wa_itemlist-taxableamount = w_irn-NetAmount.
      wa_data1-totalvalue        = wa_data1-totalvalue + w_irn-NetAmount.
      igst = igst +   w_irn-igst_value.
      sgst = sgst +   w_irn-sgst_value.
      cgst = cgst +   w_irn-cgst_value.
      IF w_irn-ugst_value IS NOT INITIAL.
        sgst = sgst + w_irn-ugst_value.
      ENDIF.
      APPEND wa_itemlist TO itemlist.
      CLEAR wa_itemlist.
    ENDLOOP.
    wa_data1-totinvvalue  =  wa_data1-totalvalue + igst + sgst + cgst.
    wa_data1-cgstvalue         = cgst.
    wa_data1-sgstvalue         = sgst.
    wa_data1-igstvalue         = igst.
*      IF w_irn1-ugst_value IS NOT INITIAL.
*        wa_data1-sgstvalue = w_irn1-ugst_value.
*      ENDIF.
    wa_data1-itemlist[] = itemlist[].

    APPEND wa_data1 TO it_data1.
    CLEAR wa_data1.

    IF it_irn IS NOT INITIAL.
      DATA : lt_mapping  TYPE /ui2/cl_json=>name_mappings.
      lt_mapping = VALUE #(
                       ( abap = 'SUPPLYTYPE'     json = 'supplyType' )
                       ( abap = 'SUBSUPPLYDESC'  json = 'subSupplyDesc' )
                       ( abap = 'DOCTYPE'     json = 'docType' )
                       ( abap = 'DOCNO'     json = 'docNo' )
                       ( abap = 'DOCDATE'     json = 'docDate' )
                       ( abap = 'SUBSUPPLYTYPE'   json = 'subSupplyType' )
                       ( abap = 'FROMGSTIN'     json = 'fromGstin' )
                       ( abap = 'FROMTRDNAME'     json = 'fromTrdName' )
                       ( abap = 'FROMADDR1'     json = 'fromAddr1' )
                       ( abap = 'FROMADDR2'     json = 'fromAddr2' )
                       ( abap = 'FROMPLACE'     json = 'fromPlace' )
                       ( abap = 'FROMPINCODE'     json = 'fromPincode' )
                       ( abap = 'ACTFROMSTATECODE'     json = 'actFromStateCode' )
                       ( abap = 'FROMSTATECODE'     json = 'fromStateCode' )
                       ( abap = 'TOGSTIN'     json = 'toGstin' )
                       ( abap = 'TOTRDNAME'     json = 'toTrdName' )
                       ( abap = 'TOADDR1'     json = 'toAddr1' )
                       ( abap = 'TOADDR2'     json = 'toAddr2' )
                       ( abap = 'TOPLACE'     json = 'toPlace' )
                       ( abap = 'TOPINCODE'     json = 'toPincode' )
                       ( abap = 'ACTTOSTATECODE'     json = 'actToStateCode' )
                       ( abap = 'TOSTATECODE'     json = 'toStateCode' )
                       ( abap = 'TRANSACTIONTYPE'     json = 'transactionType' )
                       ( abap = 'OTHERVALUE'     json = 'otherValue' )
                       ( abap = 'TOTALVALUE'     json = 'totalValue' )
                       ( abap = 'CGSTVALUE'     json = 'cgstValue' )
                       ( abap = 'SGSTVALUE'     json = 'sgstValue' )
                       ( abap = 'IGSTVALUE'     json = 'igstValue' )
                       ( abap = 'CESSVALUE'     json = 'cessValue' )
                       ( abap = 'CESSNONADVOLVALUE'     json = 'cessNonAdvolValue' )
                       ( abap = 'TOTINVVALUE'     json = 'totInvValue' )
                       ( abap = 'TRANSPORTERID'     json = 'transporterId' )
                       ( abap = 'TRANSPORTERNAME'     json = 'transporterName' )
                       ( abap = 'TRANSDOCNO'     json = 'transDocNo' )
                       ( abap = 'TRANSMODE'        json = 'transMode' )
                       ( abap = 'TRANSDISTANCE'    json = 'transDistance' )
                       ( abap = 'TRANSDOCDATE'     json = 'transDocDate' )
                       ( abap = 'VEHICLENO'        json = 'vehicleNo' )
                       ( abap = 'VEHICLETYPE'      json = 'vehicleType' )
                       ( abap = 'LINEITEMID'       json = 'lineItemId' )
                       ( abap = 'PRODUCTNAME'      json = 'productName' )
                       ( abap = 'PRODUCTDESC'      json = 'productDesc' )
                       ( abap = 'HSNCODE'          json = 'hsnCode' )
                       ( abap = 'QUANTITY'         json = 'quantity' )
                       ( abap = 'QTYUNIT'          json = 'qtyUnit' )
                       ( abap = 'CGSTRATE'         json = 'cgstRate' )
                       ( abap = 'SGSTRATE'         json = 'sgstRate' )
                       ( abap = 'IGSTRATE'         json = 'igstRate' )
                       ( abap = 'CESSRATE'         json = 'cessRate' )
                       ( abap = 'CESSNONADVOL'     json = 'cessNonadvol' )
                       ( abap = 'TAXABLEAMOUNT'    json = 'taxableAmount' )
                          ).

      DATA(lv_json) = /ui2/cl_json=>serialize( data          = it_data1
                                               compress      = abap_false
                                               pretty_name   = /ui2/cl_json=>pretty_mode-camel_case
                                               name_mappings = lt_mapping ).

      REPLACE FIRST OCCURRENCE OF '[' IN lv_json WITH space.
*      REPLACE ALL OCCURRENCES OF '['               IN lv_json WITH space.
*      REPLACE ALL OCCURRENCES OF ']'               IN lv_json WITH space.
      REPLACE ALL OCCURRENCES OF '""'              IN lv_json WITH 'null'.
*      REPLACE ALL OCCURRENCES OF ':0*'             IN lv_json WITH ':null*'.
*      REPLACE ALL OCCURRENCES OF '":0,'            IN lv_json WITH '":null,'.
*      REPLACE ALL OCCURRENCES OF '":"0.00",'       IN lv_json WITH '":null,'.
      REPLACE ALL OCCURRENCES OF '"transdistance":null' IN lv_json WITH '"transdistance":0'.
      REPLACE ALL OCCURRENCES OF '"transdistance":"1"'  IN lv_json WITH '"transdistance":null'.


*     clear lv_len.
*     lv_len = lv_json1.
      TRY.
          DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
                                   comm_scenario      = 'ZCOMM_TO_CREATE_EWAY_STD'
                                       service_id     = 'ZEXPTAX_CREATE_EWAY_REST_STD_REST'
                                 ).


          DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( i_destination = lo_destination ).
          DATA(lo_request) = lo_http_client->get_http_request( ).


          SELECT SINGLE businessplace
          FROM i_in_plantbusinessplacedetail
          WHERE companycode = @w_irn1-companycode AND
                plant       = @w_irn1-Plant
          INTO @DATA(lv_businessplace).

          SELECT SINGLE in_gstidentificationnumber
          FROM i_in_businessplacetaxdetail
          WHERE businessplace = @lv_businessplace AND
                companycode   = @w_irn1-companycode
          INTO @DATA(lv_sellergstin).

          CLEAR : gv_gstin, gv_username, gv_token.
          SELECT SINGLE * FROM zei_api_url_1 WHERE method = 'GEN_EWB' AND param1 = @lv_sellergstin INTO @DATA(ls_api_url).
          IF sy-subrc = 0.
            gv_gstin    = ls_api_url-param1.
            gv_username = ls_api_url-param2.
            gv_token    = |Token { ls_api_url-param3 }|.

          ENDIF.

          lo_request->set_header_field( i_name  = 'Content-Type'
                                        i_value = gv_contenttype ).

          lo_request->set_header_field( i_name  = 'Authorization'
                                        i_value = gv_token ).

          lo_request->set_header_field( i_name  = 'username'
                                        i_value = gv_username ).

          lo_request->set_header_field( i_name  = 'gstin'
                                        i_value = gv_gstin ).

          DATA(lv_len) = strlen( lv_json ).
          lv_len = lv_len - 1.

          json = lv_json(lv_len).

*          json = lv_json.

          lv_content_length_value = strlen( json ).

          lo_request->set_text( i_text = json
                                i_length = lv_content_length_value ).

          DATA(lo_response) = lo_http_client->execute( i_method = if_web_http_client=>post ).
          lv_xml_result_str = lo_response->get_text( ).
          lv_response = lv_xml_result_str.

          "capture response
          SELECT SINGLE FROM i_billingdocument
          FIELDS companycode, billingdocumentdate, billingdocumenttype
          WHERE billingdocument = @lv_vbeln
          INTO @DATA(ls_billdoc).
          IF sy-subrc = 0.
            CLEAR: wa_ztsd_ew_log.
            wa_ztsd_ew_log-bukrs    = ls_billdoc-companycode.
            wa_ztsd_ew_log-docno    = lv_vbeln.
            wa_ztsd_ew_log-doc_year = ls_billdoc-billingdocumentdate+0(4).
            wa_ztsd_ew_log-doc_type = ls_billdoc-billingdocumenttype.
            wa_ztsd_ew_log-method   = 'GENERATE_EWAY'.
            wa_ztsd_ew_log-erdat    = sy-datlo. "sy-datum.
            wa_ztsd_ew_log-uzeit    = sy-timlo. "sy-uzeit.
            wa_ztsd_ew_log-message  = lv_xml_result_str.
          ENDIF.

          DATA : str TYPE string.
          SPLIT lv_xml_result_str AT '"document_status":"'   INTO str lv_doc_status.
          SPLIT lv_xml_result_str AT '"error_response":'     INTO str lv_error_response.
          SPLIT lv_xml_result_str AT '"govt_response":'      INTO str lv_govt_response.
          SPLIT lv_xml_result_str AT '"Success":"'           INTO str lv_success.

          SPLIT lv_xml_result_str AT '"AckNo":'              INTO str lv_ackno.
          SPLIT lv_ackno AT ','                              INTO lv_ackno str .

          SPLIT lv_xml_result_str AT '"AckDt":"'             INTO str lv_ackdt.

          SPLIT lv_xml_result_str AT '"Irn":"'               INTO str lv_irn.
          SPLIT lv_irn AT '"'                                INTO lv_irn str.

          SPLIT lv_xml_result_str AT '"ewayBillNo":'         INTO str lv_ewaybill_irn.
          SPLIT lv_ewaybill_irn  AT ','                      INTO lv_ewaybill_irn str .

          SPLIT lv_xml_result_str AT '"ewayBillDate":"'      INTO str lv_ewbdt.
          SPLIT lv_ewbdt AT '"'                              INTO lv_ewbdt str .

          SPLIT lv_xml_result_str AT '"status":"'            INTO str lv_status.

          SPLIT lv_xml_result_str AT '"validUpto":"'      INTO str lv_valid_till.
          SPLIT lv_valid_till AT '"'                         INTO lv_valid_till str .

          IF lv_ewaybill_irn IS NOT INITIAL.
            lv_success = 'Y'.
          ENDIF.

          IF  lv_ewaybill_irn IS NOT INITIAL.
            CLEAR wa_zsdt_ewaybill.
            wa_zsdt_ewaybill-bukrs     = ls_billdoc-companycode.
            wa_zsdt_ewaybill-doc_type  = ls_billdoc-billingdocumenttype.
            wa_zsdt_ewaybill-docno     = lv_vbeln.

            wa_zsdt_ewaybill-gjahr = ls_billdoc-billingdocumentdate+0(4).
            wa_zsdt_ewaybill-ebillno = lv_ewaybill_irn."gs_resp_post_topaz-response-ewbno.
            CLEAR lv_ewbdt1.
            REPLACE ALL OCCURRENCES OF '/' IN lv_ewbdt WITH space.
            CONDENSE lv_ewbdt.
            lv_ewbdt1 = lv_ewbdt(8).
            CONCATENATE lv_ewbdt1+4(4) lv_ewbdt1+2(2) lv_ewbdt1+0(2) INTO wa_zsdt_ewaybill-egen_dat.
*            wa_zsdt_ewaybill-egen_dat = lv_ewbdt(8).

            REPLACE ALL OCCURRENCES OF ':' IN lv_ewbdt WITH space.
            CONDENSE lv_ewbdt.
            wa_zsdt_ewaybill-egen_time = lv_ewbdt+9(6).

            wa_zsdt_ewaybill-vdfmdate = wa_zsdt_ewaybill-egen_dat.
            wa_zsdt_ewaybill-vdfmtime = wa_zsdt_ewaybill-egen_time.

            IF wa_zsdt_ewaybill-egen_dat IS INITIAL.
              wa_zsdt_ewaybill-egen_dat = sy-datlo. "sy-datum.
            ENDIF.
            IF wa_zsdt_ewaybill-egen_time IS INITIAL.
              wa_zsdt_ewaybill-egen_time = sy-timlo. "sy-UZeIT.
            ENDIF.

            REPLACE ALL OCCURRENCES OF '/' IN lv_valid_till WITH space.
            CONDENSE lv_valid_till.

            REPLACE ALL OCCURRENCES OF ':' IN lv_valid_till WITH space.
            CONDENSE lv_valid_till.
            CLEAR lv_ewbdt1.
            IF lv_valid_till IS NOT INITIAL.
              lv_ewbdt1 = lv_valid_till(8).
              CONCATENATE lv_ewbdt1+4(4) lv_ewbdt1+2(2) lv_ewbdt1+0(2) INTO wa_zsdt_ewaybill-vdtodate.
              wa_zsdt_ewaybill-vdtotime  = lv_valid_till+9(6).
            ENDIF.

            wa_zsdt_ewaybill-status = 'A'.
            wa_zsdt_ewaybill-ernam  = sy-uname.

            CLEAR: wa_data.
            lv_stat = 'S'.
            wa_ztsd_ew_log-status  = 'E-Waybill Generated Successfully'.
            lv_response            = 'E-Waybill Generated Successfully'.
          ELSE.
            lv_stat = 'E'.
            wa_ztsd_ew_log-status  = 'Error While Generating E-Waybill. Please Check Response inside record'.
          ENDIF.



        CATCH cx_root INTO DATA(lx_exception).
          DATA(lvtxt) = lx_exception->get_text( ).
          lv_response = lvtxt.
      ENDTRY.


    ENDIF.

  ENDMETHOD.


  METHOD create_eway_with_irn.

    DATA : lv_date(10) TYPE c.

    lv_vbeln = im_vbeln.

    CLEAR : lv_date.
    SELECT SINGLE *
    FROM zr_ewb_trans_dtls
    WHERE billingdocument = @im_vbeln
    INTO @DATA(wa_trans_dtls).

    READ ENTITY i_billingdocumenttp
       ALL FIELDS WITH VALUE #( ( billingdocument = lv_vbeln ) )
       RESULT FINAL(billingheader)
       FAILED FINAL(failed_data1).

    READ ENTITY i_billingdocumenttp
    BY \_item
    ALL FIELDS WITH VALUE #( ( billingdocument = lv_vbeln ) )
    RESULT FINAL(billingdata)
    FAILED FINAL(failed_data).

    DATA : lv_werks TYPE i_plant-plant.
    READ TABLE billingdata INTO DATA(wa_data_n) INDEX 1.
    IF sy-subrc = 0.
      lv_werks = wa_data_n-plant.

      READ TABLE billingheader INTO DATA(wa_head) WITH KEY billingdocument =  wa_data_n-billingdocument.
      IF sy-subrc = 0.

        SELECT SINGLE businessplace
        FROM i_in_plantbusinessplacedetail
        WHERE companycode = @wa_head-companycode AND
              plant       = @lv_werks
        INTO @DATA(lv_businessplace).

        SELECT SINGLE in_gstidentificationnumber
        FROM i_in_businessplacetaxdetail
        WHERE businessplace = @lv_businessplace AND
              companycode   = @wa_head-companycode
        INTO @DATA(lv_sellergstin).

        lv_gstin = lv_sellergstin.

        CLEAR : gv_gstin, gv_username, gv_token.
        SELECT SINGLE * FROM zei_api_url_1 WHERE method = 'GEN_EWB' AND param1 = @lv_gstin INTO @DATA(ls_api_url).
        IF sy-subrc = 0.
          gv_gstin    = ls_api_url-param1.
          gv_username = ls_api_url-param2.
          gv_token    = |Token { ls_api_url-param3 }|.

        ENDIF.

      ENDIF..
    ENDIF.

    IF sy-subrc = 0.
      wa_data-transid    = wa_trans_dtls-transid.
      wa_data-transname  = wa_trans_dtls-transnm.
      wa_data-vehno      = wa_trans_dtls-vehno.

      IF  wa_trans_dtls-vehtype IS NOT INITIAL.

        wa_data-vehtype    = wa_trans_dtls-vehtype+0(1).

        IF wa_data-vehtype+0(1) = 'R'.
          wa_data-transmode = '1'.
        ELSE.
          wa_data-transmode = '2'.
        ENDIF.

      ENDIF.

      IF wa_data-vehtype <> 'R'.
        CLEAR : wa_data-vehno.
      ENDIF.

      wa_data-transdocno = wa_trans_dtls-lrno.
      wa_data-irn        = ls_irn-irn.

      TRANSLATE wa_data-vehno TO UPPER CASE.

      IF  wa_trans_dtls-lrdate IS NOT INITIAL.
        lv_date = wa_trans_dtls-lrdate+6(2) && '/' &&
                  wa_trans_dtls-lrdate+4(2) && '/' &&
                  wa_trans_dtls-lrdate+0(4).
        wa_data-transdocdt = lv_date.
      ELSE.
        CLEAR :  wa_data-transdocdt.
      ENDIF.

*      read table lt_irn into data(w_irn1) index 1.
      READ TABLE billingdata INTO DATA(wa_data_n1) INDEX 1.
      IF sy-subrc = 0.
        SELECT SINGLE  addressid  FROM i_plant
          WHERE plant = @wa_data_n1-Plant
          INTO @DATA(lv_address_id).
        IF sy-subrc = 0.
          SELECT SINGLE * FROM i_organizationaddress
          WITH PRIVILEGED ACCESS
          WHERE addressid = @lv_address_id
        INTO @DATA(gs_orgaddress).
        ENDIF.
      ENDIF.

      IF ls_api_url-bukrs IS NOT INITIAL.
        SELECT SINGLE
          customer, addressid, customername, taxnumber3, country,
          streetname, cityname, postalcode, region, telephonenumber1
          FROM i_customer
          WHERE customer = @wa_head-payerparty
          INTO @DATA(wa_kna1).

        SELECT SINGLE * FROM i_organizationaddress
        WITH PRIVILEGED ACCESS
        WHERE addressid = @wa_kna1-addressid
        INTO @DATA(gs_buyaddress1).

      ENDIF.
      IF gs_buyaddress1-PostalCode =   gs_orgaddress-PostalCode.
        wa_data-distance = '10'.
      ENDIF.
      IF wa_data-distance <> '10'.
        wa_data-distance = 0.
      ENDIF.

      CONDENSE wa_data-distance NO-GAPS.

      APPEND wa_data TO it_data.

      DATA : lt_mapping  TYPE /ui2/cl_json=>name_mappings.

      lt_mapping = VALUE #(
    ( abap = 'IRN'        json = 'Irn' )
    ( abap = 'DISTANCE'   json = 'Distance' )
    ( abap = 'TRANSMODE'  json = 'TransMode' )
    ( abap = 'TRANSID'    json = 'TransId' )
    ( abap = 'TRANSNAME'  json = 'TransName' )
    ( abap = 'TRANSDOCDT' json = 'TransDocDt' )
    ( abap = 'TRANSDOCNO' json = 'TransDocNo' )
    ( abap = 'VEHNO'      json = 'VehNo' )
    ( abap = 'VEHTYPE'    json = 'VehType' )

    ).

      DATA(lv_json) = /ui2/cl_json=>serialize( data          = it_data
                                               compress      = abap_false
                                               pretty_name   = /ui2/cl_json=>pretty_mode-camel_case
                                               name_mappings = lt_mapping ).

      REPLACE ALL OCCURRENCES OF '['               IN lv_json WITH space.
      REPLACE ALL OCCURRENCES OF ']'               IN lv_json WITH space.
      REPLACE ALL OCCURRENCES OF '""'              IN lv_json WITH 'null'.
      REPLACE ALL OCCURRENCES OF ':0*'             IN lv_json WITH ':null*'.
      REPLACE ALL OCCURRENCES OF '":0,'            IN lv_json WITH '":null,'.
      REPLACE ALL OCCURRENCES OF '":"0.00",'       IN lv_json WITH '":null,'.
      REPLACE ALL OCCURRENCES OF '"Distance":null' IN lv_json WITH '"Distance":0'.
      REPLACE ALL OCCURRENCES OF '"Distance":"1"'  IN lv_json WITH '"Distance":null'.

      json = lv_json.

      " Create HTTP client
      TRY.
          DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
                                   comm_scenario      = 'ZCOMM_TO_CREATE_EWAY'
                                       service_id     = 'ZEXPTAX_CREATE_EWAY_REST'
                                 ).

          DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( i_destination = lo_destination ).
          DATA(lo_request) = lo_http_client->get_http_request( ).


          lo_request->set_header_field( i_name  = 'Content-Type'
                                        i_value = gv_contenttype ).

          lo_request->set_header_field( i_name  = 'Authorization'
                                        i_value = gv_token ).

          lo_request->set_header_field( i_name  = 'username'
                                        i_value = gv_username ).

          lo_request->set_header_field( i_name  = 'gstin'
                                        i_value = gv_gstin ).

          lv_content_length_value = strlen( json ).

          lo_request->set_text( i_text = json
                                i_length = lv_content_length_value ).

          DATA(lo_response) = lo_http_client->execute( i_method = if_web_http_client=>post ).
          lv_xml_result_str = lo_response->get_text( ).
          lv_response = lv_xml_result_str.

          "capture response
          SELECT SINGLE FROM i_billingdocument
          FIELDS companycode, billingdocumentdate, billingdocumenttype
          WHERE billingdocument = @lv_vbeln
          INTO @DATA(ls_billdoc).
          IF sy-subrc = 0.
            CLEAR: wa_ztsd_ew_log.
            wa_ztsd_ew_log-bukrs    = ls_billdoc-companycode.
            wa_ztsd_ew_log-docno    = lv_vbeln.
            wa_ztsd_ew_log-doc_year = ls_billdoc-billingdocumentdate+0(4).
            wa_ztsd_ew_log-doc_type = ls_billdoc-billingdocumenttype.
            wa_ztsd_ew_log-method   = 'GENERATE_EWAY'.
            wa_ztsd_ew_log-erdat    = sy-datlo. "sy-datum.
            wa_ztsd_ew_log-uzeit    = sy-timlo. "sy-uzeit.
            wa_ztsd_ew_log-message  = lv_xml_result_str.
          ENDIF.

          "CAPTURE RESPONSE
          DATA : str TYPE string.
          SPLIT lv_xml_result_str AT '"document_status":"'   INTO str lv_doc_status.
          SPLIT lv_xml_result_str AT '"error_response":'     INTO str lv_error_response.
          SPLIT lv_xml_result_str AT '"govt_response":'      INTO str lv_govt_response.
          SPLIT lv_xml_result_str AT '"Success":"'           INTO str lv_success.

          SPLIT lv_xml_result_str AT '"AckNo":'              INTO str lv_ackno.
          SPLIT lv_ackno AT ','                              INTO lv_ackno str .

          SPLIT lv_xml_result_str AT '"AckDt":"'             INTO str lv_ackdt.

          SPLIT lv_xml_result_str AT '"Irn":"'               INTO str lv_irn.
          SPLIT lv_irn AT '"'                                INTO lv_irn str.

          SPLIT lv_xml_result_str AT '"EwbNo":'              INTO str lv_ewaybill_irn.
          SPLIT lv_ewaybill_irn  AT ','                      INTO lv_ewaybill_irn str .

          SPLIT lv_xml_result_str AT 'EwbDt":"'              INTO str lv_ewbdt.
          SPLIT lv_ewbdt AT '"'                              INTO lv_ewbdt str .

          SPLIT lv_xml_result_str AT '"status":"'            INTO str lv_status.

          SPLIT lv_xml_result_str AT '"EwbValidTill":"'      INTO str lv_valid_till.
          SPLIT lv_valid_till AT '"'                         INTO lv_valid_till str .

          IF lv_ewaybill_irn IS NOT INITIAL.
            lv_success = 'Y'.
          ENDIF.

          IF  lv_ewaybill_irn IS NOT INITIAL.
            CLEAR wa_zsdt_ewaybill.
            wa_zsdt_ewaybill-bukrs     = ls_billdoc-companycode.
            wa_zsdt_ewaybill-doc_type  = ls_billdoc-billingdocumenttype.
            wa_zsdt_ewaybill-docno     = lv_vbeln.

            wa_zsdt_ewaybill-gjahr = ls_billdoc-billingdocumentdate+0(4).
            wa_zsdt_ewaybill-ebillno = lv_ewaybill_irn."gs_resp_post_topaz-response-ewbno.

            REPLACE ALL OCCURRENCES OF '-' IN lv_ewbdt WITH space.
            CONDENSE lv_ewbdt.
            wa_zsdt_ewaybill-egen_dat = lv_ewbdt(8).

            REPLACE ALL OCCURRENCES OF ':' IN lv_ewbdt WITH space.
            CONDENSE lv_ewbdt.
            wa_zsdt_ewaybill-egen_time = lv_ewbdt+9(6).

            wa_zsdt_ewaybill-vdfmdate = wa_zsdt_ewaybill-egen_dat.
            wa_zsdt_ewaybill-vdfmtime = wa_zsdt_ewaybill-egen_time.

            IF wa_zsdt_ewaybill-egen_dat IS INITIAL.
              wa_zsdt_ewaybill-egen_dat = sy-datlo. "sy-datum.
            ENDIF.
            IF wa_zsdt_ewaybill-egen_time IS INITIAL.
              wa_zsdt_ewaybill-egen_time = sy-timlo. "sy-UZeIT.
            ENDIF.

            REPLACE ALL OCCURRENCES OF '-' IN lv_valid_till WITH space.
            CONDENSE lv_valid_till.

            REPLACE ALL OCCURRENCES OF ':' IN lv_valid_till WITH space.
            CONDENSE lv_valid_till.

            IF lv_valid_till IS NOT INITIAL.
              wa_zsdt_ewaybill-vdtodate  = lv_valid_till(8).
              wa_zsdt_ewaybill-vdtotime  = lv_valid_till+9(6).
            ENDIF.

            wa_zsdt_ewaybill-status = 'A'.
            wa_zsdt_ewaybill-ernam  = sy-uname.

            CLEAR: wa_data.
            lv_stat = 'S'.
            wa_ztsd_ew_log-status  = 'E-Waybill Generated Successfully'.
            lv_response            = 'E-Waybill Generated Successfully'.
          ELSE.
            lv_stat = 'E'.
            wa_ztsd_ew_log-status  = 'Error While Generating E-Waybill. Please Check Response inside record'.
          ENDIF.

        CATCH cx_root INTO DATA(lx_exception).
          DATA(lvtxt) = lx_exception->get_text( ).
          lv_response = lvtxt.
      ENDTRY.
    ENDIF..

  ENDMETHOD.


  METHOD generate_eway1.

    lv_vbeln    = im_vbeln.

    SELECT SINGLE * FROM i_billingdocument
    WHERE billingdocument = @lv_vbeln
    INTO @wa_vbrk.

    IF sy-subrc = 0.

      SELECT * FROM zei_invrefnum
      WHERE docno = @lv_vbeln
      INTO TABLE @lt_irn.
      IF lt_irn[] IS NOT INITIAL.
        SORT lt_irn BY docno ASCENDING version DESCENDING.
      ENDIF.

      SELECT * FROM zew_ewaybill
      WHERE  docno = @lv_vbeln
      INTO TABLE @DATA(lt_eway).
      IF lt_eway[] IS NOT INITIAL.
        SORT lt_eway BY docno ASCENDING erdat DESCENDING uzeit DESCENDING.
      ENDIF.

      READ TABLE lt_eway INTO DATA(ls_eway) WITH KEY docno = lv_vbeln.
      IF sy-subrc NE 0 OR ( sy-subrc = 0 AND ls_eway-status = 'C' ).

        READ TABLE lt_irn INTO ls_irn WITH KEY docno = lv_vbeln BINARY SEARCH.
        IF ( sy-subrc = 0 AND ls_irn-irn IS NOT INITIAL AND ls_irn-irn_status EQ 'ACT' ).

          CALL METHOD create_eway_with_irn( im_vbeln ).

        ELSEIF ( sy-subrc NE 0 ).

          CALL METHOD create_eway_without_irn( im_vbeln ).

        ENDIF.
      ENDIF.
    ENDIF.

    ex_response    = lv_response.
    ex_status      = lv_stat.
    es_ew_ewaybill = wa_zsdt_ewaybill.
    es_error_log   = wa_ztsd_ew_log.

  ENDMETHOD.
ENDCLASS.
