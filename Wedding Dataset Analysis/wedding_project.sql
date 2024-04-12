USE Weddings;

/* 
wedding_size estimation
The classification of wedding sizes in the dataset is based on the assumption that venues accommodating 200 guests 
or fewer offer a 'Small' setting for more intimate weddings, while a venue that holds exactly 250 guests is deemed 'Medium', 
suitable for a moderately-sized gathering. Any capacity beyond these figures falls into the 'Large' category, suitable for 
expansive celebrations. This stratification allows for a tailored approach to wedding planning, ensuring that each venue's 
offerings are matched to the event's scale. Notably, the dataset includes venues with max capacities as low as 150, reinforcing 
the range and specificity of the 'Small' category for even more intimate affairs.

budget_level classification
The direct mapping of the 'affordability' column to the 'budget_level' classification within the dataset is a logical approach
that upholds the intrinsic value assessments already established. By retaining the original affordability labels—'inexpensive',
'affordable', 'moderate', and 'luxury'—we are embracing a customer-centric perspective that recognizes and respects the preconceived
expectations and associations that clients may have with these terms. This ensures clarity and consistency in communication, both 
internally within the organization and externally with clients, 
It avoids unnecessary complexity and confusion that could arise from redefining or reinterpreting these well-understood categories, 
thereby facilitating a smoother decision-making process for clients aligning their choices with their financial preferences and 
constraints.
*/

-- Dropping the temporary table if it already exists to avoid conflicts
DROP TEMPORARY TABLE IF EXISTS relevant_vendors;

-- Creating a new temporary table to hold relevant vendor information
CREATE TEMPORARY TABLE relevant_vendors AS
SELECT 
    vendor_id,
    vendor,
    functions,
    city,
    county,
    reviews,
    avg_stars,
-- Categorizing wedding size based on venue capacity
    CASE 
    WHEN vc_capacity <= 200 THEN 'Small'
    WHEN vc_capacity = 250 THEN 'Medium'
    ELSE 'Large'
END AS wedding_size,
    -- Categorizing budget level based on affordability
    CASE
        WHEN affordability = 'inexpensive' THEN 'inexpensive'
        WHEN affordability = 'affordable' THEN 'affordable'
        WHEN affordability = 'moderate' THEN 'moderate'
        ELSE 'luxury'
    END AS budget_level
