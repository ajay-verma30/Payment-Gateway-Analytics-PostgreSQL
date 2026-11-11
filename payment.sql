-- Payments table sql queries practice
-- EASY ones

Q1. Merchant overview
Total merchants, active merchants aur inactive merchants count karo.

SELECT COUNT(*) as total_merchants, status FROM merchants GROUP BY status;

 count
-------
  1750
    78
    89
    83
(4 rows)

-- ----------------------------------------------------------
Q2. Currency distribution
Har currency ke against kitne merchants registered hain? Highest count first

SELECT COUNT(m.*) AS total_merchants, cu.name 
FROM merchants m 
JOIN currencies cu
ON cu.code = m.default_currency
GROUP BY cu.name
ORDER BY COUNT(m.*) DESC;

 total_merchants |       name
-----------------+-------------------
             552 | Euro
             459 | Indian Rupee
             431 | US Dollar
             183 | Pound Sterling
             108 | Canadian Dollar
              92 | Australian Dollar
              91 | Singapore Dollar
              84 | UAE Dirham
(8 rows)


-- -------------------------------------------
Q3. Payment status
Total succeeded, failed, pending aur cancelled payment charges count karo.

SELECT COUNT(*) as total_charges, status FROM charges 
GROUP BY status;

 total_charges |  status
---------------+-----------
         17282 | failed
             1 | pending
         89768 | succeeded


-- -------------------------------------------------
Q4. Transaction volume

Har merchant ka total number of charges aur total transaction 
amount calculate karo.

SELECT ch.merchant_id, count(ch.*) as total_charges, SUM(ch.amount) as total_amount, ch.currency as currency 
FROM charges ch
WHERE status = 'succeeded'
GROUP BY ch.merchant_id, ch.currency
ORDER BY ch.merchant_id DESC;


SELECT merchant_id, count(*) as total_charges, SUM(amount) as total_amount
FROM charges
GROUP BY merchant_id; 

      merchant_id      | total_charges | total_amount
-----------------------+---------------+--------------
 acct_00cUuQsaUZQjBHXW |            67 |        75257
 acct_02fijY3xjP34BW7Z |             6 |         5846
 acct_02KMd3QxfF31gVfx |            21 |       165647
 acct_03jmwRdWa0c06X9C |            44 |       112834
 acct_05wTrQddmH4LIR2K |            22 |      7823911
 acct_06Oy4dY9bO2Q8rNY |           266 |       847352
 acct_09x7g7pbZFzmzMi6 |             9 |        47100
 acct_09YOz0jVyFCa9PLg |           109 |       247620
 acct_0aFtBGO5IoGF1J1O |            12 |       172750
 acct_0HLJfuRv3tCBbYiD |             4 |         5591
(10 rows)

-- ----------------------------------------
Q5. Payment methods
Har payment method type (card, UPI, wallet etc.) ke against total 
payment methods count karo.

SELECT COUNT(type) as total_types, types FROM payment_methods;

 total_types |    type
-------------+------------
        2284 | sepa_debit
         955 | ach_debit
        1980 | bnpl
        6286 | wallet
        3518 | upi
         560 | ideal
       29922 | card
(7 rows)


-- -------------------------------------
Q6. Merchant-wise customer count
Har merchant ke against kitne unique customers registered hain, calculate karo.



SELECT m.merchant_id AS merchant, 
COUNT (DISTINCT(cu.customer_id)) as total_customers
FROM merchants m
JOIN customers cu
ON cu.merchant_id = m.merchant_id
GROUP BY m.merchant_id


-- ------------------------------
Q7. Har payment method type ke against kitne 
unique customers ne woh payment method save kiya hai?


SELECT COUNT(DISTINCT customer_id) as total_customers, 
type as payment_type
FROM payment_methods 
WHERE detached_at is NULL
GROUP BY type; 

 total_customers | payment_type
-----------------+--------------
             818 | ach_debit
            1726 | bnpl
           21493 | card
             438 | ideal
            1906 | sepa_debit
            2818 | upi
            5283 | wallet


-- ---------------------------
Q8 2026 mein har month kitne charges process hue, calculate karo


SELECT DATE_TRUNC('month', created_at) AS charge_month,
COUNT(*) as charges_processed 
FROM charges 
WHERE created_at >= '2026-01-01'
AND created_at < '2027-01-01'
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY charge_month;

      charge_month      | charges_processed
------------------------+-------------------
 2026-01-01 00:00:00+04 |              6260
 2026-02-01 00:00:00+04 |              5963
 2026-03-01 00:00:00+04 |              6910
 2026-04-01 00:00:00+04 |              7026
 2026-05-01 00:00:00+04 |              7759
 2026-06-01 00:00:00+04 |              8241
 2026-07-01 00:00:00+04 |              9625
 2026-08-01 00:00:00+04 |             10790
 2026-09-01 00:00:00+04 |             12769
 2026-10-01 00:00:00+04 |             19546
 2026-11-01 00:00:00+04 |               146


-- -----------------------------------------
Q9: Failed payments by currency — failed charges ko currency-wise count aur sum karo.

SELECT currency, COUNT(*) as total_failed_charges, SUM(amount) as total_sum FROM charges 
WHERE status = 'failed'
GROUP BY currency;


 currency | total_failed_charges | total_sum
----------+----------------------+------------
 CAD      |                  863 |    5310425
 AED      |                  861 |   35049002
 EUR      |                 4360 |   24354658
 SGD      |                 1194 |   11338289
 AUD      |                  909 |    8763982
 USD      |                 3554 |   32566564
 GBP      |                 1673 |   12007219
 INR      |                 3868 | 2366194132

-- ------------------------------------------------------
Q10: Un merchants ko identify karo jinke paas 100 se zyada successful charges hain.

SELECT merchant_id, count(*) AS total_charges
FROM charges 
WHERE status = 'succeeded'
GROUP BY merchant_id
HAVING count(*) > 100
ORDER BY count(*) DESC
LIMIT 10;

      merchant_id      | total_charges
-----------------------+---------------
 acct_3jUeNnp0lFWYmwIK |          3795
 acct_6zrBJh7D77dhlJvb |          1391
 acct_HSg8N61KrQFzS3kI |          1388
 acct_99oAzsjdMcMfjayu |          1383
 acct_TF8l6iIxUipo5HkW |          1084
 acct_M8FcoM1LztQ3rIAp |           852
 acct_66hD42HBdDFNGn8n |           747
 acct_HAPfkjJecPTpQfzw |           680
 acct_k1Z2PZyWEXjsnzYh |           673
 acct_ImKJ5JzkuKwwa6Zp |           654



-- -----------------------------------
Q11:Har merchant ke against total failed charges count karo.
Expected: merchant_id and total_failed_charges

SELECT merchant_id, count(*) as total_failed 
FROM charges 
WHERE status = 'failed'
GROUP BY merchant_id
ORDER BY count(*) DESC LIMIT 10;

      merchant_id      | total_failed
