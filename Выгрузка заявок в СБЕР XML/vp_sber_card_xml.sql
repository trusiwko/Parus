create or replace view vp_sber_card_xml as
select rn nrn, --
       crn ncrn,
       agnfamilyname sagnfamilyname,
       agnfirstname sagnfirstname,
       agnlastname sagnlastname,
       docser sdocser,
       docnumb sdocnumb,
       docwhen sdocwhen,
       docwho sdocwho,
       depart_code sdepart_code,
       agnburn sagnburn,
       ssex sssex,
       addr_burn saddr_burn,
       a1 sa1,
       a2 sa2,
       a3 sa3,
       a4 sa4,
       a5 sa5,
       a6 sa6,
       a7 sa7,
       a8 sa8,
       a9 sa9,
       a10 sa10,
       a11 sa11,
       a12 sa12,
       o1 so1,
       o2 so2,
       o3 so3,
       o4 so4,
       o5 so5,
       o6 so6,
       o7 so7,
       o8 so8,
       o9 so9,
       o10 so10,
       o11 so11,
       o12 so12,
       phone sphone,
       emb_1 semb_1,
       emb_2 semb_2,
       emb_3 semb_3,
       nvl(length(emb_1), 0) + nvl(length(emb_2), 0) + nvl(length(emb_3), 0) nemb_length,
       control scontrol,
       case
         when t.agnfamilyname is null or t.agnfirstname is null then
          'ФИО'
         else
          case
         when (t.docser is not null and length(t.docser) <> 5) or (t.docnumb is null) or (t.docwhen is null) then
          'Паспорт'
         else
          case
         when t.ssex is null then
          'Пол'
         else
          case
         when t.agnburn is null then
          'Дата рождения'
         else
          case
         when t.a1 is null or t.a6 is null or t.a10 is null then
          'Адрес'
         else
          case
         when (t.emb_1 is null and t.emb_2 is null) or (nvl(length(emb_1), 0) + nvl(length(emb_2), 0) + nvl(length(emb_3), 0) > 19) then
          'Эмбоссируемое имя'
         else
          case
         when t.control is null then
          'Контрольная информация'
       end end end end end end end sERROR_TEXT,
       case
         when t.agnfamilyname is null or t.agnfirstname is null then
          1
         else
          case
         when (t.docser is not null and length(t.docser) <> 5) or (t.docnumb is null) or (t.docwhen is null) then
          2
         else
          case
         when t.ssex is null then
          3
         else
          case
         when t.agnburn is null then
          4
         else
          case
         when t.a1 is null or t.a6 is null or t.a10 is null then
          5
         else
          case
         when (t.emb_1 is null and t.emb_2 is null)  or (nvl(length(emb_1), 0) + nvl(length(emb_2), 0) + nvl(length(emb_3), 0) > 19)  then
          6
         else
          case
         when t.control is null then
          7
       end end end end end end end nERROR_NUMB,
       t.loadstate sloadstate
  from tp_sber_card_xml t