FROM
    (
		-- Selecting distinct vendor details
        SELECT DISTINCT v.vendor_id, v.vendor, d.functions, c.city,
        CASE -- classification of cities into counties
            WHEN c.city IN ('santa rosa', 'foresthill', 'sonoma') THEN 'Sonoma County'
            WHEN c.city IN ('napa', 'winters') THEN 'Napa County'
            WHEN c.city IN ('sausalito', 'san rafael', 'novato', 'marin', 'nicasio', 'fairfax') THEN 'Marin County'
            WHEN c.city IN ('alamo', 'antioch', 'brentwood', 'concord', 'danville', 'lafayette', 'martinez', 'pinole', 'pleasant hill', 'pleasanton', 'san pablo', 'san ramon', 'walnut creek') THEN 'Contra Costa County'
            WHEN c.city IN ('alameda', 'berkeley', 'castro valley', 'dublin', 'emeryville', 'fremont', 'hayward', 'livermore', 'newark', 'oakland', 'san leandro', 'sunol') THEN 'Alameda County'
            WHEN c.city IN ('burlingame', 'daly city', 'half moon bay', 'menlo park', 'milbrae', 'pacifica', 'redwood', 'san bruno', 'san carlos', 'san mateo', 'woodside') THEN 'San Mateo County'
            WHEN c.city IN ('san francisco', 'harbor village', 'lakeshore', 'telegraph hill') THEN 'San Francisco County'
            WHEN c.city IN ('campbell', 'cupertino', 'gilroy', 'los altos', 'saratoga', 'los gatos', 'milpitas', 'morgan hill', 'mountain view', 'palo alto', 'san jose', 'santa clara', 'hollister', 'sunnyvale') THEN 'Santa Clara County'
            ELSE 'Solano County'
        END AS 'county', 
        p.affordability, v.reviews, v.avg_stars, vc.capacity AS vc_capacity
        FROM vendors v
		-- Joining with cities table to get city information
        LEFT JOIN cities AS c ON v.city_id = c.city_id
		-- Joining with prices table to get affordability information
        LEFT JOIN prices AS p ON v.price_id = p.price_id
		-- Joining with departments table to get functions offered by the vendor
        LEFT JOIN departments AS d ON v.function_id = d.function_id
		-- Joining with venue_capacities table to get venue capacity information
        LEFT JOIN venue_capacities AS vc ON v.vendor_id = vc.ven_id
		-- Joining with venue_locations table to filter for venues with outdoor locations and galleries
        LEFT JOIN venue_locations AS ven_l ON v.vendor_id = ven_l.ven_id
		-- Joining with venues table for additional venue details
        LEFT JOIN venues as ve on v.vendor_id = ve.ven_id
		-- Applying conditions to filter for venues with outdoor options and galleries
        WHERE ven_l.outdoor = 1 AND ve.gallery = 1
        -- Selecting venues that have outdoor facilities or gallery to accommodate an open-air setting as depicted in the vision board.

        UNION

/* Query for cakes */
SELECT DISTINCT v.vendor_id, v.vendor, d.functions, c.city,CASE
		WHEN c.city IN ('santa rosa', 'foresthill','sonoma') THEN 'Sonoma County'
        WHEN c.city IN ('napa','winters') THEN 'Napa County'
        WHEN c.city IN ('sausalito', 'san rafael', 'novato', 'marin', 'nicasio','fairfax') THEN 'Marin County'
        WHEN c.city IN ('alamo', 'antioch', 'brentwood', 'concord', 'danville', 'lafayette', 'martinez', 
						'pinole', 'pleasant hill', 'pleasanton', 'san pablo', 'san ramon', 'walnut creek') THEN 'Contra Costa County'
        WHEN c.city IN ('alameda', 'berkeley', 'castro valley', 'dublin', 'emeryville', 'fremont', 'hayward', 'livermore', 
						'newark', 'oakland', 'san leandro' ,'sunol') THEN 'Alameda County'
		WHEN c.city IN ('burlingame', 'daly city', 'half moon bay', 'menlo park', 'milbrae', 'pacifica', 'redwood', 
						'san bruno', 'san carlos', 'san mateo', 'woodside') THEN 'San Mateo County'
		WHEN c.city IN ('san francisco', 'harbor village', 'lakeshore', 'telegraph hill') THEN 'San Francisco County'
        WHEN c.city IN ('campbell', 'cupertino', 'gilroy', 'los altos', 'saratoga','los gatos', 'milpitas', 'morgan hill', 'mountain view',
						'palo alto', 'san jose', 'santa clara', 'hollister', 'sunnyvale') THEN 'Santa Clara County'
		ELSE 'Solano County'
	END AS 'county',  p.affordability, v.reviews, v.avg_stars, vc.capacity AS vc_capacity
FROM vendors v
LEFT JOIN cities AS c ON v.city_id = c.city_id
LEFT JOIN prices AS p ON v.price_id = p.price_id
LEFT JOIN departments AS d ON v.function_id = d.function_id
LEFT JOIN venue_capacities AS vc ON v.vendor_id = vc.ven_id
LEFT JOIN cakes AS cake ON v.vendor_id = cake.cak_id
WHERE (cake.vanilla = 1 OR cake.white = 1 )
-- Filtering for cakes that are either vanilla flavored or white in color

UNION

/* Query for rental services - decor, linen, shade, table and chair, tableware, tent */
SELECT DISTINCT v.vendor_id, v.vendor, d.functions, c.city,CASE
		WHEN c.city IN ('santa rosa', 'foresthill','sonoma') THEN 'Sonoma County'
        WHEN c.city IN ('napa','winters') THEN 'Napa County'
        WHEN c.city IN ('sausalito', 'san rafael', 'novato', 'marin', 'nicasio','fairfax') THEN 'Marin County'
        WHEN c.city IN ('alamo', 'antioch', 'brentwood', 'concord', 'danville', 'lafayette', 'martinez', 
						'pinole', 'pleasant hill', 'pleasanton', 'san pablo', 'san ramon', 'walnut creek') THEN 'Contra Costa County'
        WHEN c.city IN ('alameda', 'berkeley', 'castro valley', 'dublin', 'emeryville', 'fremont', 'hayward', 'livermore', 
						'newark', 'oakland', 'san leandro' ,'sunol') THEN 'Alameda County'
		WHEN c.city IN ('burlingame', 'daly city', 'half moon bay', 'menlo park', 'milbrae', 'pacifica', 'redwood', 
						'san bruno', 'san carlos', 'san mateo', 'woodside') THEN 'San Mateo County'
		WHEN c.city IN ('san francisco', 'harbor village', 'lakeshore', 'telegraph hill') THEN 'San Francisco County'
        WHEN c.city IN ('campbell', 'cupertino', 'gilroy', 'los altos', 'saratoga','los gatos', 'milpitas', 'morgan hill', 'mountain view',
						'palo alto', 'san jose', 'santa clara', 'hollister', 'sunnyvale') THEN 'Santa Clara County'
		ELSE 'Solano County'
	END AS 'county',  p.affordability, v.reviews, v.avg_stars, vc.capacity AS vc_capacity
FROM vendors v
LEFT JOIN cities AS c ON v.city_id = c.city_id
LEFT JOIN prices AS p ON v.price_id = p.price_id
LEFT JOIN departments AS d ON v.function_id = d.function_id
LEFT JOIN venue_capacities AS vc ON v.vendor_id = vc.ven_id
LEFT JOIN rental_services AS rent ON v.vendor_id = rent.ren_id
WHERE (rent.decor = 1 AND rent.linen = 1 AND rent.shade = 1 AND rent.table_chair = 1 AND rent.tableware = 1 AND rent.tent = 1)
-- Ensuring the rental includes all necessary decor elements such as linens, shade, tables, chairs, tableware, and tents, 
-- catering to a fully-equipped outdoor wedding experience.

UNION

/* Query for catering services - buffet and counties which have the venues selected*/
SELECT DISTINCT v.vendor_id, v.vendor, d.functions, c.city,CASE
		WHEN c.city IN ('santa rosa', 'foresthill','sonoma') THEN 'Sonoma County'
        WHEN c.city IN ('napa','winters') THEN 'Napa County'
        WHEN c.city IN ('sausalito', 'san rafael', 'novato', 'marin', 'nicasio','fairfax') THEN 'Marin County'
        WHEN c.city IN ('alamo', 'antioch', 'brentwood', 'concord', 'danville', 'lafayette', 'martinez', 
						'pinole', 'pleasant hill', 'pleasanton', 'san pablo', 'san ramon', 'walnut creek') THEN 'Contra Costa County'
        WHEN c.city IN ('alameda', 'berkeley', 'castro valley', 'dublin', 'emeryville', 'fremont', 'hayward', 'livermore', 
						'newark', 'oakland', 'san leandro' ,'sunol') THEN 'Alameda County'
		WHEN c.city IN ('burlingame', 'daly city', 'half moon bay', 'menlo park', 'milbrae', 'pacifica', 'redwood', 
						'san bruno', 'san carlos', 'san mateo', 'woodside') THEN 'San Mateo County'
		WHEN c.city IN ('san francisco', 'harbor village', 'lakeshore', 'telegraph hill') THEN 'San Francisco County'
        WHEN c.city IN ('campbell', 'cupertino', 'gilroy', 'los altos', 'saratoga','los gatos', 'milpitas', 'morgan hill', 'mountain view',
						'palo alto', 'san jose', 'santa clara', 'hollister', 'sunnyvale') THEN 'Santa Clara County'
		ELSE 'Solano County'
	END AS 'county',  p.affordability, v.reviews, v.avg_stars, vc.capacity AS vc_capacity
FROM vendors v
LEFT JOIN cities AS c ON v.city_id = c.city_id
LEFT JOIN prices AS p ON v.price_id = p.price_id
LEFT JOIN departments AS d ON v.function_id = d.function_id
 LEFT JOIN venue_capacities AS vc ON v.vendor_id = vc.ven_id
LEFT JOIN catering_services AS catering ON v.vendor_id = catering.cat_id
WHERE catering.buffet = 1 
		AND city IN ('san francisco', 'harbor village', 'lakeshore', 'telegraph hill','alamo', 'antioch', 'brentwood', 'concord', 'danville', 'lafayette', 'martinez', 
						'pinole', 'pleasant hill', 'pleasanton', 'san pablo', 'san ramon', 'walnut creek')
-- Selecting only those catering services that offer a buffet setup, aligning with the vision of an elegant and self-serve
-- dining experience for the wedding.
-- cities in San Francisco and Contra Costa County are chosen because our final wedding venues fall under them and we would like to 
-- get fresh food delivered on the day of the wedding.

UNION

/* Query for hair services */
SELECT DISTINCT v.vendor_id, v.vendor, d.functions, c.city,CASE
		WHEN c.city IN ('santa rosa', 'foresthill','sonoma') THEN 'Sonoma County'
        WHEN c.city IN ('napa','winters') THEN 'Napa County'
        WHEN c.city IN ('sausalito', 'san rafael', 'novato', 'marin', 'nicasio','fairfax') THEN 'Marin County'
        WHEN c.city IN ('alamo', 'antioch', 'brentwood', 'concord', 'danville', 'lafayette', 'martinez', 
						'pinole', 'pleasant hill', 'pleasanton', 'san pablo', 'san ramon', 'walnut creek') THEN 'Contra Costa County'
        WHEN c.city IN ('alameda', 'berkeley', 'castro valley', 'dublin', 'emeryville', 'fremont', 'hayward', 'livermore', 
						'newark', 'oakland', 'san leandro' ,'sunol') THEN 'Alameda County'
		WHEN c.city IN ('burlingame', 'daly city', 'half moon bay', 'menlo park', 'milbrae', 'pacifica', 'redwood', 
						'san bruno', 'san carlos', 'san mateo', 'woodside') THEN 'San Mateo County'
		WHEN c.city IN ('san francisco', 'harbor village', 'lakeshore', 'telegraph hill') THEN 'San Francisco County'
        WHEN c.city IN ('campbell', 'cupertino', 'gilroy', 'los altos', 'saratoga','los gatos', 'milpitas', 'morgan hill', 'mountain view',
						'palo alto', 'san jose', 'santa clara', 'hollister', 'sunnyvale') THEN 'Santa Clara County'
		ELSE 'Solano County'
	END AS 'county',  p.affordability, v.reviews, v.avg_stars, vc.capacity AS vc_capacity
FROM vendors v
LEFT JOIN cities AS c ON v.city_id = c.city_id
LEFT JOIN prices AS p ON v.price_id = p.price_id
LEFT JOIN departments AS d ON v.function_id = d.function_id
 LEFT JOIN venue_capacities AS vc ON v.vendor_id = vc.ven_id
LEFT JOIN hair_services AS hair ON v.vendor_id = hair.hai_id
WHERE (hair.hair = 1 AND hair.makeup = 1 )
-- Filtering for beauty services that provide comprehensive bridal care with both hair styling and makeup application, 
-- ensuring a cohesive and polished look for the wedding day.

UNION 

SELECT DISTINCT v.vendor_id, v.vendor, d.functions, c.city,CASE
		WHEN c.city IN ('santa rosa', 'foresthill','sonoma') THEN 'Sonoma County'
        WHEN c.city IN ('napa','winters') THEN 'Napa County'
        WHEN c.city IN ('sausalito', 'san rafael', 'novato', 'marin', 'nicasio','fairfax') THEN 'Marin County'
        WHEN c.city IN ('alamo', 'antioch', 'brentwood', 'concord', 'danville', 'lafayette', 'martinez', 
						'pinole', 'pleasant hill', 'pleasanton', 'san pablo', 'san ramon', 'walnut creek') THEN 'Contra Costa County'
        WHEN c.city IN ('alameda', 'berkeley', 'castro valley', 'dublin', 'emeryville', 'fremont', 'hayward', 'livermore', 
						'newark', 'oakland', 'san leandro' ,'sunol') THEN 'Alameda County'
		WHEN c.city IN ('burlingame', 'daly city', 'half moon bay', 'menlo park', 'milbrae', 'pacifica', 'redwood', 
						'san bruno', 'san carlos', 'san mateo', 'woodside') THEN 'San Mateo County'
		WHEN c.city IN ('san francisco', 'harbor village', 'lakeshore', 'telegraph hill') THEN 'San Francisco County'
        WHEN c.city IN ('campbell', 'cupertino', 'gilroy', 'los altos', 'saratoga','los gatos', 'milpitas', 'morgan hill', 'mountain view',
						'palo alto', 'san jose', 'santa clara', 'hollister', 'sunnyvale') THEN 'Santa Clara County'
		ELSE 'Solano County'
	END AS 'county',  p.affordability, v.reviews, v.avg_stars, vc.capacity AS vc_capacity
FROM vendors v
LEFT JOIN cities AS c ON v.city_id = c.city_id
LEFT JOIN prices AS p ON v.price_id = p.price_id
LEFT JOIN departments AS d ON v.function_id = d.function_id
LEFT JOIN venue_capacities AS vc ON v.vendor_id = vc.ven_id
LEFT JOIN invitations AS invitations ON v.vendor_id = invitations.inv_id
WHERE (invitations.min_quantity >= 20)
-- Selecting invitations with a minimum quantity greater than or equal to 20 aligns with the prevalent trend in our dataset,
-- ensuring that we cater to the most common request size 

UNION 

SELECT DISTINCT v.vendor_id, v.vendor, d.functions, c.city,CASE
		WHEN c.city IN ('santa rosa', 'foresthill','sonoma') THEN 'Sonoma County'
        WHEN c.city IN ('napa','winters') THEN 'Napa County'
        WHEN c.city IN ('sausalito', 'san rafael', 'novato', 'marin', 'nicasio','fairfax') THEN 'Marin County'
        WHEN c.city IN ('alamo', 'antioch', 'brentwood', 'concord', 'danville', 'lafayette', 'martinez', 
						'pinole', 'pleasant hill', 'pleasanton', 'san pablo', 'san ramon', 'walnut creek') THEN 'Contra Costa County'
        WHEN c.city IN ('alameda', 'berkeley', 'castro valley', 'dublin', 'emeryville', 'fremont', 'hayward', 'livermore', 
						'newark', 'oakland', 'san leandro' ,'sunol') THEN 'Alameda County'
		WHEN c.city IN ('burlingame', 'daly city', 'half moon bay', 'menlo park', 'milbrae', 'pacifica', 'redwood', 
						'san bruno', 'san carlos', 'san mateo', 'woodside') THEN 'San Mateo County'
		WHEN c.city IN ('san francisco', 'harbor village', 'lakeshore', 'telegraph hill') THEN 'San Francisco County'
        WHEN c.city IN ('campbell', 'cupertino', 'gilroy', 'los altos', 'saratoga','los gatos', 'milpitas', 'morgan hill', 'mountain view',
						'palo alto', 'san jose', 'santa clara', 'hollister', 'sunnyvale') THEN 'Santa Clara County'
		ELSE 'Solano County'
	END AS 'county',  p.affordability, v.reviews, v.avg_stars, vc.capacity AS vc_capacity
FROM vendors v
LEFT JOIN cities AS c ON v.city_id = c.city_id
LEFT JOIN prices AS p ON v.price_id = p.price_id
LEFT JOIN departments AS d ON v.function_id = d.function_id
LEFT JOIN venue_capacities AS vc ON v.vendor_id = vc.ven_id
LEFT JOIN music_match AS music ON v.vendor_id = music.mus_id
WHERE (music.type_id = 1)
-- Selecting only wedding bands for the music entertainment option as per the classic and elegant theme of the vision board, 
-- ensuring a traditional and sophisticated ambiance.

UNION 

SELECT DISTINCT v.vendor_id, v.vendor, d.functions, c.city,CASE
		WHEN c.city IN ('santa rosa', 'foresthill','sonoma') THEN 'Sonoma County'
        WHEN c.city IN ('napa','winters') THEN 'Napa County'
        WHEN c.city IN ('sausalito', 'san rafael', 'novato', 'marin', 'nicasio','fairfax') THEN 'Marin County'
        WHEN c.city IN ('alamo', 'antioch', 'brentwood', 'concord', 'danville', 'lafayette', 'martinez', 
						'pinole', 'pleasant hill', 'pleasanton', 'san pablo', 'san ramon', 'walnut creek') THEN 'Contra Costa County'
        WHEN c.city IN ('alameda', 'berkeley', 'castro valley', 'dublin', 'emeryville', 'fremont', 'hayward', 'livermore', 
						'newark', 'oakland', 'san leandro' ,'sunol') THEN 'Alameda County'
		WHEN c.city IN ('burlingame', 'daly city', 'half moon bay', 'menlo park', 'milbrae', 'pacifica', 'redwood', 
						'san bruno', 'san carlos', 'san mateo', 'woodside') THEN 'San Mateo County'
		WHEN c.city IN ('san francisco', 'harbor village', 'lakeshore', 'telegraph hill') THEN 'San Francisco County'
        WHEN c.city IN ('campbell', 'cupertino', 'gilroy', 'los altos', 'saratoga','los gatos', 'milpitas', 'morgan hill', 'mountain view',
						'palo alto', 'san jose', 'santa clara', 'hollister', 'sunnyvale') THEN 'Santa Clara County'
		ELSE 'Solano County'
	END AS 'county',  p.affordability, v.reviews, v.avg_stars, vc.capacity AS vc_capacity
FROM vendors v
LEFT JOIN cities AS c ON v.city_id = c.city_id
LEFT JOIN prices AS p ON v.price_id = p.price_id
LEFT JOIN departments AS d ON v.function_id = d.function_id
LEFT JOIN venue_capacities AS vc ON v.vendor_id = vc.ven_id
LEFT JOIN photo_prices AS photo ON v.vendor_id = photo.pho_id
WHERE (photo.is_photographer = 1)
-- Filtering for service providers who offer photography services to ensure the capture of high-quality, professional wedding photos,
-- as emphasized by the vision board.

UNION 

SELECT DISTINCT v.vendor_id, v.vendor, d.functions, c.city,CASE
		WHEN c.city IN ('santa rosa', 'foresthill','sonoma') THEN 'Sonoma County'
        WHEN c.city IN ('napa','winters') THEN 'Napa County'
        WHEN c.city IN ('sausalito', 'san rafael', 'novato', 'marin', 'nicasio','fairfax') THEN 'Marin County'
        WHEN c.city IN ('alamo', 'antioch', 'brentwood', 'concord', 'danville', 'lafayette', 'martinez', 
						'pinole', 'pleasant hill', 'pleasanton', 'san pablo', 'san ramon', 'walnut creek') THEN 'Contra Costa County'
        WHEN c.city IN ('alameda', 'berkeley', 'castro valley', 'dublin', 'emeryville', 'fremont', 'hayward', 'livermore', 
						'newark', 'oakland', 'san leandro' ,'sunol') THEN 'Alameda County'
		WHEN c.city IN ('burlingame', 'daly city', 'half moon bay', 'menlo park', 'milbrae', 'pacifica', 'redwood', 
						'san bruno', 'san carlos', 'san mateo', 'woodside') THEN 'San Mateo County'
		WHEN c.city IN ('san francisco', 'harbor village', 'lakeshore', 'telegraph hill') THEN 'San Francisco County'
        WHEN c.city IN ('campbell', 'cupertino', 'gilroy', 'los altos', 'saratoga','los gatos', 'milpitas', 'morgan hill', 'mountain view',
						'palo alto', 'san jose', 'santa clara', 'hollister', 'sunnyvale') THEN 'Santa Clara County'
		ELSE 'Solano County'
	END AS 'county',  p.affordability, v.reviews, v.avg_stars, vc.capacity AS vc_capacity
FROM vendors v
LEFT JOIN cities AS c ON v.city_id = c.city_id
LEFT JOIN prices AS p ON v.price_id = p.price_id
LEFT JOIN departments AS d ON v.function_id = d.function_id
LEFT JOIN venue_capacities AS vc ON v.vendor_id = vc.ven_id
LEFT JOIN planner_prices AS planner ON v.vendor_id = planner.wed_id
WHERE (planner.`partial` > 2000)
AND city IN ('san francisco', 'harbor village', 'lakeshore', 'telegraph hill','alamo', 'antioch', 'brentwood', 'concord', 'danville', 'lafayette', 'martinez', 
						'pinole', 'pleasant hill', 'pleasanton', 'san pablo', 'san ramon', 'walnut creek')
-- Filtering for planners with partial service fees above $2,000 ensuring a balance between affordability and professional expertise.
-- Since we are choosing each vendor ourselves, we ignored full wedding planner price.  
-- Also, we are choosing planners in close proximity to the venue. 

UNION

/* Query for dress and attire */
SELECT DISTINCT v.vendor_id, v.vendor, d.functions, c.city,CASE
		WHEN c.city IN ('santa rosa', 'foresthill','sonoma') THEN 'Sonoma County'
        WHEN c.city IN ('napa','winters') THEN 'Napa County'
        WHEN c.city IN ('sausalito', 'san rafael', 'novato', 'marin', 'nicasio','fairfax') THEN 'Marin County'
        WHEN c.city IN ('alamo', 'antioch', 'brentwood', 'concord', 'danville', 'lafayette', 'martinez', 
						'pinole', 'pleasant hill', 'pleasanton', 'san pablo', 'san ramon', 'walnut creek') THEN 'Contra Costa County'
        WHEN c.city IN ('alameda', 'berkeley', 'castro valley', 'dublin', 'emeryville', 'fremont', 'hayward', 'livermore', 
						'newark', 'oakland', 'san leandro' ,'sunol') THEN 'Alameda County'
		WHEN c.city IN ('burlingame', 'daly city', 'half moon bay', 'menlo park', 'milbrae', 'pacifica', 'redwood', 
						'san bruno', 'san carlos', 'san mateo', 'woodside') THEN 'San Mateo County'
		WHEN c.city IN ('san francisco', 'harbor village', 'lakeshore', 'telegraph hill') THEN 'San Francisco County'
        WHEN c.city IN ('campbell', 'cupertino', 'gilroy', 'los altos', 'saratoga','los gatos', 'milpitas', 'morgan hill', 'mountain view',
						'palo alto', 'san jose', 'santa clara', 'hollister', 'sunnyvale') THEN 'Santa Clara County'
		ELSE 'Solano County'
	END AS 'county',  p.affordability, v.reviews, v.avg_stars, vc.capacity AS vc_capacity
FROM vendors v
LEFT JOIN cities AS c ON v.city_id = c.city_id
LEFT JOIN prices AS p ON v.price_id = p.price_id
LEFT JOIN venue_capacities AS vc ON v.vendor_id = vc.ven_id
LEFT JOIN departments AS d ON v.function_id = d.function_id
WHERE d.functions = 'dress atire'
-- dress and attire can be from any city as the bride/groom likes. No filtering criteria has been applied here. 
-- They have been given the freedom to choose their wedding dress from any city in the Bay Area

UNION

/* Query for flowers */
SELECT DISTINCT v.vendor_id, v.vendor, d.functions, c.city,CASE
		WHEN c.city IN ('santa rosa', 'foresthill','sonoma') THEN 'Sonoma County'
        WHEN c.city IN ('napa','winters') THEN 'Napa County'
        WHEN c.city IN ('sausalito', 'san rafael', 'novato', 'marin', 'nicasio','fairfax') THEN 'Marin County'
        WHEN c.city IN ('alamo', 'antioch', 'brentwood', 'concord', 'danville', 'lafayette', 'martinez', 
						'pinole', 'pleasant hill', 'pleasanton', 'san pablo', 'san ramon', 'walnut creek') THEN 'Contra Costa County'
        WHEN c.city IN ('alameda', 'berkeley', 'castro valley', 'dublin', 'emeryville', 'fremont', 'hayward', 'livermore', 
						'newark', 'oakland', 'san leandro' ,'sunol') THEN 'Alameda County'
		WHEN c.city IN ('burlingame', 'daly city', 'half moon bay', 'menlo park', 'milbrae', 'pacifica', 'redwood', 
						'san bruno', 'san carlos', 'san mateo', 'woodside') THEN 'San Mateo County'
		WHEN c.city IN ('san francisco', 'harbor village', 'lakeshore', 'telegraph hill') THEN 'San Francisco County'
        WHEN c.city IN ('campbell', 'cupertino', 'gilroy', 'los altos', 'saratoga','los gatos', 'milpitas', 'morgan hill', 'mountain view',
						'palo alto', 'san jose', 'santa clara', 'hollister', 'sunnyvale') THEN 'Santa Clara County'
		ELSE 'Solano County'
	END AS 'county',  p.affordability, v.reviews, v.avg_stars, vc.capacity AS vc_capacity
FROM vendors v
LEFT JOIN cities AS c ON v.city_id = c.city_id
LEFT JOIN prices AS p ON v.price_id = p.price_id
LEFT JOIN venue_capacities AS vc ON v.vendor_id = vc.ven_id
LEFT JOIN departments AS d ON v.function_id = d.function_id
WHERE d.functions = 'flowers'
AND city IN ('san francisco', 'harbor village', 'lakeshore', 'telegraph hill','alamo', 'antioch', 'brentwood', 'concord', 'danville', 'lafayette', 'martinez', 
						'pinole', 'pleasant hill', 'pleasanton', 'san pablo', 'san ramon', 'walnut creek')
-- flowers have been filtered and can be chosen from the cities in San Francisco and Contra Costa County as our final wedding venues 
-- fall in the cities which belong to these counties and we would like to get fresh flowers on the day of the wedding

UNION 

/* Query for jewelry */
SELECT DISTINCT v.vendor_id, v.vendor, d.functions, c.city,CASE
		WHEN c.city IN ('santa rosa', 'foresthill','sonoma') THEN 'Sonoma County'
        WHEN c.city IN ('napa','winters') THEN 'Napa County'
        WHEN c.city IN ('sausalito', 'san rafael', 'novato', 'marin', 'nicasio','fairfax') THEN 'Marin County'
        WHEN c.city IN ('alamo', 'antioch', 'brentwood', 'concord', 'danville', 'lafayette', 'martinez', 
						'pinole', 'pleasant hill', 'pleasanton', 'san pablo', 'san ramon', 'walnut creek') THEN 'Contra Costa County'
        WHEN c.city IN ('alameda', 'berkeley', 'castro valley', 'dublin', 'emeryville', 'fremont', 'hayward', 'livermore', 
						'newark', 'oakland', 'san leandro' ,'sunol') THEN 'Alameda County'
		WHEN c.city IN ('burlingame', 'daly city', 'half moon bay', 'menlo park', 'milbrae', 'pacifica', 'redwood', 
						'san bruno', 'san carlos', 'san mateo', 'woodside') THEN 'San Mateo County'
		WHEN c.city IN ('san francisco', 'harbor village', 'lakeshore', 'telegraph hill') THEN 'San Francisco County'
        WHEN c.city IN ('campbell', 'cupertino', 'gilroy', 'los altos', 'saratoga','los gatos', 'milpitas', 'morgan hill', 'mountain view',
						'palo alto', 'san jose', 'santa clara', 'hollister', 'sunnyvale') THEN 'Santa Clara County'
		ELSE 'Solano County'
	END AS 'county',  p.affordability, v.reviews, v.avg_stars, vc.capacity AS vc_capacity
FROM vendors v
LEFT JOIN cities AS c ON v.city_id = c.city_id
LEFT JOIN prices AS p ON v.price_id = p.price_id
LEFT JOIN venue_capacities AS vc ON v.vendor_id = vc.ven_id
LEFT JOIN departments AS d ON v.function_id = d.function_id
WHERE d.functions = 'jewelry'
-- jewelry can come from any place. So, no filtering condition has been applied
    ) AS combined_results;