-----------------------+--------------
 acct_3jUeNnp0lFWYmwIK |          690
 acct_6zrBJh7D77dhlJvb |          275
 acct_HSg8N61KrQFzS3kI |          261
 acct_99oAzsjdMcMfjayu |          254
 acct_TF8l6iIxUipo5HkW |          218
 acct_M8FcoM1LztQ3rIAp |          202
 acct_66hD42HBdDFNGn8n |          187
 acct_HAPfkjJecPTpQfzw |          133
 acct_98lBAgcv1xx9xQ8h |          126
 acct_PP0ROjtvxhfBS36D |          123


-- -------------------------------
Q12: Har payment method type ke against kitne charges process hue hain, count karo.

Expected columns:
- payment_method_type
- total_charges

SELECT payment_method_type, COUNT(*) as total_charges 
FROM charges
GROUP BY payment_method_type 

 payment_method_type | total_charges
---------------------+---------------
 sepa_debit          |          5408
 ach_debit           |          2225
 bnpl                |          4816
 wallet              |         14210
 upi                 |          8219
 ideal               |          1438
 card                |         70735



 Q13: Un 10 customers ko identify karo jinke against sabse zyada charges create hue hain.

Expected columns:
- customer_id
- total_charges


SELECT customer_id, COUNT(*) as total_charges 
FROM charges
GROUP BY customer_id
ORDER BY COUNT(*) DESC
LIMIT 10;
 
    customer_id     | total_charges
--------------------+---------------
                    |          4960
 cus_GisDSyO7QdQPoO |            55
 cus_OSopvw1JA1Hgyz |            53
 cus_7zgHa1ZVKl1m0u |            52
 cus_wcc4BYk12xXTBJ |            50
 cus_kmBAA26GuIAPJ2 |            46
 cus_ygGNBSvbv1PVZM |            40
 cus_d3i8nfgwQf06tf |            35
 cus_E8mZg5tHOsaxm9 |            29
 cus_Ah4CO6jdQwmuP1 |            28



 Q14: 2026 mein har month successful charges ka total amount currency-wise calculate karo.

Expected columns:
charge_month
currency
total_amount


SELECT DATE_TRUNC('month', created_at) as charge_month, currency, sum(amount) 
FROM charges
WHERE status = 'succeeded'
AND created_at >= '2026-01-01'
AND created_at < '2027-01-01'
GROUP BY DATE_TRUNC('month', created_at), currency
ORDER BY DATE_TRUNC('month', created_at);


   charge_month      | currency |    sum
------------------------+----------+------------
 2026-01-01 00:00:00+04 | AED      |    5707587
 2026-01-01 00:00:00+04 | AUD      |    2073667
 2026-01-01 00:00:00+04 | CAD      |    1119164
 2026-01-01 00:00:00+04 | EUR      |    7926566
 2026-01-01 00:00:00+04 | GBP      |    2430511
 2026-01-01 00:00:00+04 | INR      | 1015950970
 2026-01-01 00:00:00+04 | SGD      |    2805006
 2026-01-01 00:00:00+04 | USD      |    8125679
 2026-02-01 00:00:00+04 | AED      |    6995428
 2026-02-01 00:00:00+04 | AUD      |    1577797
 2026-02-01 00:00:00+04 | CAD      |    1320323
 2026-02-01 00:00:00+04 | EUR      |    7993395
 2026-02-01 00:00:00+04 | GBP      |    2217643
 2026-02-01 00:00:00+04 | INR      |  711202595
 2026-02-01 00:00:00+04 | SGD      |    2392605
 2026-02-01 00:00:00+04 | USD      |    8220936
 2026-03-01 00:00:00+04 | AED      |    7620269
 2026-03-01 00:00:00+04 | AUD      |    1934970
 2026-03-01 00:00:00+04 | CAD      |    1206097
 2026-03-01 00:00:00+04 | EUR      |    8532488
 2026-03-01 00:00:00+04 | GBP      |    3299850
 2026-03-01 00:00:00+04 | INR      |  752255663
 2026-03-01 00:00:00+04 | SGD      |    4387796
 2026-03-01 00:00:00+04 | USD      |    9966390
 2026-04-01 00:00:00+04 | AED      |    6750855
 2026-04-01 00:00:00+04 | AUD      |    2189694
 2026-04-01 00:00:00+04 | CAD      |    1618184
 2026-04-01 00:00:00+04 | EUR      |    8027374
 2026-04-01 00:00:00+04 | GBP      |    4423465
 2026-04-01 00:00:00+04 | INR      |  756797666
 2026-04-01 00:00:00+04 | SGD      |    2893225
 2026-04-01 00:00:00+04 | USD      |   10197865
 2026-05-01 00:00:00+04 | AED      |    8330228
 2026-05-01 00:00:00+04 | AUD      |    2428724
 2026-05-01 00:00:00+04 | CAD      |    1598389
 2026-05-01 00:00:00+04 | EUR      |    8516315
 2026-05-01 00:00:00+04 | GBP      |    7112623
 2026-05-01 00:00:00+04 | INR      |  757773999
 2026-05-01 00:00:00+04 | SGD      |    3478925
 2026-05-01 00:00:00+04 | USD      |   10669787
 2026-06-01 00:00:00+04 | AED      |    8202608
 2026-06-01 00:00:00+04 | AUD      |    2903842
 2026-06-01 00:00:00+04 | CAD      |    2154912
 2026-06-01 00:00:00+04 | EUR      |   10276827
 2026-06-01 00:00:00+04 | GBP      |    3722720
 2026-06-01 00:00:00+04 | INR      |  836471814
 2026-06-01 00:00:00+04 | SGD      |    4713018
 2026-06-01 00:00:00+04 | USD      |   11854484
 2026-07-01 00:00:00+04 | AED      |    9306706
 2026-07-01 00:00:00+04 | AUD      |    3659046
 2026-07-01 00:00:00+04 | CAD      |    2455516
 2026-07-01 00:00:00+04 | EUR      |   11644592
 2026-07-01 00:00:00+04 | GBP      |    4421916
 2026-07-01 00:00:00+04 | INR      |  980269704
 2026-07-01 00:00:00+04 | SGD      |    5577988
 2026-07-01 00:00:00+04 | USD      |   13537777
 2026-08-01 00:00:00+04 | AED      |    8564580
 2026-08-01 00:00:00+04 | AUD      |    4075980
 2026-08-01 00:00:00+04 | CAD      |    2730719
 2026-08-01 00:00:00+04 | EUR      |   12793860
 2026-08-01 00:00:00+04 | GBP      |    6089983
 2026-08-01 00:00:00+04 | INR      | 1066492425
 2026-08-01 00:00:00+04 | SGD      |    5875812
 2026-08-01 00:00:00+04 | USD      |   14473214
 2026-09-01 00:00:00+04 | AED      |   13638621
 2026-09-01 00:00:00+04 | AUD      |    5861613
 2026-09-01 00:00:00+04 | CAD      |    2877695
 2026-09-01 00:00:00+04 | EUR      |   15000277
 2026-09-01 00:00:00+04 | GBP      |    6111448
 2026-09-01 00:00:00+04 | INR      | 1244915374
 2026-09-01 00:00:00+04 | SGD      |    6026109
 2026-09-01 00:00:00+04 | USD      |   17596127
 2026-10-01 00:00:00+04 | AED      |   16993096
 2026-10-01 00:00:00+04 | AUD      |    9530924
 2026-10-01 00:00:00+04 | CAD      |    5230552
 2026-10-01 00:00:00+04 | EUR      |   25940654
 2026-10-01 00:00:00+04 | GBP      |    8928158
 2026-10-01 00:00:00+04 | INR      | 2105452438
 2026-10-01 00:00:00+04 | SGD      |   13154811
 2026-10-01 00:00:00+04 | USD      |   27436838
 2026-11-01 00:00:00+04 | AED      |      29420
 2026-11-01 00:00:00+04 | AUD      |     158394
 2026-11-01 00:00:00+04 | CAD      |      11915
 2026-11-01 00:00:00+04 | EUR      |     177162
 2026-11-01 00:00:00+04 | GBP      |      16849
 2026-11-01 00:00:00+04 | INR      |   14811179
 2026-11-01 00:00:00+04 | SGD      |      12091
 2026-11-01 00:00:00+04 | USD      |     237635


