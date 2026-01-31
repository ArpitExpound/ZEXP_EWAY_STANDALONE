@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'billing EWAY standlone'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZC_BILLING_EWB_ST 
 provider contract transactional_query
  as projection on ZI_BILLING_EWB_ST

{
      @Search.defaultSearchElement: true
  key BillingDocument,
      SoldToParty,
      BillingDocumentDate,
      BillingDocumentType,
      CompanyCode,
      DistributionChannel,
      Irn,
      IrnStatus,
      EinvJson,
      EbillNo,
      Status,
      VdFmDate,
      VdToDate,
      VdFmTime,
      VdToTime,
      MSG,
      LogStatus,
      IrnStatus1,
      Criticality
      
      /* Associations */
//      _transdtls : redirected to composition child ZC_EWB_TRANS_DTLS_st
}
// where Irn is not initial 