SELECT * FROM relevant_vendors;

-- Assumptions:
-- To select vendors for our Nautical Themed wedding, we first chose the ideal venues, Fort Mason Centre for Arts and Culture 
-- and Bridges Golf Course, located in San Francisco County (San Francisco) and San Ramon (Contra Costa County), respectively. 
-- higher average star ratings, especially when options were tied in categories such as large and affordable, or large and luxury. 
-- Initial filtering of vendors was done at the city level (San Francisco, San Ramon), followed by the county level. 
-- Finally, we assessed potential vendors by reviewing their websites for estimated costs, completing our selection process.

-- Drop the vendor_options table if it already exists
DROP TEMPORARY TABLE IF EXISTS vendor_options;

-- Create the vendor_options table to hold budget levels, wedding sizes, and estimated costs
CREATE TEMPORARY TABLE vendor_options (
	 Wedding_Theme VARCHAR(255), -- Stores the theme of the wedding
    Budget_level VARCHAR(255), -- Indicates the budget level (e.g., Inexpensive, Affordable)
    Size VARCHAR(255), -- Size of the wedding (e.g., Small, Medium, Large)
    Flowers_vendor_name VARCHAR(255), -- Name of the florist vendor
    Venue_vendor_name VARCHAR(255), -- Name of the venue vendor
    Music_vendor_name VARCHAR(255), -- Name of the music vendor
    Jewelry_vendor_name VARCHAR(255), -- Name of the jewelry vendor
    Photo_and_Video_vendor_name VARCHAR(255), -- Name of the photography and videography vendor
    Hair_and_Makeup_vendor_name VARCHAR(255), -- Name of the hair and makeup vendor
    Brides_Dress VARCHAR(255), -- Store or designer of the bride's dress
    Grooms_Attire VARCHAR(255), -- Store or designer of the groom's attire
    Catering_vendor_name VARCHAR(255), -- Name of the catering vendor
    Rentals_vendor_name VARCHAR(255), -- Name of the rentals vendor
    Invitations_vendor_name VARCHAR(255), -- Name of the invitations vendor
    Cake_vendor_name VARCHAR(255), -- Name of the cake vendor
    Wedding_Planning_vendor_name VARCHAR(255), -- Name of the wedding planning vendor
    Total_est_cost INT -- Estimated total cost of the wedding
);