Q15: Har merchant ka average charge amount currency-wise calculate karo.

Expected columns:
- merchant_id
- currency
- average_charge_amount


SELECT merchant_id, currency, AVG(amount) 
FROM charges 
GROUP BY merchant_id, currency;

SAMPLE
    merchant_id      | currency |          avg
-----------------------+----------+------------------------
 acct_XVgfZ4M4tvkXPn9b | USD      |     12536.652173913043
 acct_09x7g7pbZFzmzMi6 | AUD      |  5233.3333333333333333
 acct_CWc5n7b5GFPC6gOn | EUR      |  3378.2500000000000000
 acct_m7azTXQE5oiMtDCq | EUR      |  2986.7692307692307692
 acct_JgL8ChbUgt0H22P6 | USD      |  5697.8571428571428571
 acct_vUfGs6BmJehANKdQ | CAD      |  8804.2702702702702703
 acct_NhIowq14XSwiJArp | EUR      |  2695.1764705882352941
 acct_MCOStEQPEq4HHDVs | INR      |    139949.333333333333
 acct_D2AIT8xGuc2IxWY9 | EUR      |  2142.1481481481481481
 acct_oLfs8Sq9mxBMqqPm | SGD      |     23392.427272727273
 acct_80byyYSd0nwkjGfe | EUR      |   673.4583333333333333
 acct_FCWQ8ugmGtY2l9Nq | GBP      |  6243.2000000000000000
 acct_eV3F4oE4LQzIxQdF | USD      |  2291.0000000000000000
 acct_1FIxYRNa7G7QGUpB | INR      |    132581.683615819209
 acct_JLiWWgy1oFZXyS5B | INR      |    109722.696428571429
 acct_jE8Wvu4f5PYuOubC | CAD      |  6596.2200000000000000
 acct_I4XIWM9G0kktZ2yB | USD      |  1929.8888888888888889
 acct_xWw09Pg3YIvSMVOZ | EUR      |     22502.088235294118
 acct_MMWbfmBKmwFHGNU0 | CAD      |  2952.7164179104477612
 acct_DaXv5pBZjrXt7HZH | EUR      |     36399.913043478261
 acct_BnQrsk1n147vOZed | AUD      |  4542.4000000000000000
 acct_2AjenXZp829UJ8QZ | CAD      |  5287.7839721254355401
 acct_7oBFaChthTZqcEhB | AUD      |  2451.3219512195121951
 acct_qZqLXlk79uoNKpnJ | INR      |    917118.700000000000
 acct_PGvqKAyPyYrRI3yo | GBP      |  2215.3157894736842105
 acct_dV7cg5XZmNZersHp | USD      |  1642.6666666666666667
 acct_4BJsreD6hzZEVxL9 | AED      |     31905.289719626168
 acct_5ZurMpVyuXwiXtOO | EUR      |  1701.5042735042735043


-- ------------------------------------
Q16:
Har card brand ke against total charges count karo.

Expected columns:
- card_brand
- total_charges

SELECT card_brand, COUNT(*) as total_charges FROM charges GROUP BY card_brand;

 card_brand | total_charges
------------+---------------
 visa       |         42816
 discover   |          1314
            |         22106
 amex       |          6959
 mastercard |         29557
 rupay      |          4299

-- --------------------------------------
 Q17: Har failure code ke against failed charges ki count nikalo.

Expected columns:
- failure_code
- total_failed_charges

SELECT failure_code, COUNT(*) as total_failure 
FROM charges
WHERE status = 'failed'
GROUP BY failure_code;


          failure_code           | total_failure
---------------------------------+---------------
 authentication_required         |          1937
 call_issuer                     |           184
 card_not_supported              |            89
 card_velocity_exceeded          |           240
 currency_not_supported          |            82
 do_not_honor                    |          1311
 expired_card                    |          6085
 fraudulent                      |           239
 generic_decline                 |          1151
 highest_risk_level              |           201
 incorrect_cvc                   |           359
 incorrect_number                |           145
 insufficient_funds              |          3305
 invalid_amount                  |            38
 invalid_expiry_year             |            64
 issuer_not_available            |           180
 lost_card                       |            78
 pickup_card                     |            45
 processing_error                |           491
 restricted_card                 |           192
 stolen_card                     |            78
 transaction_not_allowed         |           152
 try_again_later                 |           478
 withdrawal_count_limit_exceeded |           158

-- -------------------------------------------

 Q18:Domestic aur international charges ki total count nikalo.

Expected columns:
- is_international
- total_charges

SELECT is_international, count(*) as total_charges 
FROM charges
GROUP BY is_international;


 is_international | total_charges
------------------+---------------
 f                |         71573
                  |         22106
 t                |         13372

-- ---------------------------------------------
Q19:Har risk level ka average risk score calculate karo. Sirf un records ko consider karo jinka risk score available hai.

Expected columns:
- risk_level
- average_risk_score

SELECT risk_level, AVG(risk_score) as average_risk_score 
FROM charges 
WHERE risk_score is not null
GROUP BY risk_level;

 risk_level | average_risk_score
------------+---------------------
 elevated   | 75.0726600985221675
 normal     | 14.5292411273860259
 highest    | 90.2252747252747253


-- ------------------------------------------------

 Q20: Har currency ke against total captured amount calculate karo.

Expected columns:
- currency
- total_captured_amount

SELECT currency, SUM(amount_captured) as total_captured_amount 
FROM charges 
WHERE captured_at is not null
GROUP BY currency;

 currency | total_captured_amount
