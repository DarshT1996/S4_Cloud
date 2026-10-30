CLASS LHC_RAP_TDAT_CTS DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS:
      GET
        RETURNING
          VALUE(RESULT) TYPE REF TO IF_MBC_CP_RAP_TDAT_CTS.

ENDCLASS.

CLASS LHC_RAP_TDAT_CTS IMPLEMENTATION.
  METHOD GET.
    result = mbc_cp_api=>rap_tdat_cts( tdat_name = 'ZMATERIALSHELFLIFEMA'
                                       table_entity_relations = VALUE #(
                                         ( entity = 'MaterialShelflifeMa' table = 'ZYDC_CONFIG_POC' )
                                       ) ) ##NO_TEXT.
  ENDMETHOD.
ENDCLASS.
CLASS LHC_ZI_MATERIALSHELFLIFEMA_S DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_INSTANCE_FEATURES FOR INSTANCE FEATURES
        IMPORTING
          KEYS REQUEST requested_features FOR MaterialShelflifAll
        RESULT result,
      SELECTCUSTOMIZINGTRANSPTREQ FOR MODIFY
        IMPORTING
          KEYS FOR ACTION MaterialShelflifAll~SelectCustomizingTransptReq
        RESULT result,
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR MaterialShelflifAll
        RESULT result,
      EDIT FOR MODIFY
        IMPORTING
          KEYS FOR ACTION MaterialShelflifAll~edit.
ENDCLASS.

CLASS LHC_ZI_MATERIALSHELFLIFEMA_S IMPLEMENTATION.
  METHOD GET_INSTANCE_FEATURES.
    DATA: edit_flag            TYPE abp_behv_op_ctrl    VALUE if_abap_behv=>fc-o-enabled
         ,transport_feature    TYPE abp_behv_field_ctrl VALUE if_abap_behv=>fc-f-mandatory
         ,selecttransport_flag TYPE abp_behv_op_ctrl    VALUE if_abap_behv=>fc-o-enabled.

    IF lhc_rap_tdat_cts=>get( )->is_editable( ) = abap_false.
      edit_flag = if_abap_behv=>fc-o-disabled.
    ENDIF.
    IF lhc_rap_tdat_cts=>get( )->is_transport_allowed( ) = abap_false.
      selecttransport_flag = if_abap_behv=>fc-o-disabled.
    ENDIF.
    IF lhc_rap_tdat_cts=>get( )->is_transport_mandatory( ) = abap_false.
      transport_feature = if_abap_behv=>fc-f-unrestricted.
    ENDIF.
    result = VALUE #( FOR key in keys (
               %TKY = key-%TKY
               %ACTION-edit = edit_flag
               %ASSOC-_MaterialShelflifeMa = edit_flag
               %FIELD-TransportRequestID = transport_feature
               %ACTION-SelectCustomizingTransptReq = COND #( WHEN key-%IS_DRAFT = if_abap_behv=>mk-off
                                                             THEN if_abap_behv=>fc-o-disabled
                                                             ELSE selecttransport_flag ) ) ).
  ENDMETHOD.
  METHOD SELECTCUSTOMIZINGTRANSPTREQ.
    MODIFY ENTITIES OF ZI_MaterialShelflifeMa_S IN LOCAL MODE
      ENTITY MaterialShelflifAll
        UPDATE FIELDS ( TransportRequestID )
        WITH VALUE #( FOR key IN keys
                        ( %TKY               = key-%TKY
                          TransportRequestID = key-%PARAM-transportrequestid
                         ) ).

    READ ENTITIES OF ZI_MaterialShelflifeMa_S IN LOCAL MODE
      ENTITY MaterialShelflifAll
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(entities).
    result = VALUE #( FOR entity IN entities
                        ( %TKY   = entity-%TKY
                          %PARAM = entity ) ).
  ENDMETHOD.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
*    AUTHORITY-CHECK OBJECT 'S_TABU_NAM' ID 'TABLE' FIELD 'ZI_MATERIALSHELFLIFEMA' ID 'ACTVT' FIELD '02'.
*    DATA(is_authorized) = COND #( WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
*                                  ELSE if_abap_behv=>auth-unauthorized ).
*    result-%UPDATE      = is_authorized.
*    result-%ACTION-Edit = is_authorized.
*    result-%ACTION-SelectCustomizingTransptReq = is_authorized.
  ENDMETHOD.
  METHOD EDIT.
    CHECK lhc_rap_tdat_cts=>get( )->is_transport_mandatory( ).
    DATA(transport_request) = lhc_rap_tdat_cts=>get( )->get_transport_request( ).
    IF transport_request IS NOT INITIAL.
      MODIFY ENTITY IN LOCAL MODE ZI_MaterialShelflifeMa_S
        EXECUTE SelectCustomizingTransptReq FROM VALUE #( ( %IS_DRAFT = if_abap_behv=>mk-on
                                                            SingletonID = 1
                                                            %PARAM-transportrequestid = transport_request ) ).
      reported-MaterialShelflifAll = VALUE #( ( %IS_DRAFT = if_abap_behv=>mk-on
                                     SingletonID = 1
                                     %MSG = mbc_cp_api=>message( )->get_transport_selected( transport_request ) ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
