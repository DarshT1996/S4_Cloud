@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Material Due Date List'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Metadata.allowExtensions: true
define view entity ZYCDS_DUE_MAT_LIST as select from I_Batch
inner join ZYCDS_SUM_STOCK_01 on ZYCDS_SUM_STOCK_01.Material = I_Batch.Material
                                       and ZYCDS_SUM_STOCK_01.Plant = I_Batch.Plant
                                       and ZYCDS_SUM_STOCK_01.Batch = I_Batch.Batch
inner join I_ProductStorage_2 on I_ProductStorage_2.Product   = I_Batch.Material 
                               
//left outer join I_ProductPlantBasic
//      on I_ProductPlantBasic.Product = I_Batch.Material
//     and I_ProductPlantBasic.Plant   = I_Batch.Plant
//                                   
association [1..1] to I_Product on I_Product.Product = I_Batch.Material
association [1..1] to I_ProductDescription on I_ProductDescription.Product = I_Batch.Material
                                          and I_ProductDescription.Language = $session.system_language
association [1..1] to I_Plant on I_Plant.Plant = I_Batch.Plant
                              and I_Plant.Language = $session.system_language                              
association [1..1] to I_Supplier on I_Supplier.Supplier = I_Batch.Supplier   
                                                    
{
  key I_Batch.Material,
  key I_Batch.Batch,
  key I_Batch.Plant,
  key I_Batch.Supplier,
  key I_Batch.BatchBySupplier,
//  key YCDS_SUM_STOCK_01.InventoryStockType,
//  key YCDS_SUM_STOCK_01.MatlDocLatestPostgDate,
  ZYCDS_SUM_STOCK_01.StorageLocation,
   ZYCDS_SUM_STOCK_01.MaterialBaseUnit,
   @Semantics.quantity.unitOfMeasure: 'MaterialBaseUnit'
  ZYCDS_SUM_STOCK_01.MatlWrhsStkQtyInMatlBaseUnit,
  @Semantics.quantity.unitOfMeasure: 'MaterialBaseUnit' //N
  ZYCDS_SUM_STOCK_01.BlockedStockQty,  //N
  I_Batch.MatlBatchIsInRstrcdUseStock,
  I_Batch.ShelfLifeExpirationDate,
  I_Batch.ManufactureDate,
  I_Product.BaseUnit,
  I_Product.ProductType,  //N 27-07
  I_ProductDescription.ProductDescription,
  I_Plant.PlantName, 
  I_Supplier.SupplierName,
//  I_ProductPlantBasic.PeriodType,
//  I_ProductPlantBasic._PeriodTypeText as PeriodTypeText,
//  cast(' ' as ersda ) as remaining_days, 
  case when I_Batch.MatlBatchIsInRstrcdUseStock = 'X' then 'Restricted' else 'Unrestricted' end as BatchStatus,
  $session.system_date as curr_date, 
   dats_days_between( $session.system_date, I_Batch.ShelfLifeExpirationDate) as Remaining_days,  // added new
   
   cast(' '   as abap.numc(13)) as Due_range,    //add new
//   case 
//    when remaining_days between -10000 and 30 then 1  //red
//    when StorageLocation between 31 and 180 then 2  // yellow
//    when StorageLocation between -181 and 9999 then 3 //green
//    else 0
//    end as  Criticality 
I_ProductStorage_2.ShelfLifeExpirationDatePeriod,  //N
case I_ProductStorage_2.ShelfLifeExpirationDatePeriod  
    when '1' then 'Weeks'
    when 'W' then 'Weeks' 
    when '2' then 'Months'
    when 'M' then 'Months'  
    when '3' then 'Year'
    when 'Y' then 'Year'
    when '4' then 'Days'
    when 'D' then 'Days'  
    when ' ' then 'Days' // If initial, SAP defaults to Days
    else 'Days' 
end as ShelfLifePeriodTypeText,


I_ProductStorage_2.TotalShelfLife,

case I_ProductStorage_2.ShelfLifeExpirationDatePeriod
          when '1' then cast( I_ProductStorage_2.TotalShelfLife as abap.int4 ) * 7
          when 'W' then cast( I_ProductStorage_2.TotalShelfLife as abap.int4 ) * 7

          when '2' then cast( I_ProductStorage_2.TotalShelfLife as abap.int4 ) * 30
          when 'M' then cast( I_ProductStorage_2.TotalShelfLife as abap.int4 ) * 30

          when '3' then cast( I_ProductStorage_2.TotalShelfLife as abap.int4 ) * 365
          when 'Y' then cast( I_ProductStorage_2.TotalShelfLife as abap.int4 ) * 365

          when '4' then cast( I_ProductStorage_2.TotalShelfLife as abap.int4 )
          when 'D' then cast( I_ProductStorage_2.TotalShelfLife as abap.int4 )

          else cast( I_ProductStorage_2.TotalShelfLife as abap.int4 )
      end as TotalShelfLifeInDays,

  /* 2. Calculate Percentage */  //N
  cast(
    case 
      /* Protection against zero: cast NUMC to INT4 before comparing to 0 */
      when cast(I_ProductStorage_2.TotalShelfLife as abap.int4) <= 0 then 0
      else 
        ( cast( dats_days_between( $session.system_date, I_Batch.ShelfLifeExpirationDate) as abap.fltp ) / 
          cast( 
            case I_ProductStorage_2.ShelfLifeExpirationDatePeriod
                  when '1' then cast( I_ProductStorage_2.TotalShelfLife as abap.int4 ) * 7
                  when 'W' then cast( I_ProductStorage_2.TotalShelfLife as abap.int4 ) * 7
                  when '2' then cast( I_ProductStorage_2.TotalShelfLife as abap.int4 ) * 30
                  when 'M' then cast( I_ProductStorage_2.TotalShelfLife as abap.int4 ) * 30
                  when '3' then cast( I_ProductStorage_2.TotalShelfLife as abap.int4 ) * 365
                  when 'Y' then cast( I_ProductStorage_2.TotalShelfLife as abap.int4 ) * 365
                  else cast( I_ProductStorage_2.TotalShelfLife as abap.int4 )
            end as abap.fltp ) 
        ) * 100.0
    end as abap.dec(13,2) ) as ShelfLifePercentage
}

//cast(               //N
//    case            //N
//      when cast(I_ProductStorage_2.TotalShelfLifeInDays as abap.int4) > 0    //N
//      then ( cast( dats_days_between( $session.system_date, I_Batch.ShelfLifeExpirationDate) as abap.fltp ) /    //N
//             cast( I_ProductStorage_2.TotalShelfLifeInDays as abap.fltp ) ) * 100.0                              //N
//      else 0                                                                //N
//    end                                                                  //N
//  as abap.dec(13,2) ) as ShelfLifePercentage                           //N
//}

where I_Batch.ShelfLifeExpirationDate is not initial
  //and ZYCDS_SUM_STOCK_01.MatlWrhsStkQtyInMatlBaseUnit <> 0
