select
	INITCAP(SPLIT_PART(EWC.TENANTID, '.', 2))as ULB,
	EWC.ADDITIONALDETAILS ->> 'ward' as WARD,
	name,
	mobilenumber,
	address,
	EWC.CONNECTIONNO,
	EWC.OLDCONNECTIONNO,
	ews.connectiontype,
	DM.DEMANDCREATIONDATE,
	DM.MONTHOFTAXPERIODTO,
	DM.TAXPERIODFROM,
	DM.TAXPERIODTO,
	DM.DEMANDID,
	DM.TAXAMOUNT as CURRENTDEMAND,
	DM.COLLECTIONAMOUNT as collectionamount,
	coalesce(arreardtl.totalcollectableinarrears, 0) - coalesce(arreardtl.totalcollectedinarrears, 0) as arrear,
	DM.REBATEAMOUNT,
	DM.PENALTYAMOUNT,
	-DM.ADVANCEAMOUNT as ADVANCEAMOUNT ,
	case
		when (DM.TAXAMOUNT-DM.COLLECTIONAMOUNT + DM.PENALTYAMOUNT + DM.ADVANCEAMOUNT + coalesce(arreardtl.totalcollectableinarrears, 0) - coalesce(arreardtl.totalcollectedinarrears, 0))>0 then DM.TAXAMOUNT-DM.COLLECTIONAMOUNT + DM.PENALTYAMOUNT + DM.ADVANCEAMOUNT + coalesce(arreardtl.totalcollectableinarrears, 0) - coalesce(arreardtl.totalcollectedinarrears, 0)
		else 0
	end as TOTALDUE,
	case
		when (round(((DM.TAXAMOUNT-DM.COLLECTIONAMOUNT)* 0.98)+ DM.ADVANCEAMOUNT + DM.REBATEAMOUNT + coalesce(arreardtl.totalcollectableinarrears, 0) - coalesce(arreardtl.totalcollectedinarrears, 0))) >0 then round(((DM.TAXAMOUNT-DM.COLLECTIONAMOUNT)* 0.98)+ DM.ADVANCEAMOUNT + DM.REBATEAMOUNT + coalesce(arreardtl.totalcollectableinarrears, 0) - coalesce(arreardtl.totalcollectedinarrears, 0))
		else 0
	end as AMOUNTBEFOREDUEDATE,
	case
		when (round(((DM.TAXAMOUNT-DM.COLLECTIONAMOUNT)* 1.05)+ DM.ADVANCEAMOUNT + DM.PENALTYAMOUNT + coalesce(arreardtl.totalcollectableinarrears, 0) - coalesce(arreardtl.totalcollectedinarrears, 0)))>0 then round(((DM.TAXAMOUNT-DM.COLLECTIONAMOUNT)* 1.05)+ DM.ADVANCEAMOUNT + DM.PENALTYAMOUNT + coalesce(arreardtl.totalcollectableinarrears, 0) - coalesce(arreardtl.totalcollectedinarrears, 0))
		else 0
	end as AMOUNTAFTERDUEDATE
from
	EG_WS_CONNECTION EWC
inner join EG_WS_SERVICE EWS on
	EWC.ID = EWS.CONNECTION_ID
