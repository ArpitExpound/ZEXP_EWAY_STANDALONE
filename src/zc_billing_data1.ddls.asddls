@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'E-WayBill Generation Standlone'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZC_BILLING_DATA1
  as select distinct from    I_BillingDocument     as a
    inner join      I_BillingDocumentItemBasic     as b             on a.BillingDocument = b.BillingDocument
    inner join      I_BillingDocumentBasic         as f             on a.BillingDocument = f.BillingDocument
    left outer join I_Customer                     as soldto        on a.SoldToParty = soldto.Customer
    left outer join I_Customer                     as payer         on a.PayerParty = payer.Customer
    left outer join I_SalesDocumentPartner         as shiptopartner on  b.SalesDocument     = shiptopartner.SalesDocument
                                                                    and shiptopartner.PartnerFunction = 'WE'
    left outer join I_Customer                     as shipto        on shiptopartner.Customer = shipto.Customer
    left outer join I_BillingDocumentPartner       as billtopartner on  a.BillingDocument             = billtopartner.BillingDocument
                                                                    and billtopartner.PartnerFunction = 'RE'
    left outer join I_Customer                     as billto        on billtopartner.Customer = billto.Customer

    left outer join I_BillingDocumentPartner       as transp        on  a.BillingDocument      = transp.BillingDocument
                                                                    and transp.PartnerFunction = 'ZT'
    left outer join I_Customer                     as transp_nm     on transp.Customer = transp_nm.Customer     

    left outer join I_Product                      as prod          on b.Product = prod.Product
    left outer join I_ProductPlantBasic            as prodplant     on  b.Product = prodplant.Product
                                                                    and b.Plant   = prodplant.Plant
    left outer join I_SalesOrderItem               as soitem        on  b.SalesDocument     = soitem.SalesOrder
                                                                    and b.SalesDocumentItem = soitem.SalesOrderItem
    left outer join I_SalesOrder                   as so            on b.SalesDocument = so.SalesOrder
    left outer join I_BillingDocumentItemPrcgElmnt as price_zpr0    on  price_zpr0.BillingDocument     = b.BillingDocument
                                                                    and price_zpr0.BillingDocumentItem = b.BillingDocumentItem
                                                                    and price_zpr0.ConditionType       = 'ZPR0'

    left outer join I_BillingDocumentItemPrcgElmnt as price_jocg    on  price_jocg.BillingDocument     = b.BillingDocument
                                                                    and price_jocg.BillingDocumentItem = b.BillingDocumentItem
                                                                    and price_jocg.ConditionType       = 'JOCG'

    left outer join I_BillingDocumentItemPrcgElmnt as price_josg    on  price_josg.BillingDocument     = b.BillingDocument
                                                                    and price_josg.BillingDocumentItem = b.BillingDocumentItem
                                                                    and price_josg.ConditionType       = 'JOSG'

    left outer join I_BillingDocumentItemPrcgElmnt as price_joig    on  price_joig.BillingDocument     = b.BillingDocument
                                                                    and price_joig.BillingDocumentItem = b.BillingDocumentItem
                                                                    and price_joig.ConditionType       = 'JOIG'

    left outer join I_IN_PlantBusinessPlaceDetail  as bupla         on  bupla.Plant       = b.Plant
                                                                    and bupla.CompanyCode = a.CompanyCode
    left outer join I_IN_BusinessPlaceTaxDetail    as taxdet        on  taxdet.BusinessPlace = bupla.BusinessPlace
                                                                    and taxdet.CompanyCode   = bupla.CompanyCode
    left outer join I_Plant                        as pl            on pl.Plant = b.Plant

{
  // Header info
  key a.BillingDocument,
  a.BillingDocumentDate,
  a.CompanyCode,
  a.TransactionCurrency,
  a.AccountingExchangeRate,
  a.BillingDocumentType,
  a.DistributionChannel,
  a.SoldToParty,
  soldto.CustomerName                as sold_to_nm,
  a.PayerParty
//  payer.CustomerName                 as payer_nm,
//  shipto.Customer                    as shipto,
//  shipto.CustomerName                as shipto_nm,
//  billto.Customer                    as billto,
//  billto.CustomerName                as billto_nm,
//  billto.TaxNumber3                  as gstin,
//  transp.Customer                    as transporter_id,
//  transp_nm.CustomerName             as transporter_name,
//  @Semantics.quantity.unitOfMeasure: 'BillingQuantityUnit'
//  sum ( b.BillingQuantity )          as BillingQuantity,
//  b.BillingQuantityUnit,
//  @Semantics.amount.currencyCode: 'TransactionCurrency'
//  sum ( b.NetAmount )                as NetAmount,
//  @Semantics.amount.currencyCode: 'TransactionCurrency'
//  sum ( b.TaxAmount )                as TaxAmount
//  prod.ProductOldID,
//  sum ( price_zpr0.ConditionRateValue )      as base_rate,
//  @Semantics.amount.currencyCode: 'TransactionCurrency'
//  sum ( price_jocg.ConditionAmount ) as cgst_value,
//  sum ( price_jocg.ConditionRateValue ) as cgst_perc,
//  @Semantics.amount.currencyCode: 'TransactionCurrency'
//  sum ( price_jocg.ConditionAmount ) as sgst_value,
//  sum ( price_josg.ConditionRateValue )   as sgst_perc,
//  @Semantics.amount.currencyCode: 'TransactionCurrency'
//  sum ( price_jocg.ConditionAmount ) as igst_value,
//  sum ( price_joig.ConditionRateValue )   as igst_perc,
//  pl.PlantName,
//  bupla.BusinessPlace,
//  taxdet.IN_GSTIdentificationNumber  as bupla_gstin

}
where b.BillingQuantity > 0
  and a.BillingDocumentType = 'F8'  
  

group by
  a.BillingDocument,
  a.BillingDocumentDate,
  a.CompanyCode,
  a.TransactionCurrency,
  a.AccountingExchangeRate,
  a.BillingDocumentType,
  a.DistributionChannel,
  a.SoldToParty,
  soldto.CustomerName,
  a.PayerParty
//  payer.CustomerName,
//  shipto.Customer,
//  shipto.CustomerName,
//  billto.Customer,
//  billto.CustomerName,
//  billto.TaxNumber3,
//  transp.Customer,
//  transp_nm.CustomerName,
//  b.BillingQuantityUnit,
//  b.TaxAmount
//  prod.ProductOldID,
//  pl.PlantName,
//  bupla.BusinessPlace,
//  taxdet.IN_GSTIdentificationNumber
