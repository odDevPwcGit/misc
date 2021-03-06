-- BP-BED-2022-04-04-002192

-- Update workflow
INSERT INTO public.eg_wf_processinstance_v2 (id, tenantid, businessservice, businessid, "action", status, assigner,createdby, lastmodifiedby, createdtime, lastmodifiedtime, modulename, businessservicesla) VALUES('d94e80a0-12c8-425c-b41d-858d5d1c06c3',(select tenantid from public.eg_bpa_buildingplan ebb where applicationno ='BP-BED-2022-04-04-002192'),
'BPA1','BP-BED-2022-04-04-002192','PAY','373b81d4-cc81-4400-8d4b-5d32dd722bef',
'2e4f4d4d-a4f7-46f9-bf66-68c7bcdea550','2e4f4d4d-a4f7-46f9-bf66-68c7bcdea550','2e4f4d4d-a4f7-46f9-bf66-68c7bcdea550',1651492807411,1651492807411,'bpa-services',5183152167);

-- Update application
update public.eg_bpa_buildingplan set status = 'APPROVED' where applicationno ='BP-BED-2022-04-04-002192';

-- need to update the permit number as this formate  BP/[CITY.CODE]/[SEQ_EG_BP_PN] eg: BP/RRK/000121
--get seq query 
seq = select nextval('seq_eg_bp_pn')

update public.eg_bpa_buildingplan set approvalno = 'BP/SMB/{seq-with 6 digit}' where  applicationno ='BP-BED-2022-04-04-002192';
---------------------------------------------

-- BP-BED-2022-03-16-001783
-- Update application
update public.eg_bpa_buildingplan set status = 'APPROVED' where applicationno ='BP-BED-2022-03-16-001783';

-- need to update the permit number as this formate  BP/[CITY.CODE]/[SEQ_EG_BP_PN] eg: BP/RRK/000121
--get seq query 
seq = select nextval('seq_eg_bp_pn')

update public.eg_bpa_buildingplan set approvalno = 'BP/SMB/{seq-with 6 digit}' where  applicationno ='BP-BED-2022-03-16-001783';
-----------------------------------------
-- BP-BAM-2022-04-18-002607
select * from eg_wf_processinstance_v2 where businessid='BP-BAM-2022-04-18-002607'
and id='e856e1b8-570d-44d0-99ef-4035715a8df5';