----------+-----------------------
 CAD      |              25147725
 AED      |              98380919
 EUR      |             129394711
 SGD      |              55137758
 AUD      |              39057790
 USD      |             146165170
 INR      |           11281052748
 GBP      |              52148622



-- Medium Questions


Q21: Har merchant ke successful charges ka total amount currency-wise calculate karo.

Tables: merchants, charges

Expected columns:
- merchant_id
- merchant_name
- currency
- total_successful_amount

SELECT m.merchant_id, m.legal_name as merchant_name, ch.currency as currency, SUM(ch.amount) as total_successfu_amount 
FROM merchants m
JOIN charges ch
ON m.merchant_id = ch.merchant_id
GROUP by m.merchant_id, ch.currency;

SAMPLE 
      merchant_id      |          merchant_name           | currency | total_successfu_amount
-----------------------+----------------------------------+----------+------------------------
 acct_JgL8ChbUgt0H22P6 | Bright Travel Online Inc         | USD      |                  39885
 acct_NhIowq14XSwiJArp | Zen Beauty Works SAS             | EUR      |                  45818
 acct_MCOStEQPEq4HHDVs | Atlas Threads Express Pvt Ltd    | INR      |                 419848
 acct_oLfs8Sq9mxBMqqPm | Terra Gadgets Hub Pte Ltd        | SGD      |                2573167
 acct_FCWQ8ugmGtY2l9Nq | Sunny Beauty Express Ltd         | GBP      |                  62432
 acct_JLiWWgy1oFZXyS5B | Nova Books Hub Pvt Ltd           | INR      |                6144471
 acct_xWw09Pg3YIvSMVOZ | Sunny Games House B.V.           | EUR      |                 765071
 acct_BnQrsk1n147vOZed | Swift Wear House Pty Ltd         | AUD      |                  22712
 acct_2AjenXZp829UJ8QZ | Maple Cloud House Inc.           | CAD      |                1517594
 acct_7oBFaChthTZqcEhB | Maple Fitness Direct Pty Ltd     | AUD      |                 502521
 acct_qZqLXlk79uoNKpnJ | Urban Books Hub Pvt Ltd          | INR      |                9171187
 acct_dV7cg5XZmNZersHp | Orbit Gadgets Group Inc          | USD      |                   9856
 acct_5ZurMpVyuXwiXtOO | Green Gadgets Direct Ltd         | EUR      |                 199076
 acct_zfGgD3jpS47ho9FZ | Royal Games Collective GmbH      | EUR      |                  19904
 acct_4PeMkIpUDA2BoGYe | Swift Gifts Express Inc          | USD      |                  13624
 acct_8HerIm922F9uIUF0 | Indigo Cafe Point Inc            | USD      |                 388182
 acct_BwPUqFFFznkbdYe1 | Coral Foods Hub Inc              | USD      |                 449109
 acct_vcvZiFOQuJSMZng5 | Alpine Foods Online Pvt Ltd      | INR      |                 542215
 acct_uHEPRC55D3Nihent | Royal Foods House GmbH           | EUR      |                  20825
 acct_PKovoMNImnYCBt5o | Green Travel Hub Ltd             | GBP      |                3065304
 acct_z5qyS2l9AvhbILf4 | Echo Threads House Inc           | USD      |                 377592
 acct_PFFTBQA1Ir2t67IC | Sunny Travel Works Pvt Ltd       | INR      |                8243448



--  -----------------------------------------------
Q22: Har customer ne total kitne refunds receive kiye aur total refund amount kitna hai, calculate karo.

Tables: charges, refunds

Expected columns:
- customer_id
- total_refunds
- total_refund_amount


SELECT ch.customer_id, COUNT(*) as total_refunds, SUM(rf.amount) as total_refund_amount
FROM charges ch 
JOIN refunds rf
ON rf.charge_id = ch.charge_id
GROUP BY ch.customer_id;


    customer_id     | total_refunds | total_refund_amount
--------------------+---------------+---------------------
                    |           246 |            27418940
 cus_rWzQkBAWxtGsa0 |             1 |                6933
 cus_vfYAv8V5dHEmTl |             2 |                5458
 cus_Uol7mKxZkVXE7Y |             1 |               35013
 cus_vzxlX1jex7b9IH |             1 |                4399
 cus_sBsSQNQVWn7gZP |             1 |              163217
 cus_MF8SIcY4jBAnx2 |             1 |               13681
 cus_TXzdkX9ZdPZYe9 |             1 |                2501
 cus_nU1IsmZx2eImEN |             1 |             1128960
 cus_tSFQTdDJ6A57pI |             1 |                 328
 cus_gRyDwsZl9XUx3H |             1 |                 498
 cus_3FQQwR9LiT3jsy |             1 |              445058
 cus_0Ef72LKz7jYIX0 |             1 |                5948
 cus_prjojjPRmayzzN |             2 |              591650
 cus_GzyFOUxunCcsKL |             1 |               69399
 cus_hEA5MOzEa3DF9J |             1 |               11372
 cus_bH7AJGQeeIWrKf |             1 |              653418

SELECT ch.customer_id, COUNT(*) as total_refunds, SUM(rf.amount) as total_refund_amount
FROM charges ch 
JOIN refunds rf
ON rf.charge_id = ch.charge_id
WHERE ch.customer_id is NOT NULL
GROUP BY ch.customer_id;

    customer_id     | total_refunds | total_refund_amount
--------------------+---------------+---------------------
 cus_rWzQkBAWxtGsa0 |             1 |                6933
 cus_vfYAv8V5dHEmTl |             2 |                5458
 cus_Uol7mKxZkVXE7Y |             1 |               35013
 cus_vzxlX1jex7b9IH |             1 |                4399
 cus_sBsSQNQVWn7gZP |             1 |              163217
 cus_MF8SIcY4jBAnx2 |             1 |               13681
 cus_TXzdkX9ZdPZYe9 |             1 |                2501
 cus_nU1IsmZx2eImEN |             1 |             1128960
 cus_tSFQTdDJ6A57pI |             1 |                 328
 cus_gRyDwsZl9XUx3H |             1 |                 498
 cus_3FQQwR9LiT3jsy |             1 |              445058
 cus_0Ef72LKz7jYIX0 |             1 |                5948
 cus_prjojjPRmayzzN |             2 |              591650
 cus_GzyFOUxunCcsKL |             1 |               69399
 cus_hEA5MOzEa3DF9J |             1 |               11372
 cus_bH7AJGQeeIWrKf |             1 |              653418


-- --------------------------------------
Q23: Har merchant ke against failed charges ki count aur failure codes identify karo.

Tables: merchants, charges

Expected columns:
- merchant_id
- merchant_name
- failure_code
- total_failures

SELECT m.merchant_id, m.legal_name, ch.failure_code, COUNT(ch.*) as total_failures
FROM merchants m
JOIN charges ch
ON ch.merchant_id = m.merchant_id
GROUP BY m.merchant_id, ch.failure_code;


