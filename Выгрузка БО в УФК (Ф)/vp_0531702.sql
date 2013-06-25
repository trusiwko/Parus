create or replace view vp_0531702 as
select dt.docname, --
       decode(dt.doccode, 'КОНТРАКТ', 1, 2) ndoctype,
       c.ext_number,
       c.doc_date,
       c.begin_date,
       c.end_date,
       c.doc_sumtax,
       cur.curcode,
       c.doc_sumtax doc_sumtax_base,
       nvl(fp.pay_sum, 0) avans_sum,
       nvl(fp.percent, 0) avans_percent,
       ag.agnname agnin,
       nvl(ag2.fullname, ag2.agnname) agnname,
       ag2.agnidnumb,
       ag2.reason_code,
       f_agnaddresses_get_str(ag2.rn, 1, 'C') sCountry,
       f_agnaddresses_get_str(ag2.rn, 1, 'O') sCountryCode,
       f_agnaddresses_get_str(ag2.rn, 1, 'RPYTSHBF') sAddress,
       ag2.phone,
       ac.agnacc,
       ag3.agnname bankname,
       ba.bankfcodeacc,
       ba.bankacc bankcorracc,
       dp.num_value nzakaztype,
       dp.note szakaztype,
       tb.reg_date,
       tb.reg_number,
       dt2.docname sConfBO,
       t.escort_docnumb sConfBONumb,
       t.escort_docdate dConfBODate,
       substr(eco.code, 1, 3) seconclass,
       ex.code sexpstruct,
       c.subject,
       fpf.jan,
       fpf.feb,
       fpf.mar,
       fpf.apr,
       fpf.may,
       fpf.jun,
       fpf.jul,
       fpf.aug,
       fpf.sep,
       fpf.oct,
       fpf.nov,
       fpf.dec,
       tb.duty_numb,
       tb.duty_date,
       br.code ubp_code,
       tre.ft_code,
       trea.agnname ft_name,
       ac2.agnacc ls_num,
       dr.code dr_code,
       dr.name dr_name,
       bgsa.agnname fin_name,
       t.rn,
       prsf_prop_nget(t.company, 'PayNotes', t.rn, 'Номер сведения') nsved
  from paynotes t, --
       stages s,
       contracts c,
       doctypes dt,
       curnames cur,
       (select fp.percent, fp.pay_sum, fp.prn from FCACPAYPLANS FP where FP.Fact_Sign = 0) fp,
       (select sum(decode(to_char(fp.end_date, 'mm'), '01', fp.pay_sum, 0)) jan,
               sum(decode(to_char(fp.end_date, 'mm'), '02', fp.pay_sum, 0)) feb,
               sum(decode(to_char(fp.end_date, 'mm'), '03', fp.pay_sum, 0)) mar,
               sum(decode(to_char(fp.end_date, 'mm'), '04', fp.pay_sum, 0)) apr,
               sum(decode(to_char(fp.end_date, 'mm'), '05', fp.pay_sum, 0)) may,
               sum(decode(to_char(fp.end_date, 'mm'), '06', fp.pay_sum, 0)) jun,
               sum(decode(to_char(fp.end_date, 'mm'), '07', fp.pay_sum, 0)) jul,
               sum(decode(to_char(fp.end_date, 'mm'), '08', fp.pay_sum, 0)) aug,
               sum(decode(to_char(fp.end_date, 'mm'), '09', fp.pay_sum, 0)) sep,
               sum(decode(to_char(fp.end_date, 'mm'), '10', fp.pay_sum, 0)) oct,
               sum(decode(to_char(fp.end_date, 'mm'), '11', fp.pay_sum, 0)) nov,
               sum(decode(to_char(fp.end_date, 'mm'), '12', fp.pay_sum, 0)) dec,
               fp.prn
          from FCACPAYPLANS FP
         group by fp.prn) fpf,
       jurpersons jp,
       agnlist ag,
       agnlist ag2,
       agnacc agc,
       agnacc ac,
       agnbanks ba,
       agnlist ag3,
       (select edv.num_value, edv.note, dpv.unit_rn
          from docs_props dp, docs_props_vals dpv, extra_dicts ed, extra_dicts_values edv
         where dp.rn = dpv.docs_prop_rn
           and dp.code = 'Способ размещения'
           and dp.code = ed.code
           and edv.prn = ed.rn
           and edv.num_value = dpv.num_value) dp,
       paynotesbudg tb,
       doctypes dt2,
       budgexpend be,
       budgexpend_sp bes,
       expstructitems bei,
       econclass eco,
       expstruct ex,
       budgrecip br,
       agnacc ac2,
       agntreas tre,
       agnlist trea,
       dirrecip dr,
       budgets bgs,
       agnlist bgsa
 where s.faceacc = t.faceacc
   and s.prn = c.rn
   and dt.rn = c.doc_type
   and cur.rn = t.currency
   and fp.prn(+) = s.faceacc
   and fpf.prn(+) = s.faceacc
   and jp.rn = c.jur_pers
   and ag.rn = jp.agent
   and ag2.rn = c.agent
   and agc.rn(+) = c.agnacc
   and ac.rn(+) = nvl(agc.treas_agnacc, agc.rn)
   and ba.rn(+) = ac.agnbanks
   and ag3.rn(+) = ba.agnrn
   and dp.unit_rn(+) = t.rn
   and tb.prn = t.rn
   and dt2.rn(+) = t.escort_doctype
   and tb.budgexpend_sp = bes.rn(+)
   and be.rn(+) = bes.prn
   and bei.rn(+) = bes.expstructitems
   and eco.rn = nvl(bei.econclass, tb.econclass)
   and ex.rn = nvl(be.expstruct, tb.expstruct)
   and br.agent(+) = ag.rn
   and ac2.rn = c.jur_acc
   and tre.rn(+) = ac2.agntreas
   and trea.rn(+) = tre.agnrn
   and dr.rn(+) = br.dirrecip
   and bgs.rn(+) = br.budget
   and bgsa.rn(+) = bgs.finagency
   and t.signplan = 1
--   and t.rn = 77999208

