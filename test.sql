select dt.distributor_id,dm.name as distributor_name ,im.d_inv_date::DATE::VARCHAR as invoice_date,dt.n_inv_no::VARCHAR as invoice_no, null::VARCHAR as challan_no
,(CAST(date(im.d_inv_date)||' '||split_part(im.t_time,' ',2) as TIMESTAMP)) as invoice_timestamp
--,(CAST(date(im.d_inv_date)||' '||split_part(im.t_ltime,' ',2) as TIMESTAMP)) as inv_timestamp_b
--,im.t_ltime as inv_timestamp_c
  ,MAX(CASE
        WHEN dt.c_stage_code = 3 and dt.distributor_id=157 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        WHEN dt.c_stage_code = 4 and dt.distributor_id=6 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        WHEN dt.c_stage_code = 4 and dt.distributor_id=5 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        WHEN dt.c_stage_code = 4 and dt.distributor_id=52 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        WHEN dt.c_stage_code = 4 and dt.distributor_id=73 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        ELSE NULL
    END) AS pick_start
        ,MAX(CASE
        WHEN dt.c_stage_code = 4 and dt.distributor_id=157 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        WHEN dt.c_stage_code = 6 and dt.distributor_id=6 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        WHEN dt.c_stage_code = 5 and dt.distributor_id=5 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        WHEN dt.c_stage_code = 5 and dt.distributor_id=52 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        WHEN dt.c_stage_code = 5 and dt.distributor_id=73 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        ELSE NULL
    END) AS pick_finish
        ,MAX(CASE
        WHEN dt.c_stage_code = 6 and dt.distributor_id=157 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        WHEN dt.c_stage_code = 7 and dt.distributor_id=6 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        WHEN dt.c_stage_code = 7 and dt.distributor_id=5 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        WHEN dt.c_stage_code = 7 and dt.distributor_id=52 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        WHEN dt.c_stage_code = 7 and dt.distributor_id=73 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        ELSE NULL
    END) AS check_finish
        ,MAX(CASE
        WHEN dt.c_stage_code = 8 and dt.distributor_id=157 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        WHEN dt.c_stage_code = 8 and dt.distributor_id=6 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        WHEN dt.c_stage_code = 8 and dt.distributor_id=5 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        WHEN dt.c_stage_code = 8 and dt.distributor_id=52 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        WHEN dt.c_stage_code = 8 and dt.distributor_id=73 THEN CAST(date(dt.d_date)||' '||split_part(dt.t_time,' ',2) as TIMESTAMP)
        ELSE NULL
    END) AS delivery_out,pl.picks,pl.line_items
    from pharmassist.doc_track dt
    INNER join pharmassist.invoice_mst im
    on dt.n_inv_no=im.n_srno
    and dt.distributor_id=im.distributor_id
    and dt.fin_year=im.fin_year
    left join adhoc.distributor_name dm
    on dt.distributor_id=dm.distributor_id
    left join
    (
	    select n_srno,d_inv_date,distributor_id,sum(n_qty+n_scheme_qty) as picks,COUNT(DISTINCT c_item_code) as line_items from pharmassist.invoice_det
		where d_inv_date>CURRENT_DATE-4
		GROUP by 1,2,3
	)pl
	ON pl.n_srno=dt.n_inv_no and pl.distributor_id=dt.distributor_id
    where dt.distributor_id in (2,6,5,52,73,157)
    and im.c_prefix='I'
    and (case when dt.distributor_id=52 then extract(hour from im.t_time) BETWEEN 4 and 15 else to_char(im.t_time, 'HH24:MI:SS') BETWEEN '08:29:59' and '20:29:59' end )
    and date(im.d_inv_date)>CURRENT_DATE-4
    GROUP BY 1,2,3,4,5,6,11,12