SAMPLE
      merchant_id      |            legal_name            |          failure_code           | total_failures
-----------------------+----------------------------------+---------------------------------+----------------
 acct_00cUuQsaUZQjBHXW | Sunny Studio Hub GmbH            | authentication_required         |              4
 acct_00cUuQsaUZQjBHXW | Sunny Studio Hub GmbH            | do_not_honor                    |              2
 acct_00cUuQsaUZQjBHXW | Sunny Studio Hub GmbH            |                                 |             61
 acct_02fijY3xjP34BW7Z | Nova Home House Ltd              |                                 |              6
 acct_02KMd3QxfF31gVfx | Urban Home House Inc             | expired_card                    |              4
 acct_02KMd3QxfF31gVfx | Urban Home House Inc             |                                 |             17
 acct_03jmwRdWa0c06X9C | Atlas Travel Express S.r.l.      | authentication_required         |              1
 acct_03jmwRdWa0c06X9C | Atlas Travel Express S.r.l.      | insufficient_funds              |              1
 acct_03jmwRdWa0c06X9C | Atlas Travel Express S.r.l.      | restricted_card                 |              1
 acct_03jmwRdWa0c06X9C | Atlas Travel Express S.r.l.      | try_again_later                 |              2
 acct_03jmwRdWa0c06X9C | Atlas Travel Express S.r.l.      |                                 |             39
 acct_05wTrQddmH4LIR2K | Sunny Books Co Pvt Ltd           | authentication_required         |              1
 acct_05wTrQddmH4LIR2K | Sunny Books Co Pvt Ltd           | do_not_honor                    |              3
 acct_05wTrQddmH4LIR2K | Sunny Books Co Pvt Ltd           | expired_card                    |              5
 acct_05wTrQddmH4LIR2K | Sunny Books Co Pvt Ltd           | insufficient_funds              |              1
 acct_05wTrQddmH4LIR2K | Sunny Books Co Pvt Ltd           |                                 |             12
 acct_06Oy4dY9bO2Q8rNY | Nova Cloud Direct SAS            | authentication_required         |              3
 acct_06Oy4dY9bO2Q8rNY | Nova Cloud Direct SAS            | call_issuer                     |              1
 acct_06Oy4dY9bO2Q8rNY | Nova Cloud Direct SAS            | do_not_honor                    |              3
 acct_06Oy4dY9bO2Q8rNY | Nova Cloud Direct SAS            | expired_card                    |             30
 acct_06Oy4dY9bO2Q8rNY | Nova Cloud Direct SAS            | incorrect_cvc                   |              2
 acct_06Oy4dY9bO2Q8rNY | Nova Cloud Direct SAS            | insufficient_funds              |              7
 acct_06Oy4dY9bO2Q8rNY | Nova Cloud Direct SAS            | try_again_later                 |              1
 acct_06Oy4dY9bO2Q8rNY | Nova Cloud Direct SAS            | withdrawal_count_limit_exceeded |              1
 acct_06Oy4dY9bO2Q8rNY | Nova Cloud Direct SAS            |                                 |            218
 acct_09x7g7pbZFzmzMi6 | Atlas Gifts House Pty Ltd        | expired_card                    |              1
 acct_09x7g7pbZFzmzMi6 | Atlas Gifts House Pty Ltd        |                                 |              8
 acct_09YOz0jVyFCa9PLg | Terra Cart House GmbH            | authentication_required         |              3
 acct_09YOz0jVyFCa9PLg | Terra Cart House GmbH            | call_issuer                     |              1
 acct_09YOz0jVyFCa9PLg | Terra Cart House GmbH            | expired_card                    |              5
 acct_09YOz0jVyFCa9PLg | Terra Cart House GmbH            | insufficient_funds              |              2
 acct_09YOz0jVyFCa9PLg | Terra Cart House GmbH            | withdrawal_count_limit_exceeded |              1
 acct_09YOz0jVyFCa9PLg | Terra Cart House GmbH            |                                 |             97
 acct_0aFtBGO5IoGF1J1O | Pixel Games Group Inc            |                                 |             12
 acct_0HLJfuRv3tCBbYiD | Coral Books Works Inc            |                                 |              4
 acct_0KDAMnpGtP3wJrXn | Bright Wear Hub Inc.             | authentication_required         |              1
 acct_0KDAMnpGtP3wJrXn | Bright Wear Hub Inc.             | expired_card                    |              2
 acct_0KDAMnpGtP3wJrXn | Bright Wear Hub Inc.             | generic_decline                 |              1
 acct_0KDAMnpGtP3wJrXn | Bright Wear Hub Inc.             | incorrect_cvc                   |              1
 acct_0KDAMnpGtP3wJrXn | Bright Wear Hub Inc.             | insufficient_funds              |              3
 acct_0KDAMnpGtP3wJrXn | Bright Wear Hub Inc.             |                                 |             31
 acct_0MHn7ZGgVumTZMeL | Pixel Beauty Express Pte Ltd     | insufficient_funds              |              1
 acct_0MHn7ZGgVumTZMeL | Pixel Beauty Express Pte Ltd     |                                 |             22



-- --------------------------------------------------
 Q24: Har payment method type ke against successful aur failed charges ki count calculate karo.

Table: charges

Expected columns:
- payment_method_type
- successful_charges
- failed_charges


SELECT payment_method_type, 
COUNT(*) FILTER(WHERE status = 'succeeded') as successful_charges,
COUNT(*) FILTER(WHERE status = 'failed') as failed_charges
FROM charges
GROUP BY payment_method_type;


 payment_method_type | successful_charges | failed_charges
---------------------+--------------------+----------------
 ach_debit           |               2041 |            184
 bnpl                |               4151 |            665
 card                |              57600 |          13135
 ideal               |               1348 |             90
 sepa_debit          |               4991 |            416
 upi                 |               7535 |            684
 wallet              |              12102 |           2108

-- --------------------------
Q25: Har merchant ke against total disputes aur disputed amount calculate karo.

Tables: merchants, disputes

Expected columns:
- merchant_id
- merchant_name
- total_disputes
- total_disputed_amount

SELECT d.merchant_id, m.legal_name as merchant_name, COUNT(d.*) as total_disputes, SUM(d.amount) as total_disputed_amount
FROM disputes d
JOIN merchants m
ON m.merchant_id = d.merchant_id
GROUP BY d.merchant_id, m.legal_name;




      merchant_id      |          merchant_name           | total_disputes | total_disputed_amount
