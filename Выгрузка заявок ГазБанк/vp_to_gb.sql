create or replace view vp_to_gb as
select pf.rn nCLNPSPFM,
       substr(ca.agnname, 1, 30) COMPNAME, --
       trim(cp.tab_numb) tab_numb,
       (a.agnfamilyname) agnfamilyname,
       (a.agnfirstname) agnfirstname,
       (a.agnlastname) agnlastname,
       to_char(a.agnburn, 'dd.mm.yyyy') agnburn,
       substr((a.addr_burn), 1, 200) addr_burn,
       (po.name) sclnposts,
       aga.addr_post ZIPCODE,
       (decode(FP_P_GEOGRAFY_GET_STRUCT(aga.geografy_rn, 1), 'Российская Федерация', 'РФ')) sCountry,
       FP_P_GEOGRAFY_GET_STRUCT(aga.geografy_rn, 2, 'code') sRegionCode,
       (FP_P_GEOGRAFY_GET_STRUCT(aga.geografy_rn, 3)) sRaion,
       (nvl(FP_P_GEOGRAFY_GET_STRUCT(aga.geografy_rn, 8), FP_P_GEOGRAFY_GET_STRUCT(aga.geografy_rn, 4))) sTown,
       (FP_P_GEOGRAFY_GET_STRUCT(aga.geografy_rn, 5)) sStreet,
       (aga.addr_house) addr_house,
       (nvl(aga.addr_block, aga.addr_building)) addr_building,
       (aga.addr_flat) addr_flat,
       agd.docser,
       agd.docnumb,
       to_char(agd.docwhen, 'dd.mm.yyyy') docwhen,
       substr((agd.docwho), 1, 200) docwho,
       FP_P_CLNPSPFMGS_CALCSUMM(pf.company, pf.rn, trunc(sysdate)) amount
  from clnpspfm pf, --
       companies co,
       agnlist ca,
       clnpersons cp,
       agnlist a,
       clnpsdep pd,
       clnposts po,
       (select ad.prn, max(ad.rn) keep(dense_rank last order by ad.registration_date) rn from agnaddresses ad where ad.primary_sign = 1 group by ad.prn) ad,
       agnaddresses aga,
       (select * from agndocums agd where agd.default_sign = 1) agd
 where pf.company = co.rn
   and co.agent = ca.rn
   and cp.rn = pf.persrn
   and a.rn = cp.pers_agent
   and pd.rn(+) = pf.psdeprn
   and po.rn = nvl(pd.postrn, pf.postrn)
   and a.rn = ad.prn(+)
   and aga.rn(+) = ad.rn
   and agd.prn(+) = a.rn
/*create public synonym VP_TO_GB for VP_TO_GB;
grant select on VP_TO_GB to public;*/;
