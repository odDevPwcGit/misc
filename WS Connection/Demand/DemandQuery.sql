-- Demand Report
select
	initcap(split_part(ws.tenantid,'.',2)) ulb,
	ws.connectionno,
	ws.oldconnectionno,
	date(to_timestamp(dmd.taxperiodfrom/1000)) periodFrom,
	date(to_timestamp(dmd.taxperiodto/1000)) periodTo,
	sum(case when dtl.taxheadcode='WS_CHARGE' then dtl.taxamount else 0 end) waterCharge,
	sum(case when dtl.taxheadcode='SW_CHARGE' then dtl.taxamount else 0 end) sewerageCharge,
	sum(case when dtl.taxheadcode='WS_SPECIAL_REBATE' then dtl.taxamount
		when dtl.taxheadcode='WS_TIME_REBATE' then dtl.taxamount else 0 end) rebate,
	sum(case when dtl.taxheadcode='SW_ADHOC_CHARGE' then dtl.taxamount else 0 end) sewerageArrear,
	sum(case when dtl.taxheadcode='SW_SPECIAL_REBATE' then dtl.taxamount else 0 end) sewerageArrearRebate,
	sum(case when dtl.taxheadcode='WS_ADVANCE_CARRYFORWARD' then 0
		when dtl.taxheadcode='SW_ADVANCE_CARRYFORWARD' then 0 else dtl.taxamount end) totalDemandAmount,
	sum(case when dtl.taxheadcode='WS_ADVANCE_CARRYFORWARD' then 0
		when dtl.taxheadcode='SW_ADVANCE_CARRYFORWARD' then 0 else dtl.collectionamount end) collectedAgainstDemand
from egbs_demand_v1 dmd
inner join egbs_demanddetail_v1 dtl on dtl.demandid=dmd.id
inner join eg_ws_connection ws on ws.connectionno = dmd.consumercode 
where dmd.consumercode in (
select distinct conn.connectionno from eg_ws_connection conn
where conn.tenantid ='od.bhubaneswar'
and conn.oldconnectionno in ('0101756','0101805','2502030','2015111','2423076','28151644','0103101','0401250','1807448','0101673','0101675','0101600','0101767','0101710','0101717','0101730')
)
group by
	ws.tenantid,
	ws.connectionno,
	ws.oldconnectionno,
	dmd.taxperiodfrom,
	dmd.taxperiodto
order by dmd.taxperiodfrom;

-- Payment history
select 
	ep.tenantid,
	(select consumercode from egbs_billdetail_v1 ebv2 where billid=ep.billid) consumercode,
	ep.amountpaid,
	ep.receiptnumber,
	pay.paymentmode,
	to_timestamp(ep.receiptdate/1000) receiptdate
from egcl_paymentdetail ep
inner join egcl_payment pay on pay.id=ep.paymentid 
where ep.billid in (
select billid from egbs_billdetail_v1 ebv where consumercode in (
select distinct conn.connectionno from eg_ws_connection conn
where conn.tenantid ='od.bhubaneswar'
and conn.oldconnectionno in ('0101756','0101805','2502030','2015111','2423076','28151644','0103101','0401250','1807448','0101673','0101675','0101600','0101767','0101710','0101717','0101730')
));