-----------------------+----------------------------------+----------------+-----------------------
 acct_FSwU8vaT0Z8v4mK3 | Urban Bakes Point Pvt Ltd        |              2 |                121135
 acct_D6EUfdyu5EE01WBn | Atlas Pets Collective Pty Ltd    |              1 |                  3299
 acct_uGhyqcajUcFbnlvU | Coral Cloud House Ltd            |              1 |                  2299
 acct_I8jtlZ0ZoqyVU9W7 | Pixel Gifts Online Inc.          |              2 |                 70682
 acct_vUfGs6BmJehANKdQ | Zen Gifts Point Inc.             |              3 |                 17748
 acct_dyUHEiJftoODA0yV | Maple Foods Collective LLC       |              1 |                  6070
 acct_Dc4Nl3QQ5zwM3YWV | Alpine Games Co Inc.             |              1 |                 10395
 acct_SKQyhuDA3ntlJX2o | Orbit Pets Collective GmbH       |              1 |                  2831
 acct_M8zmhpV0sgSWdiuC | Swift Labs Direct B.V.           |              3 |                 15834
 acct_uedH07R5ojgkUjAU | Indigo Pets Hub SAS              |              1 |                  1199
 acct_iLb1bEPznp0iSsaz | Alpine Threads Hub B.V.          |              4 |                 10790
 acct_QzKRLa3rOJh2f75J | Atlas Cart Direct Pvt Ltd        |              2 |                326321
 acct_7ZjSwxmK1oHONqbZ | Urban Bakes House Ltd            |              1 |                  1041
 acct_7WXLeB74oUtzOELg | Alpine Books Online GmbH         |              3 |                  6534
 acct_5jlegyt7BtDSuiAM | Orbit Beauty Express B.V.        |              2 |                 36261
 acct_wi85zAAlgqxjc52s | Atlas Tech House Ltd             |              1 |                 18899
 acct_eTO6EDNjUElYq1qE | Cedar Games Collective Inc.      |              3 |                  2670
 acct_WB8uC4kZj4uNSxIU | Pixel Pets Direct Ltd            |              4 |                 10936
 acct_A7jzpLW5Bq7fi72I | Cedar Cafe Direct Pvt Ltd        |              1 |                 48999
 acct_wj91DuC7nQ4U16do | Alpine Pets Co Inc               |              4 |                  5578
 acct_FsjJMkhDcmNsCQko | Terra Foods Point GmbH           |              2 |                  5495
 acct_RMhW1ujJ6TYIzsYO | Cedar Tech Online Pvt Ltd        |              1 |                176199
 acct_G2NiTAbMs89PNsed | Indigo Threads Express S.L.      |              1 |                 13462
 acct_ClSzoEbGHyRKwShF | Maple Games House Inc.           |              1 |                  3790
 acct_9zs3klxeQWv1aGTx | Indigo Pets Co Inc               |              5 |                 24267
 acct_9jwll6uLjrwK3pNE | Lumen Foods Direct S.r.l.        |              2 |                  1462
 acct_janne9dTZNiTuzpW | Atlas Games House GmbH           |              3 |                 34746
 acct_FYt4zFbhr8qy0tYh | Indigo Studio Point Pvt Ltd      |              4 |                785690
 acct_xFGzC3raXeWu0kkz | Zen Cloud Collective Pte Ltd     |              1 |                 18153
 acct_sQWu3BsnqInwS2QG | Lumen Studio Online Ltd          |              1 |                  1699
 acct_oXQoWcxlaTjRe38t | Sunny Tech House Pvt Ltd         |              7 |               2738881
 acct_DaBnpQktydRVIbWB | Blue Cafe Direct Ltd             |              1 |                  2843
 acct_Q84enhtKifNNwSKz | Sunny Pets Point LLC             |              2 |                 13082
 acct_j4o8vrCr5LUeoKE8 | Blue Tech Co S.r.l.              |              1 |                   365
 acct_6WLT0MtehoVfh8yh | Coral Travel Works GmbH          |              2 |                 73798
 acct_0w48ePf2h3VHmqA0 | Terra Wear Works Ltd             |              3 |                 15812
 acct_cOQhT6RoffMoxdBk | Orbit Bakes Collective GmbH      |              1 |                 10010
 acct_YIktur6H9hSKVyGv | Cedar Gadgets Collective Pvt Ltd |              1 |                167718
-- More  --





-- ------------------------------------------

Q26: Har merchant ke successful charges ka total amount calculate karo aur top 10 merchants identify karo.

Tables: merchants, charges

Expected columns:
- merchant_id
- merchant_name
- currency
- total_amount


SELECT ch.merchant_id, m.legal_name as merchant_name, ch.currency as currency, SUM(ch.amount) as total_amount
FROM charges ch
JOIN merchants m
ON ch.merchant_id = m.merchant_id
WHERE ch.status ='succeeded'
GROUP BY ch.merchant_id, m.legal_name, ch.currency
ORDER BY SUM(ch.amount) DESC
LIMIT 10;

      merchant_id      |         merchant_name         | currency | total_amount
-----------------------+-------------------------------+----------+--------------
 acct_M8FcoM1LztQ3rIAp | Sunny Studio Direct Pvt Ltd   | INR      |   1903481078
 acct_nCaqt7rrqpHmsHUg | Swift Foods Point Pvt Ltd     | INR      |    741591726
 acct_jhuE6ZyKVxVPR8xe | Nova Cloud House Pvt Ltd      | INR      |    377826228
 acct_mYdljfIo75kZcrOm | Lumen Gadgets Express Pvt Ltd | INR      |    302103332
 acct_PP0ROjtvxhfBS36D | Sunny Fitness Express Pvt Ltd | INR      |    291406578
 acct_T7l2wMxm2vbj7YPW | Royal Cafe Hub Pvt Ltd        | INR      |    256695694
 acct_HAPfkjJecPTpQfzw | Pixel Threads Direct Pvt Ltd  | INR      |    235892664
 acct_iBOkiNNzhsnOsxqk | Pixel Cloud House Pvt Ltd     | INR      |    221341606
 acct_yIBv4q0LOr7DFpDQ | Blue Foods Point Pvt Ltd      | INR      |    213671303
 acct_pJrtPOb1KpgERbr6 | Green Gifts Online Pvt Ltd    | INR      |    212940836



--  ---------------------------

Q27: Un customers ko identify karo jinhone 2 ya usse zyada different payment method types save kiye hain.

Table: payment_methods

Expected columns:
- customer_id
- total_payment_types


SELECT customer_id, COUNT(DISTINCT(payment_method_type)) as total_payment_types
FROM charges 
GROUP BY customer_id
HAVING COUNT(DISTINCT(payment_method_type)) >= 2;

SAMPLE
    customer_id     | total_payment_types
