@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'consumption of e-waybill standlone'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZC_EWB_TRANS_DTLS_st 
 as projection on ZI_EWB_TRANS_DET_ST1
{

  key Bukrs,
  key DocNo,
  key doc_year,
  key Doc_Type,
      @EndUserText.label: 'Transporter ID'
      TransId,
      @EndUserText.label: 'Transporter Name'
      TransNm,
      Distance,
      VehNo,
      VehType,
      TransMd,
      TransDocNo,
      TransDt,
      @Semantics.user.createdBy: true
      CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      /* Associations */
      _BILLINGEWB : redirected to parent ZC_BILLING_EWB_ST

}