UNION
(	
select
base.distributor_id::INT,
(CASE	
WHEN base.distributor_id=70 then 'Mayapuri'
WHEN base.distributor_id=71 then 'Patpadganj'
WHEN base.distributor_id=64 then 'Aryan Wellness'
END) as Distrbutor_name
,base.vdt::date::VARCHAR
,base.invoice_no::int::varchar,challan_no::int::VARCHAR
		,chn_print_stg
		, store_in_stg
		, store_out_stg
		, check_out_stg
--		, inv_print_stg
		, inv_dispout_stg
--		, inv_delcomp_stg
		,sum(qty) as total_picks
		,count(DISTINCT itemc) as line_items_processed
		FROM
	(
	SELECT
		DISTINCT
		c.distributor_id
		,s.vdt
		,a.name
		,s.acno as party_code
		,s.srlno
		,c.vno as challan_no
		,s.vno as invoice_no
		,s.itemc
		,s.netamt as amt
		,s.qty+s.fqty as qty
	FROM easysol.salepurchase2 c
	JOIN easysol.salepurchase2 s ON s.refvno = c.vno AND s.refvtype = c.vtype AND s.distributor_id = c.distributor_id AND s.itemc = c.itemc
	JOIN easysol.acm a ON a.code = s.acno AND a.distributor_id = s.distributor_id
	WHERE c.distributor_id IN (70,71,64) AND a.slcd='CL' AND s.vdt::date > CURRENT_DATE-4 AND s.vtype in ('SB') 
	)base
	LEFT JOIN -- CHALLAN TRACK JOIN
	(
	select
	bd.distributor_id
	,bd.vtype
	,bd.vno
	,MIN(CASE
	       WHEN bd.srl = 2 THEN cast((date(bd.scandt)||' '||REPLACE(bd.mtime,'.',':')) as datetime)
	       ELSE NULL
	   END) AS chn_print_stg
	,MAX(CASE
	       WHEN bd.srl = 3 THEN cast((date(bd.scandt)||' '||REPLACE(bd.mtime,'.',':')) as datetime)
	       ELSE NULL
	   END) AS store_in_stg
	,MAX(CASE
	       WHEN bd.srl = 4 THEN cast((date(bd.scandt)||' '||REPLACE(bd.mtime,'.',':')) as datetime)
	       ELSE NULL
	   END) AS store_out_stg
 	,MAX(CASE
	       WHEN bd.srl = 5 THEN cast((date(bd.scandt)||' '||REPLACE(bd.mtime,'.',':')) as datetime)
	       ELSE NULL
	   END) AS check_out_stg
	   from easysol.billtrackdet bd
	where bd.vdt>CURRENT_DATE-4
	and bd.vtype='SN'  
    and to_char(cast((date(bd.scandt)||' '||REPLACE(bd.mtime,'.',':')) as datetime), 'HH24:MI:SS') BETWEEN '08:29:59' and '20:29:59'
	GROUP by 1,2,3
	)chln_track
	on
	base.challan_no=chln_track.vno and base.distributor_id=chln_track.distributor_id
	left join
	-- INVOICE TRACK JOIN
	(select
	bd.distributor_id
	,bd.vtype
	,bd.vno
	,SUM(CASE WHEN bd.srl=2 then 1 else 0 END) as inv_print_count
	,MIN(CASE
	       WHEN bd.srl = 2 THEN cast((date(bd.scandt)||' '||REPLACE(bd.mtime,'.',':')) as datetime)
	       ELSE NULL
	   END) AS inv_print_stg
	,MAX(CASE
	       WHEN bd.srl = 8 THEN cast((date(bd.scandt)||' '||REPLACE(bd.mtime,'.',':')) as datetime)
	       ELSE NULL
	   END) AS inv_dispout_stg
	,MAX(CASE
	       WHEN bd.srl = 9 THEN cast((date(bd.scandt)||' '||REPLACE(bd.mtime,'.',':')) as datetime)
	       ELSE NULL
	   END) AS inv_delcomp_stg
	from easysol.billtrackdet bd
	where bd.vdt>CURRENT_DATE-4
	and bd.vtype='SB'
	GROUP by 1,2,3)inv_track
	on
	base.invoice_no=inv_track.vno and base.distributor_id=inv_track.distributor_id
	group by 1,2,3,4,5,6,7,8,9,10
)