--------------------+---------------------
 cus_01Uf45gSGSTPQq |                   2
 cus_03jbefI3czi3pq |                   2
 cus_07IOJQ1aTpwnIW |                   2
 cus_07OABXqYXLDJ1r |                   2
 cus_07YKHQROxPPBL9 |                   2
 cus_0AZ9L12e8r6q6x |                   2
 cus_0cLPnhtEq5koFs |                   2
 cus_0E6vxw2QARy2xr |                   2
 cus_0Elig7RboHRtZZ |                   2
 cus_0F80L0FW9Fm6yI |                   2
 cus_0FsVtf5R4nbk7s |                   2
 cus_0gKgm7xInTVFiW |                   2
 cus_0Hv8zP9DCGoQHK |                   2
 cus_0i2FmpJBli9Cis |                   2
 cus_0I9bzuxKKrWBGv |                   2
 cus_0iN74CJyX88PZF |                   2
 cus_0iSzH060JZO4wS |                   2
 cus_0JgwXvMpekd8NB |                   2
 cus_0MLRUWgXaofD5X |                   2
 cus_0o9LOuTQ59TvR7 |                   2
 cus_0oYtgokg2zWwiT |                   2
 cus_0Q55EiYWUB7RIk |                   2
 cus_0qxmrIlNvq2ply |                   2
 cus_0ryJkS4Rby7ar0 |                   2
 cus_0svRvsrzFaGMGv |                   2
 cus_0UcO3bOvefrSLQ |                   2
 cus_0xeHar7HqtLDt5 |                   2
 cus_0XG6AvAftvxb9G |                   2
 cus_0xQc5uBHA4l9fn |                   2
 cus_0YbEuyBZiwKtML |                   2
 cus_14JWKUa7DYGnSf |                   2
 cus_18thuxhvZ1DOhh |                   2
 cus_1BtCs16EgCKUng |                   2
 cus_1EFlgjN3it44MC |                   2
 cus_1EGK2ngIOO2wyc |                   2
 cus_1EpqlYMGjnp8Bo |                   2
 cus_1glHj4BnR8Ft9d |                   2
 cus_1IFJAp7LLHAluC |                   2
 cus_1JsyN9HBngIIrQ |                   2
 cus_1kJ4LiGAOVmsMC |                   2
 cus_1KVF7Jecvt2xn8 |                   2
 cus_1lXXDx8hd4FBKo |                   2
 cus_1mEjBvodcphYPo |                   2
 cus_1NSxtsMA2x3vh2 |                   2
 cus_1o1ZtpTGJsLyfM |                   2
 cus_1ooW6jQkhe1bPY |                   2
 cus_1QCHTVBJN5PrPp |                   2
 cus_1qywNP0s4qR1V7 |                   2
 cus_1SYdZXS5nS5wKy |                   2
 cus_1SYSw9T8QjKhrl |                   2
 cus_1tvt4EJsTnolsu |                   2
 cus_1usAdrL7lwl4KD |                   2
 cus_1wi4lCR5ioMC8e |                   2
 cus_1Xr8esR47fybaX |                   2
 cus_234o4fEO8OLG5b |                   2
 cus_27DwxnTL6clA6g |                   2
 cus_2ACzAV2MoRnNM1 |                   2
 cus_2bMQyZxkQZpxlY |                   2
 cus_2Cb6DPPYpaVByY |                   2
 cus_2CLgQsSUOza4J0 |                   2
 cus_2EA8wryfp9Rw3S |                   2
 cus_2FJPyXOo127i3s |                   2
 cus_2HJdoJwQYeUkGi |                   2
 cus_2hSY90nxxtP8iu |                   2
 cus_2jZuTR07aR5gm0 |                   2
 cus_2LOrAGrjEMitPj |                   2
 cus_2P9n4SlEDlER7E |                   2
 cus_2PaOOrunJrbQ6Y |                   2
 cus_2RicWStjBsIpJ4 |                   2
 cus_2RznvGlkhDcJNS |                   2
 cus_2ttDSDEmDFLgMZ |                   2
 cus_2VajNeJMtgqeMd |                   2
 cus_2vokNUp77466gr |                   2
 cus_2WEGrs72BE66mV |                   2
 cus_2xhIvIQKJYuL7A |                   2
 cus_2yE52ZbICGFJyj |                   3
 cus_2zhSQnZqJoLvEd |                   2
 cus_318AYHA6mITl6W |                   2
 cus_37k5CFMRLbmLi0 |                   2
 cus_39jd7GPenrDiLG |                   2
 cus_3aKx0lBK1sOMkZ |                   2
 cus_3Aou87mxVNVMuU |                   2
 cus_3gi9EbagGa7nNY |                   2
 cus_3isI87AKhuxjrz |                   2
 cus_3IVby2YwN0Vd1a |                   2
 cus_3j2Ne3BcyWH3mn |                   3
 cus_3jQMiFUYlTaEKH |                   2



-- ------------------------------------------
Q28: 2026 ke har month ka payment success rate calculate karo.

Table: charges

Expected columns:
- month
- total_charges
- successful_charges
- success_rate


SELECT 
DATE_TRUNC('month', created_at) as month, 
COUNT(*) as total_charges,
COUNT(*) FILTER(WHERE status = 'succeeded') as successful_charges,
ROUND(
    (COUNT(*) FILTER(WHERE status = 'succeeded') * 100.0) / COUNT(*), 2 
) as success_rate
FROM charges
WHERE created_at >= '2026-01-01'
AND created_at < '2027-01-01'
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month;


         month          | total_charges | successful_charges | success_rate
------------------------+---------------+--------------------+--------------
 2026-01-01 00:00:00+04 |          6260 |               5427 |        86.69
 2026-02-01 00:00:00+04 |          5963 |               5195 |        87.12
 2026-03-01 00:00:00+04 |          6910 |               5867 |        84.91
 2026-04-01 00:00:00+04 |          7026 |               5943 |        84.59
 2026-05-01 00:00:00+04 |          7759 |               6562 |        84.57
 2026-06-01 00:00:00+04 |          8241 |               6872 |        83.39
 2026-07-01 00:00:00+04 |          9625 |               8033 |        83.46
 2026-08-01 00:00:00+04 |         10790 |               8916 |        82.63
 2026-09-01 00:00:00+04 |         12769 |              10535 |        82.50
 2026-10-01 00:00:00+04 |         19546 |              15910 |        81.40
 2026-11-01 00:00:00+04 |           146 |                104 |        71.23


-- ----------------------------------------
Q29: Un merchants ko identify karo jinke successful charge counts, overall merchant average successful charge count se zyada hain.

Table: charges

Expected columns:
- merchant_id
- successful_charges



WITH merchant_total AS  
(SELECT merchant_id, COUNT(*) as total_successful_charge_counts 
FROM charges
WHERE status = 'succeeded'
GROUP BY merchant_id
),
overall_avg as (
    SELECT AVG(total_successful_charge_counts) as avg_successful_charge_counts
    FROM merchant_total
)
SELECT mt.merchant_id, mt.total_successful_charge_counts
FROM merchant_total mt
CROSS JOIN overall_avg oa
WHERE mt.total_successful_charge_counts > oa.avg_successful_charge_counts;



SAMPLE
   merchant_id      | total_successful_charge_counts
