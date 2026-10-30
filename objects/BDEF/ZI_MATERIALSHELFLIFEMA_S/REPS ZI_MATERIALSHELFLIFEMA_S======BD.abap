managed with additional save implementation in class ZBP_I_MATERIALSHELFLIFEMA_S unique;
strict;
with draft;
define behavior for ZI_MaterialShelflifeMa_S alias MaterialShelflifAll
draft table ZYDC_CONFIG_D_S
with unmanaged save
lock master total etag LastChangedAtMax
authorization master( global )

{
  field ( readonly )
   SingletonID;

  field ( features : instance )
   TransportRequestID;

  field ( notrigger )
   SingletonID,
   LastChangedAtMax;


  update;
  internal create;
  internal delete;

  draft action ( features : instance ) Edit with additional implementation;
  draft action Activate optimized;
  draft action Discard;
  draft action Resume;
  draft determine action Prepare;
  action ( features : instance ) SelectCustomizingTransptReq parameter D_SelectCustomizingTransptReqP result [1] $self;

  association _MaterialShelflifeMa { create ( features : instance ); with draft; }

  validation ValidateTransportRequest on save ##NOT_ASSIGNED_TO_DETACT { create; update; }

  side effects {
    action SelectCustomizingTransptReq affects $self;
  }
  }

define behavior for ZI_MaterialShelflifeMa alias MaterialShelflifeMa ##UNMAPPED_FIELD
persistent table ZYDC_CONFIG_POC
draft table ZYDC_CONFIG_P_D
lock dependent by _MaterialShelflifAll
authorization dependent by _MaterialShelflifAll

{
  field ( mandatory : create )
   Criticality;

   field( mandatory )
   Daysfrom, Daysto, Remarks;

  field ( readonly )
   SingletonID;

  field ( readonly : update )
   Criticality;

  field ( notrigger )
   SingletonID;


  update( features : global );
  delete( features : global );

  determination Validateonmodify on modify { field Daysfrom, Daysto; create; update; }


  validation Validatedata on save {create; update; field Daysfrom, Daysto;}

  mapping for ZYDC_CONFIG_POC
  {
    Criticality = CRITICALITY;
    Daysfrom = DAYSFROM;
    Daysto = DAYSTO;
    Remarks = REMARKS;
  }

  association _MaterialShelflifAll { with draft; }

  validation ValidateTransportRequest on save ##NOT_ASSIGNED_TO_DETACT { create; update; delete; }
}