CLASS LSC_ZI_MATERIALSHELFLIFEMA_S DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_SAVER.
  PROTECTED SECTION.
    METHODS:
      SAVE_MODIFIED REDEFINITION.
ENDCLASS.

CLASS LSC_ZI_MATERIALSHELFLIFEMA_S IMPLEMENTATION.
  METHOD SAVE_MODIFIED.
    DATA(transport_from_singleton) = VALUE #( update-MaterialShelflifAll[ 1 ]-TransportRequestID OPTIONAL ).
    IF transport_from_singleton IS NOT INITIAL.
      lhc_rap_tdat_cts=>get( )->record_changes(
                                  transport_request = transport_from_singleton
                                  create            = REF #( create )
                                  update            = REF #( update )
                                  delete            = REF #( delete ) )->update_last_changed_date_time( view_entity_name   = 'ZI_MATERIALSHELFLIFEMA'
                                                                                                        maintenance_object = 'ZMATERIALSHELFLIFEMA' ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
CLASS LHC_ZI_MATERIALSHELFLIFEMA DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_FEATURES FOR GLOBAL FEATURES
        IMPORTING
          REQUEST REQUESTED_FEATURES FOR MaterialShelflifeMa
        RESULT result,
      VALIDATETRANSPORTREQUEST FOR VALIDATE ON SAVE
        IMPORTING
          KEYS_MATERIALSHELFLIFALL FOR MaterialShelflifAll~ValidateTransportRequest
          KEYS_MATERIALSHELFLIFEMA FOR MaterialShelflifeMa~ValidateTransportRequest,
      Validatedata FOR VALIDATE ON SAVE
            IMPORTING keys FOR MaterialShelflifeMa~Validatedata,
      Validateonmodify FOR DETERMINE ON MODIFY
            IMPORTING keys FOR MaterialShelflifeMa~Validateonmodify.

ENDCLASS.

CLASS LHC_ZI_MATERIALSHELFLIFEMA IMPLEMENTATION.
  METHOD GET_GLOBAL_FEATURES.
    DATA edit_flag TYPE abp_behv_op_ctrl VALUE if_abap_behv=>fc-o-enabled.
    IF lhc_rap_tdat_cts=>get( )->is_editable( ) = abap_false.
      edit_flag = if_abap_behv=>fc-o-disabled.
    ENDIF.
    result-%UPDATE = edit_flag.
    result-%DELETE = edit_flag.
  ENDMETHOD.
  METHOD VALIDATETRANSPORTREQUEST.

    CHECK keys_MaterialShelflifeMa IS NOT INITIAL.
    DATA change TYPE REQUEST FOR CHANGE ZI_MaterialShelflifeMa_S.
    READ ENTITY IN LOCAL MODE ZI_MaterialShelflifeMa_S
    FIELDS ( TransportRequestID ) WITH CORRESPONDING #( keys_MaterialShelflifAll )
    RESULT FINAL(transport_from_singleton).
    lhc_rap_tdat_cts=>get( )->validate_all_changes(
                                transport_request     = VALUE #( transport_from_singleton[ 1 ]-TransportRequestID OPTIONAL )
                                table_validation_keys = VALUE #(
                                                          ( table = 'ZYDC_CONFIG_POC' keys = REF #( keys_MaterialShelflifeMa ) )
                                                               )
                                reported              = REF #( reported )
                                failed                = REF #( failed )
                                change                = REF #( change ) ).


  ENDMETHOD.
  METHOD Validatedata.

  data: lv_daysfrom1 type int2,
         lv_daysto1 type int2,
         lv_daysfrom2 type int2,
         lv_daysto2 type int2,
         lv_critical  type c LENGTH 10.

 FIELD-SYMBOLS <fs_data1> type zydc_config_poc.
 FIELD-SYMBOLS <fs_data2> type zydc_config_poc.

 DATA: lt_entries TYPE STANDARD TABLE OF zydc_config_poc,
      lt_entries2 TYPE STANDARD TABLE OF zydc_config_poc,
      ls_entries TYPE  zydc_config_poc,
      ls_entries2 TYPE  zydc_config_poc.

  READ ENTITIES OF ZI_MaterialShelflifeMa_S IN LOCAL MODE " zi_vehin_head IN LOCAL MODE
           ENTITY MaterialShelflifeMa
               FIELDS ( Criticality Daysfrom Daysto Remarks ) WITH CORRESPONDING #( keys )
                   RESULT DATA(MaterialShelflifeMa).

   TRY.
        DATA(ls_header) = MaterialShelflifeMa[ 1 ].

        clear:lt_entries[],lt_entries2[].
        select * from zydc_config_cds_poc into table @data(lt_zydc_config).

        if lt_zydc_config[] is not INITIAL.

        MOVE-CORRESPONDING lt_zydc_config[] to lt_entries.
        MOVE-CORRESPONDING lt_zydc_config[] to lt_entries2.

        endif.


         sort lt_entries by criticality.
  sort lt_entries2 by criticality.
clear:ls_entries,ls_entries2.

   lv_daysfrom1 = ls_header-daysfrom.
   lv_daysto1 = ls_header-daysto.

 loop at lt_entries2  into ls_entries2 where criticality ne ls_header-criticality.

 lv_daysfrom2 = ls_entries2-daysfrom.
   lv_daysto2 = ls_entries2-daysto.

if ( lv_daysfrom1 <= lv_daysto2  and lv_daysfrom2 <= lv_daysto1 )  or ( lv_daysto1 < lv_daysfrom1 )  .
     clear:lv_critical.
     if ls_header-criticality = 1.
        lv_critical = '1-Red'.
        elseif ls_header-criticality = 2.
          lv_critical = '2-Yellow'.
          elseif ls_header-criticality = 3.
          lv_critical = '3-Green'.
          endif.

    APPEND VALUE #(
             %tky = ls_header-%tky
             %msg = new_message_with_text(
             severity = if_abap_behv_message=>severity-error
             text     = |{ TEXT-001 }|
          )

          ) TO reported-MaterialShelflifeMa.

" This line is critical to STOP the save
APPEND VALUE #( %tky = ls_header-%tky ) TO failed-MaterialShelflifeMa.

    endif.

 endloop.
clear:lt_entries[],lt_entries2[].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.


  ENDMETHOD.

  METHOD Validateonmodify.


data: lv_daysfrom1 type int2,
         lv_daysto1 type int2,
         lv_daysfrom2 type int2,
         lv_daysto2 type int2,
         lv_critical  type c LENGTH 10.

 FIELD-SYMBOLS <fs_data1> type zydc_config_poc.
 FIELD-SYMBOLS <fs_data2> type zydc_config_poc.

 DATA: lt_entries TYPE STANDARD TABLE OF zydc_config_poc,
      lt_entries2 TYPE STANDARD TABLE OF zydc_config_poc,
      ls_entries TYPE  zydc_config_poc,
      ls_entries2 TYPE  zydc_config_poc.

  READ ENTITIES OF ZI_MaterialShelflifeMa_S IN LOCAL MODE " zi_vehin_head IN LOCAL MODE
           ENTITY MaterialShelflifeMa
               FIELDS ( Criticality Daysfrom Daysto Remarks ) WITH CORRESPONDING #( keys )
                   RESULT DATA(MaterialShelflifeMa).
    TRY.
        DATA(ls_header) = MaterialShelflifeMa[ 1 ].

        clear:lt_entries[],lt_entries2[].
        select * from zydc_config_cds_poc into table @data(lt_zydc_config).

        if lt_zydc_config[] is not INITIAL.

        MOVE-CORRESPONDING lt_zydc_config[] to lt_entries.
        MOVE-CORRESPONDING lt_zydc_config[] to lt_entries2.

        endif.


         sort lt_entries by criticality.
  sort lt_entries2 by criticality.
clear:ls_entries,ls_entries2.

   lv_daysfrom1 = ls_header-daysfrom.
   lv_daysto1 = ls_header-daysto.

 loop at lt_entries2  into ls_entries2 where criticality ne ls_header-criticality.

 lv_daysfrom2 = ls_entries2-daysfrom.
   lv_daysto2 = ls_entries2-daysto.

if ( lv_daysfrom1 <= lv_daysto2  and lv_daysfrom2 <= lv_daysto1 )  or ( lv_daysto1 < lv_daysfrom1 ) ." or ( lv_daysto1 <= lv_daysto2 ).
     clear:lv_critical.
     if ls_header-criticality = 1.
        lv_critical = '1-Red'.
        elseif ls_header-criticality = 2.
          lv_critical = '2-Yellow'.
          elseif ls_header-criticality = 3.
          lv_critical = '3-Green'.
          endif.

    APPEND VALUE #(
             %tky = ls_header-%tky
             %msg = new_message_with_text(
             severity = if_abap_behv_message=>severity-error
             text     = |{ TEXT-001 }|
          )

          ) TO reported-MaterialShelflifeMa.
*          APPEND VALUE #( %tky = ls_header-%tky ) TO reported-MaterialShelflifeMa  .
" This line is critical to STOP the save



    endif.

 endloop.
clear:lt_entries[],lt_entries2[].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

  ENDMETHOD.



ENDCLASS.