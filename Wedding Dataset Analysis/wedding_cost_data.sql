/* 
The prices have been taken from the vendors websites.

Calculations
1. Estimation for Flowers
300 stems * 2= 600( 20 tables , per table 15 stems - For guests)
30 stems * 2 = 60 ( For long table - Relatives)
135 stems * 2 = 270(arch)

Total Budget = 600+60+270 = 930$

2. The venue - fort mason centre for arts and culture where we plan to host the wedding also provides catering to the guests and rentals.
So, we have taken the prices charged by the venue and skipped the catering and rentals departments. Also, it simplifies coordination,
as dealing with one vendor reduces complexity and enhances communication efficiency. 

3. The Photo Premier package from George Street Photo and Video, costing $2545, includes a lead and associate photographer for 
8 and 6 hours respectively, covering unlimited locations. It offers hand color-corrected, non-watermarked high-resolution images, 
and free digital negatives. The package also features online proofing, album design, and a 10x10 signature album, with additional 
replica albums available at extra cost.

4. For hair and makeup, beauty by pace offers hair services for 150$, makeup services for 150$. And a combined package for hair and 
makeup has been considered.

5. The jewelry vendor - master fix jewelers didn't have wedding earrings in their product portfolio, so we are going with tina bridal
and creations, who is the dress and attire vendor to supply the bride's earrings. 

6. Folded cards are chosen for invitations to maximize space for showcasing numerous photos, printed on both sides. 
Their customizable nature allows for unique sizes and folds, creating one-of-a-kind, memorable invitations. 

7. For wedding planners, 1000$ package price was taken from weddingwire.com

8. catering and rentals department have been skipped as the venue is offering both these services. 

*/

-- Drop the existing temporary table if it exists
DROP TEMPORARY TABLE IF EXISTS wedding_cost_data;

-- Create a new temporary table with specified columns and data types
CREATE TEMPORARY TABLE wedding_cost_data (

`Serial No` VARCHAR(20), #serial no 
functions VARCHAR(20), #department
vendor_name VARCHAR (255), #vendor name
budget_level VARCHAR (30), #vendor budget level
item_name VARCHAR (80), #product/service name
price_per_item INT, #non-aggregated item prices
quantity INT, #quantity required for the wedding
subtotal INT #subtotal per line item (calculated using price_per_item * quantity)

);

#Inserting data into the respective columns
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES (1, 'flowers', 'fresh petals', 'inexpensive', 'white flowers', 2, 465, 930);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES ('2a', 'venue', 'fort mason centre for arts and culture', 'inexpensive', 'fort mason centre backyard (venue rental fees)', 7500, 1, 7500);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES ('2b', 'venue', 'fort mason centre for arts and culture', 'inexpensive', 'cost for insurance, security, coordinator ', 900, 1, 900);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES ('2c', 'venue', 'fort mason centre for arts and culture', 'inexpensive', 'catering and bar service', 6100, 1, 6100);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES ('2d', 'venue', 'fort mason centre for arts and culture', 'inexpensive', 'rentals for table and chair', 3200, 1, 3200);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES ('2e', 'venue', 'fort mason centre for arts and culture', 'inexpensive', 'taxes and service charges', 1100, 1, 1100);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES (3, 'music', 'the klipptones', 'inexpensive', 'package price', 2753, 1, 2753);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES ('4a', 'jewelry', 'master fix jewelers', 'inexpensive', 'rings women', 649, 1, 649);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES ('4b', 'jewelry', 'master fix jewelers', 'inexpensive', 'rings men', 649, 1, 649);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES ('4c', 'jewelry', 'master fix jewelers', 'inexpensive', 'bracelet women', 150, 1, 150);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES (5, 'photo and video', 'george street photo and video', 'inexpensive', 'Photo Premier', 2545, 1, 2545);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES (6, 'hair and makeup', 'beauty by pace', 'inexpensive', 'ceremony/engagement/wedding day services', 300, 1, 300);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES ('7a-1', 'dress atire - bride', 'tina bridal and creations', 'inexpensive', 'embroidered v-neck mermaid wedding gown', 1136, 1, 1136);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES ('7a-2', 'dress atire - bride', 'tina bridal and creations', 'inexpensive', 'crystal drop earrings', 60, 1, 60);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES ('7b-1', 'dress atire - groom', 'men wearhouse', 'inexpensive', 'JOE Joseph Abboud Slim Fit Linen Blend Suit Separates Coat (White)', 200, 1, 200);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES ('7b-2', 'dress atire - groom', 'men wearhouse', 'inexpensive', 'Egara pre-tied bow tie (Black)', 35, 1, 35);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES ('7b-3', 'dress atire - groom', 'men wearhouse', 'inexpensive', 'Ben Sherman Slim Fit Dobby Dress Shirt (White)', 60, 1, 60);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES ('7b-4', 'dress atire - groom', 'men wearhouse', 'inexpensive', 'Paisley & Gray fit suit separates pants (White)', 40, 1, 40);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES ('7b-5', 'dress atire - groom', 'men wearhouse', 'inexpensive', 'Egara Ankle Compression Socks (White)', 13, 1, 13);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES ('7b-6', 'dress atire - groom', 'men wearhouse', 'inexpensive', 'Moretti Stardust crystal formal loafers (Black)', 80, 1, 80);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES (10, 'invitations', 'pro digital photos', 'inexpensive', 'folded cards (5X7 tri fold)', 2, 135, 270);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES (11, 'cake', 'mitraartcake', 'inexpensive', 'classic vanilla cake (chiffon)', 300, 1, 300);
INSERT INTO wedding_cost_data (`Serial No`, functions, vendor_name, budget_level, item_name, price_per_item, quantity, subtotal) VALUES (12, 'wedding planners', 'swc consultants', 'inexpensive', 'package price', 1000, 1, 1000);

SELECT * FROM wedding_cost_data;