-- Inserting data into the 'vendor_options' table. Each row represents a different combination of vendors and costs for a Nautical themed wedding
-- The following statements create multiple scenarios with various sizes, budget levels, and vendor combinations
INSERT INTO vendor_options (Wedding_Theme, Budget_level, Size, Flowers_vendor_name, Venue_vendor_name, Music_vendor_name, Jewelry_vendor_name, Photo_and_Video_vendor_name, Hair_and_Makeup_vendor_name, Brides_Dress, Grooms_Attire, Catering_vendor_name, Rentals_vendor_name, Invitations_vendor_name, Cake_vendor_name, Wedding_Planning_vendor_name, Total_est_cost) VALUES ('Nautical', 'Inexpensive', 'Small', 'fresh petals', 'fort mason centre for arts and culture', 'the klipptones', 'the love of ganesha', 'george street photo and video', 'beauty by pace', 'tina bridal and creations', 'men warehouse', 'slider shack', 'fine line creation', 'pro digital photos', 'mitraartcake', 'swc consultants', 12520);
INSERT INTO vendor_options (Wedding_Theme, Budget_level, Size, Flowers_vendor_name, Venue_vendor_name, Music_vendor_name, Jewelry_vendor_name, Photo_and_Video_vendor_name, Hair_and_Makeup_vendor_name, Brides_Dress, Grooms_Attire, Catering_vendor_name, Rentals_vendor_name, Invitations_vendor_name, Cake_vendor_name, Wedding_Planning_vendor_name, Total_est_cost) VALUES ('Nautical', 'Inexpensive', 'Medium', 'fresh petals', 'fort mason centre for arts and culture', 'the klipptones', 'the love of ganesha', 'george street photo and video', 'beauty by pace', 'tina bridal and creations', 'men warehouse', 'slider shack', 'fine line creation', 'pro digital photos', 'mitraartcake', 'swc consultants', 21637);
INSERT INTO vendor_options (Wedding_Theme, Budget_level, Size, Flowers_vendor_name, Venue_vendor_name, Music_vendor_name, Jewelry_vendor_name, Photo_and_Video_vendor_name, Hair_and_Makeup_vendor_name, Brides_Dress, Grooms_Attire, Catering_vendor_name, Rentals_vendor_name, Invitations_vendor_name, Cake_vendor_name, Wedding_Planning_vendor_name, Total_est_cost) VALUES ('Nautical', 'Inexpensive', 'Large', 'fresh petals', 'fort mason centre for arts and culture', 'the klipptones', 'the love of ganesha', 'george street photo and video', 'beauty by pace', 'tina bridal and creations', 'men warehouse', 'slider shack', 'fine line creation', 'pro digital photos', 'mitraartcake', 'swc consultants', 34080);
INSERT INTO vendor_options (Wedding_Theme, Budget_level, Size, Flowers_vendor_name, Venue_vendor_name, Music_vendor_name, Jewelry_vendor_name, Photo_and_Video_vendor_name, Hair_and_Makeup_vendor_name, Brides_Dress, Grooms_Attire, Catering_vendor_name, Rentals_vendor_name, Invitations_vendor_name, Cake_vendor_name, Wedding_Planning_vendor_name, Total_est_cost) VALUES ('Nautical', 'Affordable', 'Small', 'petals and decor', 'fort mason centre for arts and culture', 'the klipptones', 'yadav diamonds and jewelry', 'of his fold photography', 'glamour by kary li', 'glamour closet', 'men warehouse', 'trattoria da vittorio', 'chairs for affairs', 'fedex office print and ship center', 'mitraartcake', 'hitch perfect', 22390);
INSERT INTO vendor_options (Wedding_Theme, Budget_level, Size, Flowers_vendor_name, Venue_vendor_name, Music_vendor_name, Jewelry_vendor_name, Photo_and_Video_vendor_name, Hair_and_Makeup_vendor_name, Brides_Dress, Grooms_Attire, Catering_vendor_name, Rentals_vendor_name, Invitations_vendor_name, Cake_vendor_name, Wedding_Planning_vendor_name, Total_est_cost) VALUES ('Nautical', 'Affordable', 'Medium', 'petals and decor', 'fort mason centre for arts and culture', 'the klipptones', 'yadav diamonds and jewelry', 'of his fold photography', 'glamour by kary li', 'glamour closet', 'men warehouse', 'trattoria da vittorio', 'chairs for affairs', 'fedex office print and ship center', 'mitraartcake', 'hitch perfect', 36225);
INSERT INTO vendor_options (Wedding_Theme, Budget_level, Size, Flowers_vendor_name, Venue_vendor_name, Music_vendor_name, Jewelry_vendor_name, Photo_and_Video_vendor_name, Hair_and_Makeup_vendor_name, Brides_Dress, Grooms_Attire, Catering_vendor_name, Rentals_vendor_name, Invitations_vendor_name, Cake_vendor_name, Wedding_Planning_vendor_name, Total_est_cost) VALUES ('Nautical', 'Affordable', 'Large', 'petals and decor', 'fort mason centre for arts and culture', 'the klipptones', 'yadav diamonds and jewelry', 'of his fold photography', 'glamour by kary li', 'glamour closet', 'men warehouse', 'trattoria da vittorio', 'chairs for affairs', 'fedex office print and ship center', 'mitraartcake', 'hitch perfect', 54295);
INSERT INTO vendor_options (Wedding_Theme, Budget_level, Size, Flowers_vendor_name, Venue_vendor_name, Music_vendor_name, Jewelry_vendor_name, Photo_and_Video_vendor_name, Hair_and_Makeup_vendor_name, Brides_Dress, Grooms_Attire, Catering_vendor_name, Rentals_vendor_name, Invitations_vendor_name, Cake_vendor_name, Wedding_Planning_vendor_name, Total_est_cost) VALUES ('Nautical', 'Moderate', 'Small', 'petals and decor', 'the bridges golf club', 'radio gatsby', 'jin wang', 'anne-claire brun', 'the glam bar', 'nouvelle vogue', 'franco masoma bespoke', 'wylder space inc', 'bright event rentals', 'catprint', 'le gateau elegang', 'nicole taylor events', 34875);
INSERT INTO vendor_options (Wedding_Theme, Budget_level, Size, Flowers_vendor_name, Venue_vendor_name, Music_vendor_name, Jewelry_vendor_name, Photo_and_Video_vendor_name, Hair_and_Makeup_vendor_name, Brides_Dress, Grooms_Attire, Catering_vendor_name, Rentals_vendor_name, Invitations_vendor_name, Cake_vendor_name, Wedding_Planning_vendor_name, Total_est_cost) VALUES ('Nautical', 'Moderate', 'Medium', 'petals and decor', 'the bridges golf club', 'radio gatsby', 'jin wang', 'anne-claire brun', 'the glam bar', 'nouvelle vogue', 'franco masoma bespoke', 'wylder space inc', 'bright event rentals', 'catprint', 'le gateau elegang', 'nicole taylor events', 57350);
INSERT INTO vendor_options (Wedding_Theme, Budget_level, Size, Flowers_vendor_name, Venue_vendor_name, Music_vendor_name, Jewelry_vendor_name, Photo_and_Video_vendor_name, Hair_and_Makeup_vendor_name, Brides_Dress, Grooms_Attire, Catering_vendor_name, Rentals_vendor_name, Invitations_vendor_name, Cake_vendor_name, Wedding_Planning_vendor_name, Total_est_cost) VALUES ('Nautical', 'Moderate', 'Large', 'petals and decor', 'the bridges golf club', 'radio gatsby', 'jin wang', 'anne-claire brun', 'the glam bar', 'nouvelle vogue', 'franco masoma bespoke', 'wylder space inc', 'bright event rentals', 'catprint', 'le gateau elegang', 'nicole taylor events', 82950);
INSERT INTO vendor_options (Wedding_Theme, Budget_level, Size, Flowers_vendor_name, Venue_vendor_name, Music_vendor_name, Jewelry_vendor_name, Photo_and_Video_vendor_name, Hair_and_Makeup_vendor_name, Brides_Dress, Grooms_Attire, Catering_vendor_name, Rentals_vendor_name, Invitations_vendor_name, Cake_vendor_name, Wedding_Planning_vendor_name, Total_est_cost) VALUES ('Nautical', 'Luxury', 'Small', 'petals and decor', 'the bridges golf club', 'radio gatsby', 'tiffany and co', 'alice che photography', 'chritina choi cosmetics', 'marina morrison', 'franco masoma bespoke', 'miller and lux', 'bright event rentals', 'reb peters press', 'le gateau elegang', 'mandy scott', 53765);
INSERT INTO vendor_options (Wedding_Theme, Budget_level, Size, Flowers_vendor_name, Venue_vendor_name, Music_vendor_name, Jewelry_vendor_name, Photo_and_Video_vendor_name, Hair_and_Makeup_vendor_name, Brides_Dress, Grooms_Attire, Catering_vendor_name, Rentals_vendor_name, Invitations_vendor_name, Cake_vendor_name, Wedding_Planning_vendor_name, Total_est_cost) VALUES ('Nautical', 'Luxury', 'Medium', 'petals and decor', 'the bridges golf club', 'radio gatsby', 'tiffany and co', 'alice che photography', 'chritina choi cosmetics', 'marina morrison', 'franco masoma bespoke', 'miller and lux', 'bright event rentals', 'reb peters press', 'le gateau elegang', 'mandy scott', 92245);
INSERT INTO vendor_options (Wedding_Theme, Budget_level, Size, Flowers_vendor_name, Venue_vendor_name, Music_vendor_name, Jewelry_vendor_name, Photo_and_Video_vendor_name, Hair_and_Makeup_vendor_name, Brides_Dress, Grooms_Attire, Catering_vendor_name, Rentals_vendor_name, Invitations_vendor_name, Cake_vendor_name, Wedding_Planning_vendor_name, Total_est_cost) VALUES ('Nautical', 'Luxury', 'Large', 'petals and decor', 'the bridges golf club', 'radio gatsby', 'tiffany and co', 'alice che photography', 'chritina choi cosmetics', 'marina morrison', 'franco masoma bespoke', 'miller and lux', 'bright event rentals', 'reb peters press', 'le gateau elegang', 'mandy scott', 144290);

-- Select the newly created vendor options to verify the output
SELECT * FROM vendor_options;
