/* 
TRAFFIC SOURCE ANALYSIS:

Traffic source analysis is about understanding where your customers are coming from and 
which channels are driving the highest quality traffic. 

COMMON USE CASES:
• Analyzing search data and shifting budget towards the engines, campaigns or keywords 
driving the strongest conversion rates.
• Comparing user behavior patterns across traffic sources to inform creative and messaging strategy.
• Identifying opportunities to eliminate wasted spend or scale high-converting traffic.

PAID MARKETING CAMPAIGNS:
When businesses run paid marketing campaigns, they often obsess over performance and 
measure everything; how much they spend, how well traffic converts to sales, etc.

Paid traffic is commonly tagged with tracking (UTM) parameters, which are appended to 
URLs and allow us to tie website activity back to specific traffic sources and campaigns. 

• We use the utm parameters stored in the database to identify paid website sessions
• From our session data, we can link to our order data to understand how much revenue our paid campaigns are driving.

BUSINESS CONCEPT: BID OPTIMIZATION

Analyzing for bid optimization is about understanding the value of various 
segments of paid traffic, so that you can optimize your marketing budget.

COMMON USE CASES:
• Understanding how your website and products perform for various subsegments of traffic (i.e. mobile vs desktop)
to optimize within channels. 
• Analyzing the impact that bid changes have on your ranking in the auctions, and the volume of 
customers driven to your site.

*/ 

-- ANALYSIS/QUESTIONS Below:

/* Q1. Request Received on 12th April, 2012:
Can you help me understand where the bulk of our website sessions are coming from?
I’d like to see a breakdown by UTM source, campaign and referring domain if possible.  
*/

-- Exploring the relevant table below
select * from website_sessions;

-- SOLUTION
select
	utm_source,
    utm_campaign,
    http_referer,
    count(website_session_id) as traffic_num_of_websessions
from website_sessions
where created_at < '2012-04-12'
group by 
	utm_source,
    utm_campaign,
    http_referer
order by 
	4 desc;
    
/* Results: the utm_source 'gsearch' and utm_campaign 'nonbrand' is driving the highest traffic 
with the number of sessions being 3613 */
    
    
/* Q2. Request Received on 14th April, 2012: 
	Sounds like gsearch nonbrand is our major traffic source, but we need to understand if those sessions are driving sales.
	Could you please calculate the conversion rate (CVR) from session to order? 
    Based on what we're paying for clicks, we’ll need a CVR of at least 4% to make the numbers work. */

-- Exploring the relevant tables below:

select * from website_sessions;
select * from orders;

-- SOLUTION
select
	website_sessions.utm_source,
	website_sessions.utm_campaign,
    website_sessions.http_referer,
	count(distinct website_sessions.website_session_id) as sessions_or_traffic,
    count(distinct orders.order_id) as orders_or_num_of_purchases,
    (count(distinct orders.order_id)/count(distinct website_sessions.website_session_id))*100 as conv_rate
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2012-04-14'
	and website_sessions.utm_source = 'gsearch'
	and website_sessions.utm_campaign = 'nonbrand'
    and website_sessions.http_referer = 'https://www.gsearch.com'
    ;
    
/* Results: 
	So, the utm_source 'gsearch' and utm_campaign 'nonbrand' is generating a conversion rate of 2.875%,
    with number of sessions = 3895 and number of orders placed = 112.
    Basically, of 3895 total sessions, 112 resulted in sales. 
    
    Insights:
    We’re below the 4% conversion rate threshold we need to make the economics work. 
	Based on this analysis, we’ll need to dial down our search bids a bit. We're over-spending based on the 
	current conversion rate. */
    
    
/* Q3. Request Received on 9th May, 2012.
Based on your conversion rate analysis, we bid down gsearch nonbrand on 2012-04-15. 
Can you pull gsearch nonbrand trended session volume, by week, to see if the bid changes 
have caused volume to drop at all? */

-- SOLUTION:
select 
	min(date(created_at)) as start_of_week ,
    week(created_at) as week,
    count(website_session_id) as traffic
from website_sessions
where 
	date(created_at) <= '2012-05-09'
	and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand'
group by 
	week;

/* RESULTS:
	So, before bidding down on gsearch nonbrand paid traffic, 
    the traffic or number of sessions per week were: 896, 956, 1152, 983 sessions per week.
    After bidding down, the number of sessions per week decreased drastically to 621, 594, 681, 399 sessions/week. 
    So, it is fairly sensitive to bid changes. */
    

