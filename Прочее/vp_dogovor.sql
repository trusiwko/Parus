create or replace view vp_dogovor as
select pfa.rn,
       ctr.cntrnumb, --
       ag.agnfamilyname_abl || ' ' || ag.agnfirstname_abl || ' ' || ag.agnlastname_abl sfio_abl,
       ag.agnfamilyname_to || ' ' || ag.agnfirstname_to || ' ' || ag.agnlastname_to sfio_to,
       ag.agnfamilyname || ' ' || ag.agnfirstname || ' ' || ag.agnlastname sfio,
       ag.agnfamilyname,
       ag.agnfirstname,
       ag.agnlastname,
       dep.name sdepartment,
       dep.name_gen sdepartment_gen,
       nvl(cd.psdep_name, cpo.name) spost,
       decode(ct.code, 'осн', 'основной', 'вне', 'по внешнему совместительству', 'по внутреннему совместительству') ctname,
       to_char(pfa.begeng, 'dd') dstart,
       lower(f_smonth_base(to_char(pfa.begeng, 'mm'), 1)) mstart,
       to_char(pfa.begeng, 'yy') ystart,
       ad.sPASSPORT,
       f_agnaddresses_get_str(pfa.pers_agent, 1, 'PRDYTSHBF') saddress,
       ag.agnfamilyname || ' ' || ag.agnfirstname || ' ' || ag.agnlastname || ', ' || to_char(ag.agnburn, 'dd.mm.yyyy') || ' г.р.' sagnburn,
       null clnpspfmhsrn,
       null ssumm,
       null sruk,
       null agncntr,
       ag.agnfamilyname || ' ' || substr(ag.agnfirstname, 1, 1) || '.' || substr(ag.agnlastname, 1, 1) || '.' sFamIO,
       to_char(ctr.datebeg, 'dd') dcntr,
       lower(f_smonth_base(to_char(ctr.datebeg, 'mm'), 1)) mcntr,
       to_char(ctr.datebeg, 'yy') ycntr,
       'нормальная продолжительность рабочего времени составляющая ' || sls.name schedule,
       null schedulees,
       null leave_len,
       decode(ag.sex, 1, 'ый', 2, 'ая') ssexend,
       decode(pfa.endeng, null, 'на неопределенный срок', 'на определенный срок') srok,
       'три месяца' sispsrok,
       'заведующему отделом' sslave,
       1 p42,
       1 p43,
       decode(ofc.code, 'Руководители', 1, 0) p44,
       1 p55,
       1 p56,
       1 p57,
       1 p58,
       1 p59,
       1 p510,
       1 p510a,
       1 p511,
       1 p512,
       1 p513,
       1 p514,
       1 p515,
       1 p631,
       1 p632,
       1 p633,
       '________' s631,
       '________' s632,
       '________' s633,
       1 p635a,
       1 p635b,
       1 p635c,
       1 p635,
       '________' s635a,
       '________' s635b,
       '________' s635c,
       'должностной оклад' sokl,
       to1.summ nokl,
       decode(to2.coeffic, 0, null, to2.coeffic) soklkoeff,
       to2.summ noklkoeff,
       to3.summ nopas,
       to3.coeffic nopasp,
       to4.summ nvysl,
       to4.coeffic nvyslp,
       to5.summ nstep,
       to6.summ nklass,
       null noth,
       null soth,
       0 ndoplotp,
       null npoosch,
       null spoosch,
       0 nplat,
       to_char(pfa.dsumdate, 'dd') dsumdate,
       lower(f_smonth_base(to_char(pfa.dsumdate, 'mm'), 1)) msumdate,
       to_char(pfa.dsumdate, 'yy') ysumdate
  from (select pf.rn, --
               pf.persrn,
               cp.pers_agent,
               pf.begeng,
               pf.endeng,
               pf.deptrn,
               pf.psdeprn,
               pf.postrn,
               pf.clnpspfmtypes,
               pf.officercls,
               t.operdate dsumdate
          from clnpspfm   pf,
               clnpersons cp,
               TP_DOGOVOR t
         where cp.rn = pf.persrn
           and t.authid = user) pfa,
       (select ctr.datebeg, --
               ctr.cntrnumb,
               ctr.prn
          from agncontracts ctr) ctr,
       agnlist ag,
       clnpsdep cd,
       clnposts cpo,
       ins_department dep,
       clnpspfmtypes ct,
       (select max(ad.docser || ' ' || ad.docnumb || decode(ad.docwhen, null, null, ' от ' || to_char(ad.docwhen, 'dd.mm.yyyy') || ' г.') || decode(ad.docwho, null, null, ', выдан ' || ad.docwho)) sPASSPORT,
               ad.prn
          from agndocums ad
         where ad.default_sign = 1
         group by ad.prn) ad,
       (select hs.*
          from (select max(rn) keep(dense_rank last order by hs.do_act_from) rn --
                  from clnpspfmhs hs
                 group by hs.prn) a,
               clnpspfmhs hs
         where hs.rn = a.rn) hs,
       slschedule sls,
       officercls ofc,
       (select GS.PRN,
               GS.DO_ACT_FROM,
               sum(gs.summ) summ
          from CLNPSPFMGS GS,
               GRCATSAL   grc,
               GRCATSALSP grs,  TP_DOGOVOR t
         where gs.grsalary = grs.grsalaryrn
           and grc.code = '1. 1 оклад'
           and grs.prn = grc.rn
           and t.operdate between gs.do_act_from and nvl(gs.do_act_to, t.operdate)
           and t.authid = user
         group by GS.PRN,
                  GS.DO_ACT_FROM) to1,
       (select GS.PRN,
               GS.DO_ACT_FROM,
               max(gs.coeffic) coeffic,
               sum(gs.summ) summ
          from CLNPSPFMGS GS,
               GRCATSAL   grc,
               GRCATSALSP grs,  TP_DOGOVOR t
         where gs.grsalary = grs.grsalaryrn
           and grc.code = 'Б. квалификационная'
           and grs.prn = grc.rn
                      and t.operdate between gs.do_act_from and nvl(gs.do_act_to, t.operdate)
           and t.authid = user
         group by GS.PRN,
                  GS.DO_ACT_FROM) to2,
       (select GS.PRN,
               GS.DO_ACT_FROM,
               sum(gs.summ) summ,
               max(gs.coeffic) coeffic
          from CLNPSPFMGS GS,
               GRCATSAL   grc,
               GRCATSALSP grs,  TP_DOGOVOR t
         where gs.grsalary = grs.grsalaryrn
           and grc.code = '2. 1 опасные условия'
           and grs.prn = grc.rn
                      and t.operdate between gs.do_act_from and nvl(gs.do_act_to, t.operdate)
           and t.authid = user
         group by GS.PRN,
                  GS.DO_ACT_FROM) to3,
       (select GS.PRN,
               GS.DO_ACT_FROM,
               sum(gs.summ) summ,
               max(gs.coeffic) coeffic
          from CLNPSPFMGS GS,
               GRCATSAL   grc,
               GRCATSALSP grs,  TP_DOGOVOR t
         where gs.grsalary = grs.grsalaryrn
           and grc.code = '2. 2 выслуга'
           and grs.prn = grc.rn
                      and t.operdate between gs.do_act_from and nvl(gs.do_act_to, t.operdate)
           and t.authid = user
         group by GS.PRN,
                  GS.DO_ACT_FROM) to4,
       (select GS.PRN,
               GS.DO_ACT_FROM,
               sum(gs.summ) summ,
               max(gs.coeffic) coeffic
          from CLNPSPFMGS GS,
               GRCATSAL   grc,
               GRCATSALSP grs,  TP_DOGOVOR t
         where gs.grsalary = grs.grsalaryrn
           and grc.code = '2. 3 ученая степень'
           and grs.prn = grc.rn
                      and t.operdate between gs.do_act_from and nvl(gs.do_act_to, t.operdate)
           and t.authid = user
         group by GS.PRN,
                  GS.DO_ACT_FROM) to5,
       (select GS.PRN,
               GS.DO_ACT_FROM,
               sum(gs.summ) summ,
               max(gs.coeffic) coeffic
          from CLNPSPFMGS GS,
               GRCATSAL   grc,
               GRCATSALSP grs,  TP_DOGOVOR t
         where gs.grsalary = grs.grsalaryrn
           and grc.code = 'Е. Классность'
           and grs.prn = grc.rn
                      and t.operdate between gs.do_act_from and nvl(gs.do_act_to, t.operdate)
           and t.authid = user
         group by GS.PRN,
                  GS.DO_ACT_FROM) to6
 where ctr.prn(+) = pfa.pers_agent
   and ctr.datebeg(+) = pfa.begeng
      --and pfa.rn = 9196406
   and ag.rn = pfa.pers_agent
   and dep.rn = pfa.deptrn
   and cd.rn(+) = pfa.psdeprn
   and cpo.rn = nvl(cd.postrn, pfa.postrn)
   and ct.rn = pfa.clnpspfmtypes
   and ad.prn(+) = pfa.pers_agent
   and hs.prn = pfa.rn
   and sls.rn(+) = hs.schedule
   and ofc.rn(+) = pfa.officercls
   and to1.prn(+) = pfa.rn
   and to2.prn(+) = pfa.rn
   and to3.prn(+) = pfa.rn
   and to4.prn(+) = pfa.rn
   and to5.prn(+) = pfa.rn
   and to6.prn(+) = pfa.rn
;
