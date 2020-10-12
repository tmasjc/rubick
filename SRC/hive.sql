select distinct 
    order_number, 
    user_id,
    term_id,
    new_budget_group_name as c_type,
    ip_city,
    order_city, 
    grade,
    pay_time,
    registr_time,
    start_time,
    parent_gender,
    child_gender,
    first_add_wx_time, 
    first_sub_time, 
    profile_id,
    filing_time, 
    pre_attend_time, 
    is_renew
from app.app_ua_user_l1_order_detail_df
where dt = date_format(date_sub(current_date(), 1), "yyyyMMdd")
    and term_id = ?terms
    -- and order_type != 'FREE' 
    and amount <= 990 
    and new_budget_group_name in ('C组','转介绍组','市场组','分销组')
    and class_id != 0 
    and class_id is not null;