-----------------------+--------------------------------
 acct_nCaqt7rrqpHmsHUg |                            617
 acct_ImKJ5JzkuKwwa6Zp |                            654
 acct_HSg8N61KrQFzS3kI |                           1388
 acct_Q84enhtKifNNwSKz |                            106
 acct_TqGXPaLXiyNaS0GB |                            257
 acct_nk2SxGvzNmV68kzq |                            198
 acct_vUfGs6BmJehANKdQ |                             68
 acct_eUMhlslY5for9M7p |                             55
 acct_2NxMC3IBMlVmbdeg |                             60
 acct_EUTMmAYtOZHFlEch |                             77
 acct_Bh4y2T6OKorutK1c |                             67
 acct_97km3NHXeIJ5CFXq |                            322
 acct_9oaICgnmBUQbkLXc |                             61
 acct_o8ECaP2s1f7pDa3F |                             92
 acct_ClGmSeY8ULBGF3hK |                             78
 acct_7oBFaChthTZqcEhB |                            175
 acct_1DtxMRpkfE57IGFo |                             94
 acct_uOds7S6QlC2QG1h7 |                            163
 acct_23ZPh8eJXfEDmg43 |                            102
 acct_ut6AYoDdqebljtUj |                             77
 acct_bSOYiOwonrTb688Z |                            277
 acct_UurwomYvqYWpsYr1 |                             53
 acct_NMTFb2rpYXFQfrpA |                             87
 acct_pyb1hMrJZtbPGidG |                            233
 acct_38WAfvmO2EcyXNcv |                             66
 acct_8RhQvs9XVtPvLyLU |                             90
 acct_FbuxPywVVauVgHER |                             64
 acct_bCGbLzmgVgmSN9cm |                            105
 acct_6XJBpd7mvBPqnuud |                             69
 acct_7IhNDYylhUoPieSv |                             56
 acct_ATcSich2QWQXEYdK |                            352
 acct_6PHiB4XBtX7sYtZ7 |                            110
 acct_HREWgpjEyHjBVeWn |                            101
 acct_dyg0VfqCCkC1nhxE |                             71
 acct_KHKtk0ym9cvTz0wN |                             83
 acct_5jGJR5vhyjTJUv73 |                             57
 acct_3jpO2zqv44h30HpC |                             72
 acct_tfHXprrY70o0t19S |                             58


-- ------------------------------------------------------
Q30: Q10. Refund percentage by merchant
Har merchant ke successful charge amount aur refunded amount ke basis par refund percentage calculate karo.

Tables: charges, refunds

Expected columns:
- merchant_id
- currency
- successful_charge_amount
- refunded_amount
- refund_percentage

SELECT 
ch.merchant_id, 
ch.currency, 
SUM(ch.amount) FILTER(WHERE ch.status = 'succeeded') as successful_charge_amount,
SUM(r.amount) AS total_refund_amount,
ROUND(
    (SUM(r.amount) * 100.0) / NULLIF(SUM(ch.amount) FILTER(WHERE ch.status = 'succeeded'),0), 2
    ) as refund_percentage
FROM charges ch
JOIN refunds r
ON r.charge_id = ch.charge_id
GROUP BY ch.merchant_id, ch.currency;





SAMPLE 
 merchant_id      | currency | successful_charge_amount | total_refund_amount | refund_percentage
-----------------------+----------+--------------------------+---------------------+-------------------
 acct_t2CAWx2UpNDv4yhz | GBP      |                     8299 |                8299 |            100.00
 acct_e6p9Tws69Lc4DbXc | EUR      |                     4970 |                4970 |            100.00
 acct_09x7g7pbZFzmzMi6 | AUD      |                     1299 |                1299 |            100.00
 acct_2FhjUYOO18ZiXFXS | EUR      |                     5182 |                5182 |            100.00
 acct_vUfGs6BmJehANKdQ | CAD      |                     5949 |                5470 |             91.95
 acct_D2AIT8xGuc2IxWY9 | EUR      |                     3179 |                3179 |            100.00
 acct_oLfs8Sq9mxBMqqPm | SGD      |                   199184 |              177194 |             88.96
 acct_kgnjZ2Ii04zPLGvr | USD      |                     7347 |                7347 |            100.00
 acct_80byyYSd0nwkjGfe | EUR      |                     6241 |                6112 |             97.93
 acct_zQYhrkXNPMHYjRZm | GBP      |                     7499 |                7499 |            100.00
 acct_FCWQ8ugmGtY2l9Nq | GBP      |                    35352 |               35352 |            100.00
 acct_eV3F4oE4LQzIxQdF | USD      |                      999 |                 999 |            100.00
 acct_yO3pW9v3bxrbLGx1 | USD      |                    65063 |               33081 |             50.84
 acct_LjfvSAk9mfxgKA5k | INR      |                    60448 |               30424 |             50.33
 acct_1FIxYRNa7G7QGUpB | INR      |                  3359320 |             2835733 |             84.41
 acct_jE8Wvu4f5PYuOubC | CAD      |                    19999 |               19999 |            100.00
 acct_zztEEM7O5ZTqJg5l | AUD      |                   130370 |              129710 |             99.49
 acct_xWw09Pg3YIvSMVOZ | EUR      |                    28312 |               28312 |            100.00
 acct_N9bT1MQ3WcVUoO00 | EUR      |                     1099 |                 429 |             39.04
 acct_eobco3lRjCLIXpUz | USD      |                     3613 |                3023 |             83.67
 acct_MMWbfmBKmwFHGNU0 | CAD      |                     5940 |                5068 |             85.32
 acct_VOUrkioHMU7ZwD7S | CAD      |                    51584 |               51584 |            100.00
 acct_BnQrsk1n147vOZed | AUD      |                     7299 |                7299 |            100.00
 acct_2AjenXZp829UJ8QZ | CAD      |                   120627 |              117410 |             97.33
 acct_7oBFaChthTZqcEhB | AUD      |                    30255 |               28580 |             94.46
 acct_PGvqKAyPyYrRI3yo | GBP      |                     8375 |                8375 |            100.00
 acct_Q84enhtKifNNwSKz | AED      |                    67235 |               65239 |             97.03
 acct_4BJsreD6hzZEVxL9 | AED      |                   111176 |              107023 |             96.26
 acct_5ZurMpVyuXwiXtOO | EUR      |                    16084 |               14071 |             87.48
 acct_PEtddZPoI2O4hePK | USD      |                     3238 |                3238 |            100.00
 acct_9opHzLpM5QTe3RMj | INR      |                   765098 |              765098 |            100.00
 acct_eLEE0rXW9YFwW5rw | USD      |                     3141 |                3141 |            100.00
 acct_CH8OlltygWeehiIY | USD      |                    55533 |               52797 |             95.07
 acct_FsjJMkhDcmNsCQko | EUR      |                    12143 |               10880 |             89.60
 acct_VAYcPHaOaRGLLsMn | INR      |                   348599 |              128275 |             36.80
 acct_dsIck9Cs1eq1UA8J | USD      |                    20301 |               12814 |             63.12
 acct_d2cQwCgPMtDIQHdH | SGD      |                     1814 |                1814 |            100.00
 acct_8HerIm922F9uIUF0 | USD      |                    37184 |               29832 |             80.23
-- More  --
