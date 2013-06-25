create or replace view vp_0531702_m as
select c.rn,
       dt.docname, --
       decode(dt.doccode, 'КОНТРАКТ', 1, 2) ndoctype,
       c.ext_number,
       c.doc_date,
       c.begin_date,
       c.end_date,
       c.doc_sumtax,
       cur.curcode,
       0/*c.doc_sumtax*/ doc_sumtax_base,
       nvl(fp.pay_sum, 0) avans_sum,
       nvl(round(fp.pay_sum / c.doc_sumtax * 100), 0) avans_percent,
       ag.agnname agnin,
       nvl(nvl(ag2g.fullname, ag2g.agnname), nvl(ag2.fullname, ag2.agnname)) agnname,
       nvl(ag2g.agnidnumb, ag2.agnidnumb) agnidnumb,
       decode(nvl(ag2g.reason_code, ag2.reason_code), 0, null, nvl(ag2g.reason_code, ag2.reason_code)) reason_code,
       f_agnaddresses_get_str(ag2.rn, 1, 'C') sCountry,
       f_agnaddresses_get_str(ag2.rn, 1, 'O') sCountryCode,
       f_agnaddresses_get_str(ag2.rn, 1, 'PRDYTSHBF') sAddress,
       ag2.phone,
       ac.agnacc,
       ag3.agnname bankname,
       ba.bankfcodeacc,
       ba.bankacc bankcorracc,
       dp.num_value nzakaztype,
       dp.note szakaztype,
       prsf_prop_sget(c.company, 'Contracts', c.rn, 'Номер реестровой зап') reg_number,
       prsf_prop_dget(c.company, 'Contracts', c.rn, 'Дата подведения итог') reg_date,
       dt2.docname sConfBO,
       prsf_prop_sget(c.company, 'Contracts', c.rn, 'Реквизиты: Номер') sConfBONumb,
       prsf_prop_dget(c.company, 'Contracts', c.rn, 'Реквизиты: Дата') dConfBODate,
       c.subject,
       prsf_prop_sget(c.company, 'Contracts', c.rn, 'Учетный номер БО') duty_numb,
       prsf_prop_dget(c.company, 'Contracts', c.rn, 'Дата постановки на у') duty_date,
       br.code ubp_code,
       tre.ft_code,
       trea.agnname ft_name,
       ac2.agnacc ls_num,
       dr.code dr_code,
       dr.name dr_name,
       bgsa.agnname fin_name,
       prsf_prop_nget(c.company, 'Contracts', c.rn, 'Номер сведения') nsved,
       prsf_prop_dget(c.company, 'Contracts', c.rn, 'Дата сведения') dsved,
       prsf_prop_sget(c.company, 'Contracts', c.rn, 'Статус исполнения') sdoc_stat_gk,
       FP_PRSF_PROP_SGET(c.company, 'Contracts', c.rn, 'Статус исполнения') sdoc_stat_gk_full
  from contracts c,
       doctypes dt,
       curnames cur,
       (select s.prn,
               sum(fp.pay_sum) pay_sum, --
               max(s.FACEACC) keep(dense_rank last order by s.stage_sum) facern
          from (select PRN, --
                       pay_sum
                  from FCACPAYPLANS
                 where Fact_Sign = 0) FP,
               STAGES S
         where FP.PRN(+) = S.FACEACC
           and s.status = 1 -- только открытые этапы
         group by s.prn) fp, -- аванс
       jurpersons jp,
       agnlist ag,
       agnlist ag2, -- поставщик
       agnlist ag2g, -- головное подразделение поставщика
       agnacc agc, -- реквизиты поставщика
       agnacc ac, -- счет поставщика
       agnbanks ba,
       agnlist ag3,
       faceacc fc,
       (select edv.num_value, edv.note, dpv.unit_rn
          from docs_props dp, docs_props_vals dpv, extra_dicts ed, extra_dicts_values edv
         where dp.rn = dpv.docs_prop_rn
           and dp.code = 'Способ размещения'
           and dp.code = ed.code
           and edv.prn = ed.rn
           and edv.num_value = dpv.num_value) dp,
       doctypes dt2,
       budgrecip br,
       agnacc ac2,
       agntreas tre,
       agnlist trea,
       dirrecip dr,
       budgets bgs,
       agnlist bgsa
 where dt.rn = c.doc_type
   and cur.rn = c.currency
   and fp.prn(+) = c.rn
   and jp.rn = c.jur_pers
   and ag.rn = jp.agent
   and ag2.rn = nvl(fc.agent, c.agent)
   and agc.rn = nvl(fc.agnacc, c.agnacc)
   and ac.rn(+) = nvl(agc.treas_agnacc, agc.rn)
   and ba.rn(+) = ac.agnbanks
   and ag3.rn(+) = ba.agnrn
   and dp.unit_rn(+) = c.rn
   and dt2.doccode(+) = prsf_prop_sget(c.company, 'Contracts', c.rn, 'Реквизиты: Вид')
   and br.agent(+) = ag.rn
   and ac2.rn = c.jur_acc
   and tre.rn(+) = ac2.agntreas
   and trea.rn(+) = tre.agnrn
   and dr.rn(+) = br.dirrecip
   and bgs.rn(+) = br.budget
   and bgsa.rn(+) = bgs.finagency
   and fc.rn(+) = fp.facern
   and ag2g.agnabbr(+) = prsf_prop_sget(ag2.version, 'AGNLIST', ag2.rn, 'Мнемокод ГП')