left outer join(
	select
		edv.consumercode,
		to_char(to_timestamp(edv.createdtime / 1000), 'DD-MM-YYYY')as DemandCreationDate,
		TO_CHAR(to_timestamp(edv.taxperiodto / 1000), 'Mon')as MONTHOFTAXPERIODTO,
		to_char(to_timestamp(edv.taxperiodfrom / 1000), 'DD-MM-YYYY')as TaxPeriodFrom,
		to_timestamp(edv.taxperiodto / 1000)as formattedtaxperiodto,
		to_char(to_timestamp(edv.taxperiodto / 1000), 'DD-MM-YYYY')as TaxPeriodTo,
		edv2.demandid,
		edv2.taxamount,
		edv2.collectionamount,
		edv2.rebateamount,
		edv2.penaltyamount,
		edv2.advanceamount,
		edv.status,
		edv.businessservice
	from
		EGBS_DEMAND_V1 EDV
	inner join(
		select
			egb1.demandid,
			egb1.taxheadcode,
			egb1.taxamount,
			coalesce(egb1.collectionamount, 0) as collectionamount,
			coalesce(egb2.rebateamount, 0)as rebateamount,
			coalesce(egb3.penaltyamount, 0)as penaltyamount,
			coalesce(egb4.advanceamount, 0)as advanceamount
		from
			egbs_demanddetail_v1 egb1
		left join(
			select
				demandid,
				taxamount as rebateamount
			from
				egbs_demanddetail_v1
			where
				taxheadcode = 'WS_TIME_REBATE'
				and tenantid = 'od.cuttack')egb2 on
			egb1.demandid = egb2.demandid
		left join(
			select
				demandid,
				taxamount as penaltyamount
			from
				egbs_demanddetail_v1
			where
				taxheadcode = 'WS_TIME_PENALTY'
				and tenantid = 'od.cuttack')egb3 on
			egb1.demandid = egb3.demandid
		left join(
			select
				demandid,
				taxamount as advanceamount
			from
				egbs_demanddetail_v1
			where
				taxheadcode = 'WS_ADVANCE_CARRYFORWARD'
				and tenantid = 'od.cuttack')egb4 on
			egb1.demandid = egb4.demandid
		where
			egb1.taxheadcode = 'WS_CHARGE'
			and egb1.tenantid = 'od.cuttack')edv2 on
		EDV.ID = EDV2.DEMANDID)DM on
	EWC.connectionno = DM.CONSUMERCODE
left outer join(
		select
		egdm1.consumercode as consumercode,
		sum(egdd1.TAXAMTPERDEMANDPERDEMANDDETAIL)as totalcollectableinarrears,
		sum(egdd1.COLLECTEDAMTPERDEMANDPERDEMANDDETAIL)as totalcollectedinarrears
	from
		egbs_demand_v1 egdm1
	inner join(
		select
			d_detail.DEMANDID,
			d_detail.TAXAMOUNT as TAXAMTPERDEMANDPERDEMANDDETAIL,
			d_detail.COLLECTIONAMOUNT as COLLECTEDAMTPERDEMANDPERDEMANDDETAIL,
			d_detail.taxheadcode
		from
			EGBS_DEMANDDETAIL_V1 d_detail
		where
			d_detail.tenantid = 'od.cuttack'
			and d_detail.taxheadcode like 'WS%') egdd1 on
		egdm1.id = egdd1.demandid
	where
		date(to_timestamp(taxperiodto / 1000))< date('2021-09-01')
		and ispaymentcompleted = false
		and businessservice = 'WS'
		and STATUS = 'ACTIVE'
		and tenantid = 'od.cuttack'
	group by
		egdm1.consumercode)arreardtl on
	EWC.connectionno = arreardtl.consumercode
left outer join(
	select
		name,
		mobilenumber,
		address,
		connectionid
	from
		eg_ws_connectionholder ewch
	inner join(
		select
			name,
			mobilenumber,
			address,
			egu.uuid
		from
			eg_user egu
		inner join eg_user_address eguad on
			eguad.userid = egu.id
		where
			eguad.type = 'CORRESPONDENCE')usr on
		ewch.userid = usr.uuid)conholder on
	ewc.id = conholder.connectionid
where
	EWC.APPLICATIONSTATUS = 'CONNECTION_ACTIVATED'
	and DM.STATUS = 'ACTIVE'
	and DM.BUSINESSSERVICE = 'WS'
	and ewc.tenantid = 'od.cuttack'
	and ews.connectiontype = 'Non Metered'
	and
	case
		when LOWER('01') = 'nil' then EWC.ADDITIONALDETAILS ->> 'ward' is null
		else EWC.ADDITIONALDETAILS ->> 'ward' = '01'
	end
	and (date(formattedtaxperiodto) >= date('2021-09-01')
	and date(formattedtaxperiodto) <= date('2021-09-30'));