/* Q4. Request Received on 11th May, 2012.
I was trying to use our site on my mobile device the other day, and the experience was not great. 
Could you pull conversion rates from session to order, by device type? 
If desktop performance is better than on mobile we may be able to bid up for desktop specifically to get more volume? */

-- SOLUTION
select 
	website_sessions.device_type,
    count(website_sessions.website_session_id) as traffic_volume,
    count(orders.order_id) as orders_placed,
    (count(orders.order_id)/count(website_sessions.website_session_id))*100 as session_to_order_conv_rate
from website_sessions 
	left join orders 
		on website_sessions.website_session_id = orders.website_session_id
where 
	website_sessions.created_at < '2012-05-11'
	and website_sessions.utm_source = 'gsearch'
	and website_sessions.utm_campaign = 'nonbrand'
group by 
	website_sessions.device_type;
    
/* RESULTS:
	The conversion rate for our desktop session is 3.73% whereas, 
	the conversion rate for mobile sessions is 0.96% much lesser (1/4th roughly). 
    
	INSIGHTS: 
    Based on this, we can increase our bids on the desktop campaign. */


/* Request received on 9th June, 2012.
Q5. After your device-level analysis of conversion rates, we realized desktop was doing well, 
so we bid our gsearch nonbrand desktop campaigns up on 2012-05-19. 
Could you pull weekly trends for both desktop and mobile, so we can see the impact on volume? */

-- SOLUTION:
/* Weekly Traffic Analysis by mobile and desktop segments between 2012-04-15 and 2012-06-08.
   19th May we bid up on desktop campaign, 15th April we had bid down on gsearch nonbrand, we r doing tha analysis on 9th June */

select 
    min(date(created_at)) as start_of_week,
    count(case when device_type = 'desktop' then website_session_id else null end) as desktop_traffic,
    count(case when device_type = 'mobile' then website_session_id else null end) as mobile_traffic
from website_sessions
where 
	date(created_at) between '2012-04-15' and '2012-06-08'
    and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand'
group by 
	week(created_at);

/* RESULTS:
	The desktop traffic or sessions per week has increased after the bidding up from 403 to 661 and 585.
    Whereas, the mobile traffic has slightly gone down from 214 sessions per week to 190 and 183. */
    

/* Request received on 27th Nov, 2012 (first 8 months into the business) 
Q6. Could you dive into gsearch nonbrand, and pull monthly sessions and orders split by device type? 
I want to flex our analytical muscles a little and show the board we really know our traffic sources.  */

-- SOLUTION

select 
	year(website_sessions.created_at) as year,
    month(website_sessions.created_at) as month_of_yr,
    count(case when website_sessions.device_type = 'mobile' then website_sessions.website_session_id else null end) as mobile_traffic,
    count(case when website_sessions.device_type = 'mobile' then orders.order_id else null end) as mobile_sales,
    
    count(case when website_sessions.device_type = 'mobile' then orders.order_id else null end)/
    count(case when website_sessions.device_type = 'mobile' then website_sessions.website_session_id else null end) as mobile_conv_rt,
    
    count(case when website_sessions.device_type = 'desktop' then website_sessions.website_session_id else null end) as desktop_traffic,
    count(case when website_sessions.device_type = 'desktop' then orders.order_id else null end) as desktop_sales,
    
    count(case when website_sessions.device_type = 'desktop' then orders.order_id else null end)/
    count(case when website_sessions.device_type = 'desktop' then website_sessions.website_session_id else null end) as desktop_conv_rt
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
where 
	website_sessions.created_at < '2012-11-27'
	and website_sessions.utm_source = 'gsearch'
	and website_sessions.utm_campaign = 'nonbrand'
group by 
	1,2;
    
/* RESULTS:
Mobile Traffic OR number of sessions/month in March: 724, April: 1370, May: 1019.... Oct: 1263 and Nov: 2049
Desktop Traffic OR number of sessions/month in in Mar: 1128, Apr: 2139, May: 2276....Oct: 3934 and Nov: 6457
	We have picked up our mobile traffic steadily and consistently over 8 months 
    But, we have made appreciable progress in desktop traffic in the same time period

Sales per Month from Mobile traffic: Mar: 10, Apr: 11, May: 8..... Oct: 18, Nov: 33 (Very slow progress) 
Sales per Month from Desktop traffic: Mar: 50, Apr: 75, May: 83..... Oct: 201, Nov: 323 (Good steady progress)

Traffic to sales conversion rate of Mobile traffic: fluctuates between 0.8% - 1.61% from March to November
Traffic to sales conversion rate of Desktop traffic: steadily increased from 3.5% - 5% between March to November 
*/



