@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'standalone eway bill data'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZC_BILLING_data 
as select from I_BillingDocument              as a
    inner join I_BillingDocumentItemBasic       as b
      on  a.BillingDocument = b.BillingDocument
    inner join I_BillingDocumentBasic           as f
      on  a.BillingDocument = f.BillingDocument

    // Sold-to & Payer
    left outer join I_Customer                  as soldto
      on a.SoldToParty = soldto.Customer
    left outer join I_Customer                  as payer
      on a.PayerParty  = payer.Customer

    // Ship-to (Partner Function WE)
    left outer join I_SalesDocumentPartner      as shiptopartner
      on b.SalesDocument = shiptopartner.SalesDocument
     and shiptopartner.PartnerFunction = 'WE'
    left outer join I_Customer                  as shipto
      on shiptopartner.Customer = shipto.Customer

    // Bill-to (Partner Function RE)
    left outer join I_BillingDocumentPartner    as billtopartner
      on a.BillingDocument = billtopartner.BillingDocument
     and billtopartner.PartnerFunction = 'RE'
    left outer join I_Customer                  as billto
      on billtopartner.Customer = billto.Customer

    // Transporter (Partner Function ZT)
    left outer join I_BillingDocumentPartner    as transp
      on a.BillingDocument = transp.BillingDocument
     and transp.PartnerFunction = 'ZT'
    left outer join I_Customer                  as transp_nm
      on transp.Customer = transp_nm.Customer

    // Product and HSN
    left outer join I_Product                   as prod
      on b.Product = prod.Product
    left outer join I_ProductPlantBasic         as prodplant
      on b.Product = prodplant.Product
     and b.Plant   = prodplant.Plant

    // Sales Order Reference
    left outer join I_SalesOrderItem            as soitem
      on b.SalesDocument     = soitem.SalesOrder
     and b.SalesDocumentItem = soitem.SalesOrderItem
    left outer join I_SalesOrder                as so
      on b.SalesDocument     = so.SalesOrder

    // Pricing elements (condition-based joins)
    left outer join I_BillingDocumentItemPrcgElmnt as price_zpr0
      on price_zpr0.BillingDocument     = b.BillingDocument
     and price_zpr0.BillingDocumentItem = b.BillingDocumentItem
     and price_zpr0.ConditionType       = 'ZPR0'

    left outer join I_BillingDocumentItemPrcgElmnt as price_jocg
      on price_jocg.BillingDocument     = b.BillingDocument
     and price_jocg.BillingDocumentItem = b.BillingDocumentItem
     and price_jocg.ConditionType       = 'JOCG'

    left outer join I_BillingDocumentItemPrcgElmnt as price_josg
      on price_josg.BillingDocument     = b.BillingDocument
     and price_josg.BillingDocumentItem = b.BillingDocumentItem
     and price_josg.ConditionType       = 'JOSG'

    left outer join I_BillingDocumentItemPrcgElmnt as price_joig
      on price_joig.BillingDocument     = b.BillingDocument
     and price_joig.BillingDocumentItem = b.BillingDocumentItem
     and price_joig.ConditionType       = 'JOIG'
    
    left outer join I_BillingDocumentItemPrcgElmnt as price_joug
      on price_joug.BillingDocument     = b.BillingDocument
     and price_joug.BillingDocumentItem = b.BillingDocumentItem
     and price_joug.ConditionType       = 'JOUG' 

    // Plant / Business Place / GSTIN
    left outer join I_IN_PlantBusinessPlaceDetail as bupla
      on bupla.Plant       = b.Plant
     and bupla.CompanyCode = a.CompanyCode
    left outer join I_IN_BusinessPlaceTaxDetail   as taxdet
      on taxdet.BusinessPlace = bupla.BusinessPlace
     and taxdet.CompanyCode   = bupla.CompanyCode
    left outer join I_Plant                        as pl
      on pl.Plant = b.Plant

{
    // Header info
    a.BillingDocument,
    b.BillingDocumentItem,
    a.BillingDocumentDate,
//    b.NetAmount,
    a.CompanyCode,
    a.TransactionCurrency,
    a.AccountingExchangeRate,
    a.BillingDocumentType,
    a.DistributionChannel,
    // Sold-to, Payer, Ship-to, Bill-to
    a.SoldToParty,
    soldto.CustomerName          as sold_to_nm,
    a.PayerParty,
    payer.CustomerName           as payer_nm,
    shipto.Customer              as shipto,
    shipto.CustomerName          as shipto_nm,
    billto.Customer              as billto,
    billto.CustomerName          as billto_nm,
    billto.TaxNumber3            as gstin,

    // Transporter
    transp.Customer              as transporter_id,
    transp_nm.CustomerName       as transporter_name,

    // Product
    b.Product,
    b.MaterialGroup,
    b.BillingDocumentItemText,
    @Semantics.quantity.unitOfMeasure: 'BillingQuantityUnit'
    b.BillingQuantity,
    b.BillingQuantityUnit,
    @Semantics.amount.currencyCode: 'TransactionCurrency'
    b.NetAmount,
    @Semantics.amount.currencyCode: 'TransactionCurrency'
    b.TaxAmount,
    prod.ProductOldID,
    prodplant.ConsumptionTaxCtrlCode as hsncode,

    // Pricing breakdown (example)
    price_zpr0.ConditionRateValue as base_rate,
    @Semantics.amount.currencyCode: 'TransactionCurrency'
    price_jocg.ConditionAmount    as cgst_value,
    price_jocg.ConditionRateValue as cgst_perc,
    @Semantics.amount.currencyCode: 'TransactionCurrency'
    price_josg.ConditionAmount    as sgst_value,
    price_josg.ConditionRateValue as sgst_perc,
    @Semantics.amount.currencyCode: 'TransactionCurrency'
    price_joig.ConditionAmount    as igst_value,
    price_joig.ConditionRateValue as igst_perc,
    @Semantics.amount.currencyCode: 'TransactionCurrency'
    price_joug.ConditionAmount    as ugst_value,
    price_joug.ConditionRateValue as ugst_perc,
    

    // Plant / GSTIN info
    pl.Plant,
    pl.PlantName,
    bupla.BusinessPlace,
    taxdet.IN_GSTIdentificationNumber as bupla_gstin,
    f.YY1_VehicleNo2_BDH,
    f.YY1_VehicleType_BDH,
    b.ReferenceSDDocument,
    b.ReferenceSDDocumentCategory
    

}
where b.BillingQuantity  > 0
and  a.BillingDocumentType = 'F8'
