@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Trasnporter Details view Standlone'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI_EWB_TRANS_DET_ST1 
 as select from  ZR_EWB_TRANS_DTLS as _EWBDTLS
  left outer join ztsd_ewb_dtls_n   on _EWBDTLS.BillingDocument = ztsd_ewb_dtls_n.docno
  association to parent ZI_BILLING_EWB_ST as _BILLINGEWB on $projection.DocNo = _BILLINGEWB.BillingDocument
{

  key _EWBDTLS.CompanyCode            as Bukrs,
  key _EWBDTLS.BillingDocument        as DocNo,
  key ztsd_ewb_dtls_n.doc_year,
  key _EWBDTLS.BillingDocumentType    as Doc_Type,
      _EWBDTLS.TransId                as TransId,
      _EWBDTLS.TransNm                as TransNm,
      ztsd_ewb_dtls_n.distance        as Distance,
      _EWBDTLS.VehNo                  as VehNo,
      _EWBDTLS.VehType                as VehType,
      ztsd_ewb_dtls_n.trans_mode      as TransMd,
      _EWBDTLS.LrNo                   as TransDocNo,
      _EWBDTLS.LrDate                 as TransDt,
      ztsd_ewb_dtls_n.created_by      as CreatedBy,
      ztsd_ewb_dtls_n.created_at      as CreatedAt,
      ztsd_ewb_dtls_n.last_changed_by as LastChangedBy,
      ztsd_ewb_dtls_n.last_changed_at as LastChangedAt,
      _BILLINGEWB

}
