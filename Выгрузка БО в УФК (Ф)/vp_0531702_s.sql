create or replace view vp_0531702_s as
select s.prn,
       substr(eco.code, 1, 3) seconclass, --
       ex.code sexpstruct,
       (s.description) subject,
       sum(fpf.jan) jan,
       sum(fpf.feb) feb,
       sum(fpf.mar) mar,
       sum(fpf.apr) apr,
       sum(fpf.may) may,
       sum(fpf.jun) jun,
       sum(fpf.jul) jul,
       sum(fpf.aug) aug,
       sum(fpf.sep) sep,
       sum(fpf.oct) oct,
       sum(fpf.nov) nov,
       sum(fpf.dec) dec,
       sum(fpf.all_summ) all_summ,
       fpf.sYEAR
  from stages s,
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
               sum(fp.pay_sum) all_summ,
               fp.prn,
               to_char(fp.end_date, 'yyyy') sYEAR
          from ( -- Все, кроме НДС:
                select fp.end_date, fp.pay_sum, fp.prn
                  from FCACPAYPLANS FP
                union all
                -- Плюс НДС, но сменим контрагента НДС на необходимого, подменим ЛС:
                select fp.end_date, fp.pay_sum, tn.nmainface
                  from (select st.faceacc, min(st2.faceacc) nmainface
                          from stages st, faceacc fc, agnlist ag, stages st2, faceacc fc2, agnlist ag2
                         where fc.rn = st.faceacc
                           and ag.rn = fc.agent
                           and ag.agnabbr = 'НДС'
                           and st.status = 1
                           and fc2.rn = st2.faceacc
                           and ag2.rn = fc2.agent
                           and ag2.agnabbr <> 'НДС'
                           and st2.status = 1
                           and st.prn = st2.prn
                           and st.begin_date = st2.begin_date
                         group by st.faceacc) tn,
                       FCACPAYPLANS FP
                 where tn.faceacc = fp.prn) FP
         group by fp.prn, to_char(fp.end_date, 'yyyy')) fpf,
       budgexpend be,
       budgexpend_sp bes,
       expstructitems bei,
       econclass eco,
       expstruct ex,
       faceacc fc,
       agnlist ag
 where fpf.prn(+) = s.faceacc
   and fc.rn = s.faceacc
   and ag.rn = fc.agent
   and ag.agnabbr <> 'НДС'
   and fc.budgexpend_sp = bes.rn(+)
   and be.rn = bes.prn
   and bei.rn = bes.expstructitems
   and eco.rn = bei.econclass
   and ex.rn = be.expstruct
   and s.status = 1 -- только открытые
   --and s.prn = 83883154
 group by s.prn,
          substr(eco.code, 1, 3), --
          ex.code,
          ag.rn,
          s.description,
          fpf.sYEAR

